extends Element
class_name Attribute


## Original value of this attribute. Never modified by the state module.
var base_value: float

## Lowest value this attribute may hold. Defaults to negative infinity (unbounded).
var min_value: float

## Current mutable value of this attribute. Effects modify this value.
## Every assignment is clamped to min_value.
var current_value: float:
	set(value):
		current_value = maxf(value, min_value)

## Active modifiers that affect the effective value.
var modifiers: Array[Modifier] = []


## Creates a new attribute with the given identifier, name, base value and minimum value.
func _init(p_id: int, p_name: String, p_base_value: float, p_min_value: float = -INF) -> void:
	super(p_id, p_name)
	base_value = p_base_value
	min_value = p_min_value
	current_value = p_base_value


## Adds a modifier to this attribute.
func add_modifier(modifier: Modifier) -> void:
	modifiers.append(modifier)


## Removes a modifier from this attribute.
func remove_modifier(modifier: Modifier) -> void:
	modifiers.erase(modifier)


## Returns the effective value, calculated from the current value and the active modifiers.
func get_effective_value() -> float:
	var effective_value: float = current_value
	for modifier in modifiers:
		effective_value += modifier.value
	return effective_value