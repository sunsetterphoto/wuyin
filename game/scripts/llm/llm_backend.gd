class_name LlmBackend
extends RefCounted
## Interface for model runtimes. Implementations stream tokens into the job
## and call job.finish(). The service handles timeouts and fallbacks.
##   HttpLlamaBackend   llama-server over HTTP (desktop development, Steam builds)
##   native (planned)   llama.cpp GDExtension inside the game (Android, desktop)


func name() -> String:
	return "none"


## Cheap check whether this backend can serve requests right now.
func is_available() -> bool:
	return false


## Starts generation. Must not block; stream via job.push_token(), end with job.finish().
func run(job: LlmJob) -> void:
	job.finish(false, "backend not implemented")


func cancel(_job: LlmJob) -> void:
	pass
