extends RefCounted
class_name UIAnimationDefinition


## How progress is distributed over time.
enum Easing {
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT,
}

## How the animation behaves after one full duration.
enum Loop {
	## Plays once and finishes.
	NONE,
	## Starts again from the beginning.
	RESTART,
	## Reverses direction at each iteration boundary.
	PING_PONG,
}


## Animatable element properties. The playback drives exactly these; other
## properties are rejected at track creation.
const ANIMATABLE_PROPERTIES: Array[StringName] = [
	&"position",
	&"size",
	&"scale",
	&"modulate",
]


## Duration in seconds of one full iteration.
var duration := 0.0

## Delay in seconds before the animation starts.
var delay := 0.0

## Easing applied to progress. Values come from Easing.
var easing := Easing.LINEAR

## Loop behavior after the first iteration ends. Values come from Loop.
var loop := Loop.NONE

## When true, progress travels to 1.0 at the halfway point of each iteration
## and returns to 0.0 at its end. The value therefore always finishes exactly
## at its base, which makes single shots (pulses, flashes) self-restoring:
## no view-side poke is needed after the last tick.
var swing := false

## Tracks of this animation, evaluated in order.
var tracks: Array[Track] = []


## Adds a track for the given animatable property and target, with the given
## blend. Emits an error and returns null for properties outside
## ANIMATABLE_PROPERTIES.
func add_track(property: StringName, to: Variant, blend: int = Track.Blend.OVERRIDE) -> Track:
	if not ANIMATABLE_PROPERTIES.has(property):
		push_error("Property %s is not animatable" % property)
		return null
	var track := Track.new(property, to, blend)
	tracks.append(track)
	return track