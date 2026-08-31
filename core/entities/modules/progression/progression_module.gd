extends Module
class_name ProgressionModule


## Progressions of the entity.
var _progression: Progression


## Creates a new progression module bound to the given entity.
func _init(p_entity: Entity) -> void:
	super(p_entity)
	_progression = Progression.new()


## Returns the progression of this progression module.
func get_progression() -> Progression:
	return _progression