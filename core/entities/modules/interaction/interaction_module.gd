extends Module
class_name InteractionModule


## Emitted after an interaction becomes available to this module.
signal interaction_added(interaction: Interaction)

## Emitted after an interaction stops being available to this module.
signal interaction_removed(interaction: Interaction)

## Emitted after an actual focus transition, with the previous and the new focus.
signal focused_changed(previous: Interaction, current: Interaction)


## Available interactions in insertion order.
var _interactions: Array[Interaction] = []

## The currently focused interaction, or null.
var _focused: Interaction = null

## Interactions presented by each source, keyed by the source object itself.
## Values are shallow copies of the presented array; the Interaction instances
## are the original ones.
var _offerings: Dictionary = {}

## Interactions added through add(), kept available independently of offerings.
var _manual_interactions: Array[Interaction] = []


## Adds an interaction to the available set as a manual reason.
## Focuses it automatically when no interaction is focused yet and the
## availability actually changes.
func add(interaction: Interaction) -> void:
	if _manual_interactions.has(interaction):
		push_error("Interaction already added")
		return
	_manual_interactions.append(interaction)
	if _interactions.has(interaction):
		return
	_interactions.append(interaction)
	interaction_added.emit(interaction)
	if _focused == null:
		_set_focused(interaction)


## Removes the manual reason of an interaction. The interaction remains
## available while any source still offers it. Removing an interaction that is
## not available emits an error.
func remove(interaction: Interaction) -> void:
	if not _interactions.has(interaction):
		push_error("Interaction not found")
		return
	_manual_interactions.erase(interaction)
	if _has_other_reason(interaction, null):
		return
	_interactions.erase(interaction)
	interaction_removed.emit(interaction)
	if _focused == interaction:
		_set_focused(null)


## Presents the complete current offering of the given source, replacing any
## previous offering from the same source. An empty offering is equivalent to
## retracting the source. Presenting the same offering again is a no-op.
func present(source: Object, interactions: Array[Interaction]) -> void:
	if source == null:
		push_error("Cannot present interactions with a null source")
		return
	var offering := _deduplicate(interactions)
	var previous: Array[Interaction] = []
	if _offerings.has(source):
		previous = _offerings[source]
	if previous == offering:
		return
	if offering.is_empty():
		_offerings.erase(source)
	else:
		_offerings[source] = offering
	_reconcile(source, previous, offering)


## Retracts the offering of the given source without affecting other sources.
## Retracting an unknown source is an idempotent no-op.
func retract(source: Object) -> void:
	present(source, [])


## Focuses the given available interaction.
func focus(interaction: Interaction) -> void:
	if not _interactions.has(interaction):
		push_error("Cannot focus an interaction that is not available")
		return
	_set_focused(interaction)


## Focuses the next available interaction, wrapping around.
func next() -> void:
	_step(1)


## Focuses the previous available interaction, wrapping around.
func previous() -> void:
	_step(-1)


## Executes the focused interaction's action. Does nothing without a focused interaction.
func execute_focused() -> void:
	if _focused == null:
		return
	_focused.action.call()


## Returns the currently focused interaction, or null.
func get_focused() -> Interaction:
	return _focused


## Returns a copy of the available interactions array in insertion order.
## The Interaction instances are the same references.
func get_interactions() -> Array[Interaction]:
	return _interactions.duplicate()


## Steps the focus forward or backward, wrapping around the available set.
func _step(direction: int) -> void:
	if _interactions.is_empty():
		return
	var index := 0
	if _focused != null:
		index = (_interactions.find(_focused) + direction + _interactions.size()) % _interactions.size()
	_set_focused(_interactions[index])


## Applies the effective additions and removals between the previous and the
## next offering of a source, then reconciles the focus.
func _reconcile(source: Object, previous: Array[Interaction], next: Array[Interaction]) -> void:
	var added_any := false
	for interaction in previous:
		if next.has(interaction) or _has_other_reason(interaction, source):
			continue
		_interactions.erase(interaction)
		interaction_removed.emit(interaction)
	for interaction in next:
		if _interactions.has(interaction):
			continue
		_interactions.append(interaction)
		interaction_added.emit(interaction)
		added_any = true
	if _focused != null and not _interactions.has(_focused):
		_set_focused(_interactions[0] if not _interactions.is_empty() else null)
	elif _focused == null and added_any:
		_set_focused(_interactions[0])


## Returns true when the interaction would remain available without the given
## source: either it was added manually or another source still offers it.
func _has_other_reason(interaction: Interaction, excluded_source: Object) -> bool:
	if _manual_interactions.has(interaction):
		return true
	for other_source in _offerings:
		if other_source == excluded_source:
			continue
		var offering: Array[Interaction] = _offerings[other_source]
		if offering.has(interaction):
			return true
	return false


## Returns a copy of the given interactions without repeated instances,
## preserving the first occurrence of each one.
func _deduplicate(interactions: Array[Interaction]) -> Array[Interaction]:
	var result: Array[Interaction] = []
	for interaction in interactions:
		if not result.has(interaction):
			result.append(interaction)
	return result


## Transitions focus to the given interaction, firing lifecycle callbacks in
## order and reporting the transition through focused_changed.
func _set_focused(interaction: Interaction) -> void:
	if _focused == interaction:
		return
	var previous := _focused
	if _focused != null and _focused.on_unfocused.is_valid():
		_focused.on_unfocused.call()
	_focused = interaction
	if _focused != null and _focused.on_focused.is_valid():
		_focused.on_focused.call()
	focused_changed.emit(previous, interaction)