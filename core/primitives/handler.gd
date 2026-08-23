extends RefCounted
class_name Handler


## Elements keyed by their identifier.
var _elements: Dictionary = {}


## Adds an element to this handler.
func add(element: Element) -> void:
	_elements[element.id] = element


## Removes an element from this handler.
func remove(element: Element) -> void:
	_elements.erase(element.id)


## Returns the element with the given identifier, or null if it does not exist.
func lookup_by_id(id: int) -> Element:
	return _elements.get(id)


## Returns true if an element with the given identifier exists.
func contains(id: int) -> bool:
	return _elements.has(id)


## Removes all elements from this handler.
func clear() -> void:
	_elements.clear()


## Returns the value stored for the given identifier, or null if it does not exist.
func get_value(id: int) -> Element:
	return _elements.get(id)


## Stores the given element under the given identifier, replacing any previous value.
func set_value(id: int, element: Element) -> void:
	_elements[id] = element


## Returns all elements in this handler.
func get_elements() -> Array[Element]:
	var elements: Array[Element] = []
	elements.assign(_elements.values())
	return elements