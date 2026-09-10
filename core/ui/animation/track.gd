extends RefCounted
class_name Track


## How a track's target value combines with the base value of its property.
enum Blend {
	## Replaces the base value, interpolating towards the target.
	OVERRIDE,
	## Adds the target scaled by progress to the base value.
	ADD,
	## Multiplies the base value by a value interpolating from 1 towards the target.
	MULTIPLY,
}


## The element property animated by this track. Limited to the animatable
## properties validated by UIAnimationDefinition.
var property: StringName

## The target value of the animation. Float for scalar properties, Vector2 for
## position, size and scale.
var to: Variant

## How the target combines with the current value of the property. Values come
## from Blend; the field is an int because GDScript enums are not types.
var blend := Blend.OVERRIDE


## Creates a track for the given property and target.
func _init(p_property: StringName, p_to: Variant, p_blend: int = Blend.OVERRIDE) -> void:
	property = p_property
	to = p_to
	blend = p_blend