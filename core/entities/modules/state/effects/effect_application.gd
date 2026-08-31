extends Element
class_name EffectApplication


## Number of StateModule ticks between consecutive applications of this effect.
var rate: int

## Weak reference to the owning condition, used to avoid a reference cycle.
var _condition: WeakRef


## Creates a new effect application with the given identifier, name and rate.
func _init(p_id: int, p_name: String, p_rate: int = 1) -> void:
	super(p_id, p_name)
	rate = p_rate


## Returns the condition this application belongs to, or null when the application
## is instant or its condition no longer exists. Assigned by the condition that
## owns this application. Held weakly so the condition and its applications do not
## form a reference cycle.
var condition: Condition:
	get:
		if _condition == null:
			return null
		return _condition.get_ref()
	set(value):
		_condition = weakref(value)


## Generates the effect produced by this application at the current moment.
func generate_effect() -> Effect:
	return null