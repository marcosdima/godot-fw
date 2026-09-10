extends RefCounted
class_name UIAnimationPlayback


## Emitted when a non-looping animation reaches its end.
signal finished

## Emitted when the playback is stopped before finishing.
signal stopped


## Weak reference to the element this playback belongs to. Held weakly so a
## playback never keeps an element tree alive after the screen that owns the
## element is freed.
var _element_ref: WeakRef

## The definition that drives this playback.
var _definition: UIAnimationDefinition

## Accumulated time in seconds since start, including the delay.
var _elapsed := 0.0

## True once a non-looping animation has reached its end.
var _done := false


## Creates a playback of the given definition for the given element.
func _init(element: UIElement, definition: UIAnimationDefinition) -> void:
	_element_ref = weakref(element)
	_definition = definition


## The element this playback animates, or null if it has been freed.
var element: UIElement:
	get:
		if _element_ref == null:
			return null
		return _element_ref.get_ref()


## Advances the playback by the given delta in seconds, using the runtime's own
## clock. Resolving loops happens here; values are read with value_for.
func advance(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	if _definition.loop == UIAnimationDefinition.Loop.NONE and _elapsed_time() >= _definition.duration:
		_done = true
		finished.emit()


## Stops the playback without reaching the end. Emits stopped.
func stop() -> void:
	if _done:
		return
	_done = true
	stopped.emit()


## Returns the value of the given property composited by its tracks: the base
## value with every matching track applied in order. Properties without a track
## come back unchanged. The element itself is never mutated.
func value_for(property: StringName, base: Variant) -> Variant:
	var result: Variant = base
	var progress := eased_progress()
	for track in _definition.tracks:
		if track.property != property:
			continue
		result = _compose(result, track.to, progress, track.blend)
	return result


## Returns true when this playback has finished or was stopped.
func is_finished() -> bool:
	return _done


## Returns the eased progress in the range 0.0 to 1.0 for the current state,
## after delay and easing have been applied. For swing definitions the value
## passes through 1.0 at the midpoint and comes back to 0.0 at the end, so a
## finished swing reports its base value instead of holding the target.
func eased_progress() -> float:
	var time := _elapsed_time()
	if time <= 0.0:
		return 0.0
	var duration := _definition.duration
	if duration <= 0.0:
		return 1.0
	var raw_progress := time / duration
	match _definition.loop:
		UIAnimationDefinition.Loop.RESTART:
			raw_progress = fmod(raw_progress, 1.0)
		UIAnimationDefinition.Loop.PING_PONG:
			var cycle := fmod(raw_progress, 2.0)
			raw_progress = cycle if cycle <= 1.0 else 2.0 - cycle
		_:
			raw_progress = minf(raw_progress, 1.0)
	if _definition.swing:
		raw_progress = 1.0 - absf(raw_progress * 2.0 - 1.0)
	return _ease(raw_progress)


## Advances the internal clock by delta without applying easing or limits, for
## deterministic testing of unfinished progress.
func set_time(value: float) -> void:
	_elapsed = value
	_done = false


## Returns the time in seconds since the effective start of the animation,
## excluding the delay.
func _elapsed_time() -> float:
	return _elapsed - _definition.delay


## Returns the eased value for the given raw progress.
func _ease(progress: float) -> float:
	match _definition.easing:
		UIAnimationDefinition.Easing.EASE_IN:
			return progress * progress
		UIAnimationDefinition.Easing.EASE_OUT:
			return 1.0 - (1.0 - progress) * (1.0 - progress)
		UIAnimationDefinition.Easing.EASE_IN_OUT:
			return progress * progress * (3.0 - 2.0 * progress)
		_:
			return progress


## Composes a base value with a track's target according to the blend mode.
## Supports the animatable value kinds: Vector2 and float.
func _compose(base: Variant, to: Variant, progress: float, blend: int) -> Variant:
	if base is Vector2:
		var vector_base := base as Vector2
		var vector_to := to as Vector2
		match blend:
			Track.Blend.ADD:
				return vector_base + vector_to * progress
			Track.Blend.MULTIPLY:
				return vector_base * vector_to.lerp(Vector2.ONE, progress)
			_:
				return vector_base.lerp(vector_to, progress)
	var scalar_base := float(base)
	var scalar_to := float(to)
	match blend:
		Track.Blend.ADD:
			return scalar_base + scalar_to * progress
		Track.Blend.MULTIPLY:
			return scalar_base * lerpf(1.0, scalar_to, progress)
		_:
			return lerpf(scalar_base, scalar_to, progress)