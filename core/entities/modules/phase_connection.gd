extends RefCounted
class_name PhaseConnection


## The pipeline signal this connection was made on.
var pipeline_signal: Signal

## The callback connected to the signal.
var callback: Callable


## Creates a new connection record for the given signal and callable.
func _init(p_pipeline_signal: Signal, p_callback: Callable) -> void:
	pipeline_signal = p_pipeline_signal
	callback = p_callback