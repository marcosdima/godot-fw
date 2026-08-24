extends RefCounted
class_name UpdatePipeline


## Phases executed by the pipeline, in definition order.
enum Phase { STATE }


## Emitted after the STATE phase executes.
signal state


## Signals of each phase, keyed by phase.
## The insertion order of this dictionary is the execution order.
var _phase_signals: Dictionary = {
	Phase.STATE: state,
}


## Returns the signal of the given phase. Callbacks receive no arguments.
func phase_signal(phase: UpdatePipeline.Phase) -> Signal:
	return _phase_signals[phase]


## Advances the update cycle: emits each phase signal in order.
##
## Modules never register here. They connect directly to the signals of
## the phases they need. The pipeline and World must not know which
## concrete modules exist.
func update() -> void:
	for phase in _phase_signals:
		(_phase_signals[phase] as Signal).emit()