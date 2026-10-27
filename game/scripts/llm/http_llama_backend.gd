class_name HttpLlamaBackend
extends LlmBackend
## Streams from llama.cpp's llama-server (OpenAI-compatible chat endpoint) with
## a JSON schema constraint. Used for desktop development; the shipped Android
## build will use the in-process llama.cpp backend with the same requests.
##   llama-server -m model.gguf --port 8090 -c 4096 -ngl 99

var host := "127.0.0.1"
var port := 8090
var _available_checked_ms := -100000
var _available := false

const AVAILABILITY_TTL_MS := 5000


func _init(h := "127.0.0.1", p := 8090) -> void:
	host = h
	port = p


func name() -> String:
	return "llama-server %s:%d" % [host, port]


## Blocking TCP connect check, cached for a few seconds (only a few ms on localhost).
func is_available() -> bool:
	var now := Time.get_ticks_msec()
	if now - _available_checked_ms < AVAILABILITY_TTL_MS:
		return _available
	_available_checked_ms = now
	var peer := StreamPeerTCP.new()
	_available = false
	if peer.connect_to_host(host, port) == OK:
		var deadline := now + 150
		while Time.get_ticks_msec() < deadline:
			peer.poll()
			if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				_available = true
				break
			if peer.get_status() == StreamPeerTCP.STATUS_ERROR:
				break
			OS.delay_msec(5)
	peer.disconnect_from_host()
	return _available


func build_body(job: LlmJob) -> Dictionary:
	var body := {
		"messages": job.messages,
		"max_tokens": job.max_tokens,
		"temperature": job.temperature,
		"stream": true,
		# Small reasoning models (Gemma 4, Qwen 3) would otherwise think first and blow the latency budget.
		"chat_template_kwargs": {"enable_thinking": false},
	}
	if not job.schema.is_empty():
		body["response_format"] = {"type": "json_schema", "json_schema": {"schema": job.schema}}
	return body


func run(job: LlmJob) -> void:
	_stream(job)


func _stream(job: LlmJob) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var client := HTTPClient.new()
	if client.connect_to_host(host, port) != OK:
		job.finish(false, "connect failed")
		return
	while client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		client.poll()
		if job.done:
			client.close()
			return
		await tree.process_frame
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		job.finish(false, "connect failed (%d)" % client.get_status())
		return
	var body := JSON.stringify(build_body(job))
	client.request(HTTPClient.METHOD_POST, "/v1/chat/completions",
		["Content-Type: application/json", "Accept: text/event-stream"], body)
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		if job.done:
			client.close()
			return
		await tree.process_frame
	if not client.has_response() or client.get_response_code() != 200:
		job.finish(false, "http %d" % client.get_response_code())
		client.close()
		return
	var buffer := ""
	while client.get_status() == HTTPClient.STATUS_BODY:
		if job.done:
			client.close()
			return
		client.poll()
		var chunk := client.read_response_body_chunk()
		if chunk.is_empty():
			await tree.process_frame
			continue
		buffer += chunk.get_string_from_utf8()
		var nl := buffer.find("\n")
		while nl >= 0:
			var line := buffer.substr(0, nl).strip_edges()
			buffer = buffer.substr(nl + 1)
			nl = buffer.find("\n")
			if not line.begins_with("data:"):
				continue
			var payload := line.substr(5).strip_edges()
			if payload == "[DONE]":
				client.close()
				job.finish(true)
				return
			var data = JSON.parse_string(payload)
			if data is Dictionary and data.has("choices") and not data["choices"].is_empty():
				var delta: Dictionary = data["choices"][0].get("delta", {})
				var content = delta.get("content")
				if content is String and content != "":
					job.push_token(content)
	client.close()
	job.finish(job.text != "", "stream ended")
