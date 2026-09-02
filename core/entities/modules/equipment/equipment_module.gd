extends Module
class_name EquipmentModule


## Emitted when an item is equipped in a slot, after any swap unequip.
signal equipped(slot: int, item: Object)

## Emitted when an item is removed from a slot, including by a swap.
signal unequipped(slot: int, item: Object)

## Equipped items keyed by slot identifier.
var _items: Dictionary = {}

## Modifiers currently applied per slot, remembered for symmetric removal.
var _applied_modifiers: Dictionary = {}


## Equips the given item in the given slot and applies its modifiers to the entity status.
## The operation is atomic: when any modifier targets a missing attribute, nothing changes.
## Equipping an occupied slot unequips its current item first.
## Returns false when the operation is rejected.
func equip(slot: int, item: Object, modifiers: Array[Modifier]) -> bool:
	var status := entity.modules.status.get_status()
	for modifier in modifiers:
		if not status.has_attribute(modifier.attribute_id):
			push_error("Modifier %d targets the missing attribute %d and cannot be equipped in slot %d" % [modifier.id, modifier.attribute_id, slot])
			return false
	if _items.has(slot):
		unequip(slot)
	for modifier in modifiers:
		status.get_attribute(modifier.attribute_id).add_modifier(modifier)
	var applied: Array[Modifier] = []
	applied.assign(modifiers)
	_items[slot] = item
	_applied_modifiers[slot] = applied
	equipped.emit(slot, item)
	return true


## Unequips the item in the given slot and removes exactly the modifiers applied on equip.
## Ignored with an error when the slot is empty.
func unequip(slot: int) -> void:
	if not _items.has(slot):
		push_error("Slot %d is not equipped in this equipment module" % slot)
		return
	var status := entity.modules.status.get_status()
	var applied: Array[Modifier] = _applied_modifiers[slot]
	for modifier in applied:
		status.get_attribute(modifier.attribute_id).remove_modifier(modifier)
	var item: Object = _items[slot]
	_items.erase(slot)
	_applied_modifiers.erase(slot)
	unequipped.emit(slot, item)


## Returns true if an item is currently equipped in the given slot.
func is_equipped(slot: int) -> bool:
	return _items.has(slot)


## Returns the item currently equipped in the given slot, or null when the slot is empty.
func get_equipped(slot: int) -> Object:
	return _items.get(slot)