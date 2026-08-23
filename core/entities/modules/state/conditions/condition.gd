extends Element
class_name Condition


## Remaining strength/lifetime of this condition.
var intensity: float

## Effect applications owned by this condition.
var _effect_applications: Array[EffectApplication] = []


## Creates a new condition with the given identifier, name and intensity.
func _init(p_id: int, p_name: String, p_intensity: float) -> void:
	super(p_id, p_name)
	intensity = p_intensity


## Returns true while the intensity of this condition is greater than zero.
func is_alive() -> bool:
	return intensity > 0.0


## Adds an effect application to this condition.
func add_effect_application(application: EffectApplication) -> void:
	_effect_applications.append(application)


## Returns the effect applications owned by this condition.
func get_effect_applications() -> Array[EffectApplication]:
	return _effect_applications