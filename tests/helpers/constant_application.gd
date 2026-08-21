extends EffectApplication


## Effect returned by every call to generate_effect.
var _effect: Effect


## Creates a new application that always generates the given effect.
func _init(p_id: int, p_name: String, p_rate: int, p_effect: Effect) -> void:
	super(p_id, p_name, p_rate)
	_effect = p_effect


## Returns the effect given at construction.
func generate_effect() -> Effect:
	return _effect