extends Module
class_name InventoryModule


## Emitted when an item is added to this inventory.
signal item_added(item: Object)

## Emitted when an item is removed from this inventory.
signal item_removed(item: Object)

## Items currently held, in insertion order.
var _items: Array[Object] = []


## Adds an item to this inventory and emits item_added.
## Returns false and rejects the item when it is already held.
func add(item: Object) -> bool:
	if _items.has(item):
		push_error("Item %d is already held by this inventory" % item.get_instance_id())
		return false
	_items.append(item)
	item_added.emit(item)
	return true


## Removes an item from this inventory and emits item_removed.
## Ignored with an error when the item is not held.
func remove(item: Object) -> void:
	if not _items.has(item):
		push_error("Item %d is not held by this inventory" % item.get_instance_id())
		return
	_items.erase(item)
	item_removed.emit(item)


## Returns true if the given item is currently held by this inventory.
func has_item(item: Object) -> bool:
	return _items.has(item)


## Returns the items currently held by this inventory, in insertion order.
func get_items() -> Array[Object]:
	return _items.duplicate()