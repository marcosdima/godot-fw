extends RefCounted
class_name UpdatePipeline


## Update phases executed by the pipeline, in order.
## Deliberately empty: concrete phases and their order will be defined
## once the module abstractions are finalized.
enum Phase { }


## Advances the update cycle: executes each phase in order and emits
## that phase's signal immediately after it.
##
## Modules never register here. They connect directly to the signals of
## the phases they need. The pipeline and World must not know which
## concrete modules exist.
func update() -> void:
	pass