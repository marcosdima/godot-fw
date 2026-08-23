extends Module
class_name InteractionModule


## Available interactions in insertion order.
var _interactions: Array[Interaction] = []

## The currently focused interaction, or null.
var _focused: Interaction = null


## Adds an interaction to the available set.
## Focuses it automatically when no interaction is focused yet.
func add(interaction: Interaction) -> void:
	if _interactions.has(interaction):
		push_error("Interaction already added")
		return
	_interactions.append(interaction)
	if _focused == null:
		_set_focused(interaction)


## Removes an interaction from the available set.
func remove(interaction: Interaction) -> void:
	if not _interactions.has(interaction):
		push_error("Interaction not found")
		return
	if _focused == interaction:
		_set_focused(null)
	_interactions.erase(interaction)


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


## Transitions focus to the given interaction, firing lifecycle callbacks in order.
func _set_focused(interaction: Interaction) -> void:
	if _focused == interaction:
		return
	if _focused != null and _focused.on_unfocused.is_valid():
		_focused.on_unfocused.call()
	_focused = interaction
	if _focused != null and _focused.on_focused.is_valid():
		_focused.on_focused.call()