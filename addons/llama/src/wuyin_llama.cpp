#include "wuyin_llama.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "chat.h"
#include "llama.h"

#include <chrono>
#include <cmath>

using namespace godot;

namespace {

int64_t now_ms() {
	return std::chrono::duration_cast<std::chrono::milliseconds>(
			std::chrono::steady_clock::now().time_since_epoch())
			.count();
}

std::string to_std(const String &s) {
	CharString u = s.utf8();
	return std::string(u.get_data(), u.length());
}

// Length of the longest prefix of `bytes` that ends on a complete UTF-8 character.
size_t utf8_complete_prefix(const std::string &bytes) {
	size_t n = bytes.size();
	size_t i = n;
	int back = 0;
	while (i > 0 && back < 4) {
		unsigned char c = (unsigned char)bytes[i - 1];
		if ((c & 0xC0) != 0x80) {
			int len = (c < 0x80) ? 1 : (c >> 5) == 0x6 ? 2 : (c >> 4) == 0xE ? 3 : (c >> 3) == 0x1E ? 4 : 1;
			return (n - (i - 1) >= (size_t)len) ? n : i - 1;
		}
		i--;
		back++;
	}
	return n;
}

void tokenize_append(const llama_vocab *vocab, const std::string &text, bool parse_special, std::vector<llama_token> &out) {
	if (text.empty()) {
		return;
	}
	int n = -llama_tokenize(vocab, text.c_str(), (int32_t)text.size(), nullptr, 0, false, parse_special);
	size_t start = out.size();
	out.resize(start + n);
	llama_tokenize(vocab, text.c_str(), (int32_t)text.size(), out.data() + start, n, false, parse_special);
}

} // namespace

WuyinLlama::WuyinLlama() {
	worker = std::thread([this]() { worker_main(); });
}

WuyinLlama::~WuyinLlama() {
	{
		std::lock_guard<std::mutex> lock(mutex);
		stopping = true;
	}
	cv.notify_all();
	if (worker.joinable()) {
		worker.join();
	}
	for (auto &it : contexts) {
		llama_free(it.second.ctx);
	}
	contexts.clear();
	templates.reset();
	if (model) {
		llama_model_free(model);
	}
}

void WuyinLlama::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load", "path", "threads"), &WuyinLlama::load);
	ClassDB::bind_method(D_METHOD("new_context", "n_ctx"), &WuyinLlama::new_context);
	ClassDB::bind_method(D_METHOD("drop_context", "ctx"), &WuyinLlama::drop_context);
	ClassDB::bind_method(D_METHOD("generate", "ctx", "messages", "grammar", "max_tokens", "temperature"), &WuyinLlama::generate);
	ClassDB::bind_method(D_METHOD("cancel", "request"), &WuyinLlama::cancel);
	ClassDB::bind_method(D_METHOD("is_loaded"), &WuyinLlama::is_loaded);
	ADD_SIGNAL(MethodInfo("loaded", PropertyInfo(Variant::BOOL, "ok"), PropertyInfo(Variant::STRING, "message")));
	ADD_SIGNAL(MethodInfo("token", PropertyInfo(Variant::INT, "request"), PropertyInfo(Variant::STRING, "text")));
	ADD_SIGNAL(MethodInfo("finished", PropertyInfo(Variant::INT, "request"), PropertyInfo(Variant::BOOL, "ok"),
			PropertyInfo(Variant::STRING, "reason"), PropertyInfo(Variant::DICTIONARY, "stats")));
}

void WuyinLlama::worker_main() {
	while (true) {
		std::function<void()> job;
		{
			std::unique_lock<std::mutex> lock(mutex);
			cv.wait(lock, [this]() { return stopping || !queue.empty(); });
			if (stopping) {
				return;
			}
			job = std::move(queue.front());
			queue.pop_front();
		}
		job();
	}
}

void WuyinLlama::post(std::function<void()> p_job) {
	{
		std::lock_guard<std::mutex> lock(mutex);
		queue.push_back(std::move(p_job));
	}
	cv.notify_one();
}

void WuyinLlama::emit_main(const StringName &p_signal, const Array &p_args) {
	Array args;
	args.push_back(p_signal);
	args.append_array(p_args);
	callv("call_deferred", Array::make("emit_signal") + args);
}

void WuyinLlama::load(const String &p_path, int p_threads) {
	std::string path = to_std(p_path);
	post([this, path, p_threads]() { do_load(path, p_threads); });
}

void WuyinLlama::do_load(std::string p_path, int p_threads) {
	if (model) {
		emit_main("loaded", Array::make(true, "already loaded"));
		return;
	}
	static bool backend_ready = false;
	if (!backend_ready) {
		llama_backend_init();
		backend_ready = true;
	}
	threads = p_threads > 0 ? p_threads : 4;
	llama_model_params mp = llama_model_default_params();
	mp.n_gpu_layers = 0; // CPU: measured faster than Vulkan on Adreno; Metal not needed for dev
	model = llama_model_load_from_file(p_path.c_str(), mp);
	if (!model) {
		emit_main("loaded", Array::make(false, String::utf8(("cannot load " + p_path).c_str())));
		return;
	}
	templates = common_chat_templates_init(model, "");
	loaded = true;
	emit_main("loaded", Array::make(true, "ok"));
}

int WuyinLlama::new_context(int p_n_ctx) {
	int id = next_ctx++;
	post([this, id, p_n_ctx]() { pending_contexts[id] = p_n_ctx > 0 ? p_n_ctx : 2048; });
	return id;
}

void WuyinLlama::drop_context(int p_ctx) {
	post([this, p_ctx]() {
		pending_contexts.erase(p_ctx);
		auto it = contexts.find(p_ctx);
		if (it != contexts.end()) {
			llama_free(it->second.ctx);
			contexts.erase(it);
		}
	});
}

WuyinLlama::Context *WuyinLlama::ensure_context(int p_ctx) {
	auto it = contexts.find(p_ctx);
	if (it != contexts.end()) {
		return &it->second;
	}
	auto pit = pending_contexts.find(p_ctx);
	if (pit == pending_contexts.end() || !model) {
		return nullptr;
	}
	llama_context_params cp = llama_context_default_params();
	cp.n_ctx = pit->second;
	cp.n_batch = 512;
	cp.n_ubatch = 512;
	cp.n_threads = threads;
	cp.n_threads_batch = threads;
	llama_context *c = llama_init_from_model(model, cp);
	if (!c) {
		return nullptr;
	}
	Context &ctx = contexts[p_ctx];
	ctx.ctx = c;
	ctx.n_ctx = pit->second;
	pending_contexts.erase(pit);
	return &ctx;
}

int WuyinLlama::generate(int p_ctx, const Array &p_messages, const String &p_grammar, int p_max_tokens, float p_temperature) {
	int id = next_request++;
	std::vector<std::pair<std::string, std::string>> msgs;
	for (int i = 0; i < p_messages.size(); i++) {
		Dictionary m = p_messages[i];
		msgs.emplace_back(to_std(m.get("role", "user")), to_std(m.get("content", "")));
	}
	std::string grammar = to_std(p_grammar);
	post([this, id, p_ctx, msgs, grammar, p_max_tokens, p_temperature]() {
		do_generate(id, p_ctx, msgs, grammar, p_max_tokens, p_temperature);
	});
	return id;
}

void WuyinLlama::cancel(int p_request) {
	std::lock_guard<std::mutex> lock(cancel_mutex);
	cancelled.insert(p_request);
}

void WuyinLlama::do_generate(int p_id, int p_ctx, std::vector<std::pair<std::string, std::string>> p_messages,
		std::string p_grammar, int p_max_tokens, float p_temperature) {
	auto is_cancelled = [this, p_id]() {
		std::lock_guard<std::mutex> lock(cancel_mutex);
		return cancelled.count(p_id) > 0;
	};
	auto finish = [this, p_id](bool ok, const std::string &reason, const Dictionary &stats) {
		{
			std::lock_guard<std::mutex> lock(cancel_mutex);
			cancelled.erase(p_id);
		}
		emit_main("finished", Array::make(p_id, ok, String::utf8(reason.c_str()), stats));
	};
	if (is_cancelled()) {
		finish(false, "cancelled", Dictionary());
		return;
	}
	if (!model) {
		finish(false, "no model", Dictionary());
		return;
	}
	Context *ctx = ensure_context(p_ctx);
	if (!ctx) {
		finish(false, "no context", Dictionary());
		return;
	}
	const llama_vocab *vocab = llama_model_get_vocab(model);
	int64_t t0 = now_ms();

	// Chat template (Jinja via llama.cpp common). Player text is tokenized
	// without special-token parsing so it can't inject control tokens.
	common_chat_templates_inputs inputs;
	for (auto &m : p_messages) {
		common_chat_msg msg;
		msg.role = m.first;
		msg.content = m.second;
		inputs.messages.push_back(msg);
	}
	inputs.add_generation_prompt = true;
	inputs.use_jinja = true;
	inputs.enable_thinking = false;
	inputs.chat_template_kwargs["enable_thinking"] = "false";
	common_chat_params params = common_chat_templates_apply(templates.get(), inputs);
	std::vector<llama_token> tokens;
	for (auto &part : params.prompt.parts) {
		tokenize_append(vocab, part.text, !part.is_input, tokens);
	}
	if (tokens.empty() || (int)tokens.size() >= ctx->n_ctx - 8) {
		finish(false, "prompt too long", Dictionary());
		return;
	}

	// Reuse the KV cache for the shared prefix with the previous request.
	size_t keep = 0;
	while (keep < ctx->cached.size() && keep < tokens.size() && ctx->cached[keep] == tokens[keep]) {
		keep++;
	}
	if (keep == tokens.size()) {
		keep--; // need at least one token to compute fresh logits
	}
	llama_memory_t mem = llama_get_memory(ctx->ctx);
	if (!llama_memory_seq_rm(mem, 0, (llama_pos)keep, -1)) {
		llama_memory_clear(mem, true);
		keep = 0;
	}
	ctx->cached.assign(tokens.begin(), tokens.begin() + keep);

	const int n_batch = 512;
	for (size_t i = keep; i < tokens.size(); i += n_batch) {
		if (is_cancelled()) {
			ctx->cached.clear();
			llama_memory_clear(mem, true);
			finish(false, "cancelled", Dictionary());
			return;
		}
		int n = (int)std::min(tokens.size() - i, (size_t)n_batch);
		llama_batch batch = llama_batch_get_one(tokens.data() + i, n);
		if (llama_decode(ctx->ctx, batch) != 0) {
			ctx->cached.clear();
			llama_memory_clear(mem, true);
			finish(false, "decode failed", Dictionary());
			return;
		}
		ctx->cached.insert(ctx->cached.end(), tokens.begin() + i, tokens.begin() + i + n);
	}
	int64_t t_prompt = now_ms();

	// Sampling without the grammar in the chain: the grammar is checked only for
	// the chosen token and applied to the full vocabulary only when that token is
	// not allowed (same idea as llama.cpp's server). Gemma's 262k vocabulary made
	// a full grammar pass per token cost ~100 ms on a phone.
	llama_sampler *grammar = nullptr;
	if (!p_grammar.empty()) {
		grammar = llama_sampler_init_grammar(vocab, p_grammar.c_str(), "root");
		if (!grammar) {
			finish(false, "bad grammar", Dictionary());
			return;
		}
	}
	llama_sampler *chain = llama_sampler_chain_init(llama_sampler_chain_default_params());
	if (p_temperature <= 0.0f) {
		llama_sampler_chain_add(chain, llama_sampler_init_greedy());
	} else {
		llama_sampler_chain_add(chain, llama_sampler_init_temp(p_temperature));
		llama_sampler_chain_add(chain, llama_sampler_init_dist((uint32_t)now_ms()));
	}
	const int n_vocab = llama_vocab_n_tokens(vocab);
	std::vector<llama_token_data> candidates;
	auto sample = [&]() -> llama_token {
		llama_token tok = llama_sampler_sample(chain, ctx->ctx, -1);
		if (!grammar) {
			return tok;
		}
		llama_token_data single = { tok, 1.0f, 0.0f };
		llama_token_data_array one = { &single, 1, -1, false };
		llama_sampler_apply(grammar, &one);
		if (one.data[0].logit != -INFINITY) {
			llama_sampler_accept(grammar, tok);
			return tok;
		}
		// Slow path: constrain the whole vocabulary, then pick again.
		const float *logits = llama_get_logits_ith(ctx->ctx, -1);
		candidates.resize(n_vocab);
		for (int i = 0; i < n_vocab; i++) {
			candidates[i] = { i, logits[i], 0.0f };
		}
		llama_token_data_array all = { candidates.data(), (size_t)n_vocab, -1, false };
		llama_sampler_apply(grammar, &all);
		llama_sampler_apply(chain, &all);
		tok = all.data[all.selected].id;
		llama_sampler_accept(grammar, tok);
		return tok;
	};

	std::string pending; // bytes not yet forming whole UTF-8 characters
	int generated = 0;
	std::string reason = "";
	bool ok = true;
	while (generated < p_max_tokens) {
		if (is_cancelled()) {
			reason = "cancelled";
			ok = false;
			break;
		}
		llama_token tok = sample();
		if (llama_vocab_is_eog(vocab, tok)) {
			break;
		}
		char buf[256];
		int n = llama_token_to_piece(vocab, tok, buf, sizeof(buf), 0, false);
		if (n > 0) {
			pending.append(buf, n);
			size_t whole = utf8_complete_prefix(pending);
			if (whole > 0) {
				emit_main("token", Array::make(p_id, String::utf8(pending.substr(0, whole).c_str())));
				pending.erase(0, whole);
			}
		}
		generated++;
		llama_batch b = llama_batch_get_one(&tok, 1);
		if (llama_decode(ctx->ctx, b) != 0) {
			reason = "decode failed";
			ok = false;
			break;
		}
		ctx->cached.push_back(tok);
	}
	if (!pending.empty()) {
		emit_main("token", Array::make(p_id, String::utf8(pending.c_str())));
	}
	llama_sampler_free(chain);
	if (grammar) {
		llama_sampler_free(grammar);
	}
	int64_t t_end = now_ms();
	Dictionary stats;
	stats["prompt_tokens"] = (int)tokens.size();
	stats["reused_tokens"] = (int)keep;
	stats["prompt_ms"] = (int)(t_prompt - t0);
	stats["gen_tokens"] = generated;
	stats["gen_ms"] = (int)(t_end - t_prompt);
	finish(ok, reason, stats);
}
