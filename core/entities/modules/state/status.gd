extends RefCounted
class_name Status


## Attributes keyed by their identifier.
var _attributes: Dictionary = {}


## Adds an attribute to this status.
func add_attribute(attribute: Attribute) -> void:
	_attributes[attribute.id] = attribute


## Removes the attribute with the given identifier.
func remove_attribute(attribute_id: int) -> void:
	_attributes.erase(attribute_id)


## Returns the attribute with the given identifier, or null if it does not exist.
func get_attribute(attribute_id: int) -> Attribute:
	return _attributes.get(attribute_id)


## Returns true if an attribute with the given identifier exists.
func has_attribute(attribute_id: int) -> bool:
	return _attributes.has(attribute_id)


## Returns all attributes in this status.
func get_attributes() -> Array[Attribute]:
	return _attributes.values()