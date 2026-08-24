extends RefCounted
class_name PhaseCallback


## The pipeline phase this callback participates in.
var phase: UpdatePipeline.Phase

## The callback invoked when the phase executes.
var callback: Callable


## Creates a new phase participation with the given phase and callback.
func _init(p_phase: UpdatePipeline.Phase, p_callback: Callable) -> void:
	phase = p_phase
	callback = p_callback