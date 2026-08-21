extends Element
class_name EffectApplication


## Number of StateSystem ticks between consecutive applications of this effect.
var rate: int


## Creates a new effect application with the given identifier, name and rate.
func _init(p_id: int, p_name: String, p_rate: int = 1) -> void:
	super(p_id, p_name)
	rate = p_rate


## Generates the effect produced by this application at the current moment.
func generate_effect() -> Effect:
	return null