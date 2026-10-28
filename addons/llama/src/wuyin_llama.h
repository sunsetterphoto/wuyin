// WuyinLlama: llama.cpp inside Godot for Wuyin (GDExtension).
// One worker thread owns the model and all contexts; GDScript enqueues work and
// receives results as signals on the main thread.
#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

#include <atomic>
#include <condition_variable>
#include <deque>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <thread>
#include <vector>

#include "chat.h" // common_chat_templates_ptr

struct llama_model;
struct llama_context;

namespace godot {

class WuyinLlama : public RefCounted {
	GDCLASS(WuyinLlama, RefCounted)

public:
	WuyinLlama();
	~WuyinLlama();

	// Loads the model on the worker; emits loaded(ok, message).
	void load(const String &p_path, int p_threads);
	// Context ("lane") with its own KV cache; created lazily on the worker.
	int new_context(int p_n_ctx);
	void drop_context(int p_ctx);
	// Chat messages ([{role, content}, ...]) -> request id. Emits token(id, text)
	// while generating and finished(id, ok, reason, stats) once.
	int generate(int p_ctx, const Array &p_messages, const String &p_grammar, int p_max_tokens, float p_temperature);
	void cancel(int p_request);
	bool is_loaded() const { return loaded.load(); }

protected:
	static void _bind_methods();

private:
	struct Context {
		llama_context *ctx = nullptr;
		int n_ctx = 2048;
		std::vector<int32_t> cached; // tokens currently in the KV cache
	};

	void worker_main();
	void post(std::function<void()> p_job);
	void emit_main(const StringName &p_signal, const Array &p_args);
	void do_load(std::string p_path, int p_threads);
	void do_generate(int p_id, int p_ctx, std::vector<std::pair<std::string, std::string>> p_messages,
			std::string p_grammar, int p_max_tokens, float p_temperature);
	Context *ensure_context(int p_ctx);

	std::thread worker;
	std::mutex mutex;
	std::condition_variable cv;
	std::deque<std::function<void()>> queue;
	bool stopping = false;

	std::atomic<bool> loaded{ false };
	std::atomic<int> next_request{ 1 };
	std::atomic<int> next_ctx{ 1 };
	std::mutex cancel_mutex;
	std::set<int> cancelled;

	// Worker-thread state only.
	llama_model *model = nullptr;
	common_chat_templates_ptr templates;
	int threads = 4;
	std::map<int, int> pending_contexts; // id -> n_ctx, created on first use
	std::map<int, Context> contexts;
};

} // namespace godot
