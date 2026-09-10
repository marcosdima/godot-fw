extends RefCounted
class_name SelectionGroup


## Emitted after an actual focus transition, with the previous and the new focus.
signal focused_changed(previous: UIElement, current: UIElement)


## Selectable elements in insertion order.
var _items: Array[UIElement] = []

## The currently focused element, or null.
var _focused: UIElement = null


## Adds the given element to the selection order. Duplicate adds are rejected.
func add(element: UIElement) -> void:
	if _items.has(element):
		push_error("Element already in the selection group")
		return
	_items.append(element)


## Removes the given element from the selection order. Removing the focused
## element clears the focus; otherwise focus is preserved.
func remove(element: UIElement) -> void:
	if not _items.has(element):
		push_error("Element is not in the selection group")
		return
	_items.erase(element)
	if _focused == element:
		_set_focused(null)


## Focuses the first element of the group, or clears focus when it is empty.
func focus_first() -> void:
	_set_focused(_items.front() if not _items.is_empty() else null)


## Focuses the given element. Focusing an element that is not in the group
## emits an error and is rejected.
func focus(element: UIElement) -> void:
	if not _items.has(element):
		push_error("Cannot focus an element that is not in the group")
		return
	_set_focused(element)


## Focuses the next element, wrapping around. Does nothing when the group is
## empty.
func next() -> void:
	_step(1)


## Focuses the previous element, wrapping around. Does nothing when the group
## is empty.
func previous() -> void:
	_step(-1)


## Returns the currently focused element, or null.
func get_focused() -> UIElement:
	return _focused


## Returns a copy of the selectable elements in insertion order.
func get_items() -> Array[UIElement]:
	return _items.duplicate()


## Steps the focus forward or backward, wrapping around the selection order.
func _step(direction: int) -> void:
	if _items.is_empty():
		return
	var index := 0
	if _focused != null:
		index = (_items.find(_focused) + direction + _items.size()) % _items.size()
	_set_focused(_items[index])


## Transitions focus to the given element, reporting effective changes.
func _set_focused(element: UIElement) -> void:
	if _focused == element:
		return
	var previous := _focused
	_focused = element
	focused_changed.emit(previous, element)