extends Module
class_name StatusModule


## Current values of the entity's attributes.
var _status: Status


## Creates a new status module bound to the given entity.
func _init(p_entity: Entity) -> void:
	super(p_entity)
	_status = Status.new()


## Returns the status of this status module.
func get_status() -> Status:
	return _status