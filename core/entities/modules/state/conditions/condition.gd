extends Element
class_name Condition


## Intensity at or below which a condition is no longer considered alive by default.
const DEFAULT_DEATH_THRESHOLD := 0.1


## Remaining strength/lifetime of this condition.
var intensity: float

## Intensity at or below which this condition is no longer considered alive.
var death_threshold: float

## Intensity removed from this condition on every StateModule tick. Zero means no decay.
var decay_rate: float

## Effect applications owned by this condition.
var _effect_applications: Array[EffectApplication] = []


## Creates a new condition with the given identifier, name, intensity, death threshold and decay rate.
func _init(p_id: int, p_name: String, p_intensity: float, p_death_threshold: float = DEFAULT_DEATH_THRESHOLD, p_decay_rate: float = 0.0) -> void:
	super(p_id, p_name)
	intensity = p_intensity
	death_threshold = p_death_threshold
	decay_rate = p_decay_rate


## Returns true while the intensity of this condition is greater than its death threshold.
func is_alive() -> bool:
	return intensity > death_threshold


## Reduces the intensity of this condition by its decay rate.
func decay() -> void:
	intensity -= decay_rate


## Adds an effect application to this condition.
func add_effect_application(application: EffectApplication) -> void:
	application.condition = self
	_effect_applications.append(application)


## Returns the effect applications owned by this condition.
func get_effect_applications() -> Array[EffectApplication]:
	return _effect_applications