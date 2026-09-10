extends Element
class_name UIElement


## Emitted after a property of this element actually changes, with the property name.
signal changed(property: StringName)

## Emitted after a child is added to this element.
signal child_added(child: UIElement)

## Emitted after a child is removed from this element.
signal child_removed(child: UIElement)


## Children of this element in insertion order.
var _children: Array[UIElement] = []

## Weak reference back to the parent element, or null for a root element.
var _parent_ref: WeakRef

## Whether the element is rendered and interactive.
var visible := true:
	set(value):
		if visible == value:
			return
		visible = value
		changed.emit(&"visible")

## Whether the element accepts interaction.
var enabled := true:
	set(value):
		if enabled == value:
			return
		enabled = value
		changed.emit(&"enabled")

## Position of the element within its parent, in parent-local units.
var position := Vector2.ZERO:
	set(value):
		if position == value:
			return
		position = value
		changed.emit(&"position")

## Intended size of the element. Containers may lay children out according to
## this value; layout results are never written back into it.
var size := Vector2.ZERO:
	set(value):
		if size == value:
			return
		size = value
		changed.emit(&"size")

## Scale applied to the element when rendered.
var scale := Vector2.ONE:
	set(value):
		if scale == value:
			return
		scale = value
		changed.emit(&"scale")

## Vertical stacking order; higher values render on top.
var z_index := 0:
	set(value):
		if z_index == value:
			return
		z_index = value
		changed.emit(&"z_index")

## Opacity of the element, from 0.0 (invisible) to 1.0 (fully opaque).
var modulate := 1.0:
	set(value):
		if modulate == value:
			return
		modulate = value
		changed.emit(&"modulate")

## Visual style applied to this element when rendered. Kept on the base
## element because every current element kind renders a surface.
var style := StyleData.new():
	set(value):
		if style == value:
			return
		style = value
		changed.emit(&"style")


## The parent of this element, or null when it is a root element.
var parent: UIElement:
	get:
		if _parent_ref == null:
			return null
		return _parent_ref.get_ref()


## Creates a new UI element with the given identifier and name.
func _init(p_id: int, p_name: String) -> void:
	super(p_id, p_name)


## Adds the given element as a child, reparenting it when it already belongs to
## another element. Rejects adding an element to itself or to one of its own
## descendants, which would create a cycle.
func add(child: UIElement) -> void:
	if child == self:
		push_error("UIElement cannot add itself as a child")
		return
	if _children.has(child):
		return
	if _contains(child):
		push_error("UIElement cannot add an element that is already a descendant")
		return
	if child._contains(self):
		push_error("UIElement cannot add an element that already contains this element")
		return
	if child.parent != null:
		child.parent.remove(child)
	_children.append(child)
	child._set_parent(self)
	child_added.emit(child)


## Removes the given child from this element. Emits an error when the child is
## not a direct child of this element.
func remove(child: UIElement) -> void:
	if not _children.has(child):
		push_error("Cannot remove an element that is not a child")
		return
	_children.erase(child)
	child._set_parent(null)
	child_removed.emit(child)


## Removes all children of this element.
func clear() -> void:
	for child in _children.duplicate():
		remove(child)


## Returns the children of this element in insertion order.
func get_children() -> Array[UIElement]:
	return _children.duplicate()


## Assigns the weak reference to the parent of this element. Changing the parent
## outside of add() or remove() is not allowed.
func _set_parent(new_parent: UIElement) -> void:
	_parent_ref = weakref(new_parent) if new_parent != null else null


## Returns true when the given element is this element or one of its descendants.
func _contains(element: UIElement) -> bool:
	if element == self:
		return true
	for child in _children:
		if child._contains(element):
			return true
	return false