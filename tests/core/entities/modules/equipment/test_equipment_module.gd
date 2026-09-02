extends GutTest


enum TestAttributeId { HEALTH, SPEED }
enum TestSlotId { WEAPON, ARMOR }
enum TestModifierId { SLOW }


func _create_entity() -> Entity:
	return Entity.new("TestEntity")


func _configure_status(p_entity: Entity) -> void:
	var status := p_entity.modules.status.get_status()
	status.add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	status.add_attribute(Attribute.new(TestAttributeId.SPEED, "Speed", 200.0))


func _create_speed_modifier(p_value: float) -> Modifier:
	return Modifier.new(TestModifierId.SLOW, "Slow", TestAttributeId.SPEED, p_value)


func test_participates_in_no_pipeline_phase() -> void:
	var equipment := EquipmentModule.new(_create_entity())
	assert_eq(equipment._get_phase_callbacks().size(), 0)


func test_module_is_created_lazily_and_reused() -> void:
	var entity := _create_entity()
	var equipment := entity.modules.equipment
	assert_not_null(equipment)
	assert_same(equipment, entity.modules.equipment)


func test_equip_applies_modifiers_to_the_status() -> void:
	var entity := _create_entity()
	_configure_status(entity)
	var item := RefCounted.new()
	assert_true(entity.modules.equipment.equip(TestSlotId.WEAPON, item, [_create_speed_modifier(-40.0)]))
	assert_same(entity.modules.equipment.get_equipped(TestSlotId.WEAPON), item)
	assert_eq(entity.modules.status.get_status().get_attribute(TestAttributeId.SPEED).get_effective_value(), 160.0)


func test_equip_applies_modifiers_across_attributes() -> void:
	var entity := _create_entity()
	_configure_status(entity)
	entity.modules.equipment.equip(TestSlotId.WEAPON, RefCounted.new(), [
		_create_speed_modifier(-40.0),
		Modifier.new(TestModifierId.SLOW, "Blessed", TestAttributeId.HEALTH, 10.0),
	])
	var status := entity.modules.status.get_status()
	assert_eq(status.get_attribute(TestAttributeId.SPEED).get_effective_value(), 160.0)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).get_effective_value(), 110.0)


func test_equip_with_empty_modifiers_equips_the_item() -> void:
	var entity := _create_entity()
	_configure_status(entity)
	var item := RefCounted.new()
	var modifiers: Array[Modifier] = []
	watch_signals(entity.modules.equipment)
	assert_true(entity.modules.equipment.equip(TestSlotId.WEAPON, item, modifiers))
	assert_signal_emitted_with_parameters(entity.modules.equipment, "equipped", [TestSlotId.WEAPON, item])
	assert_eq(entity.modules.status.get_status().get_attribute(TestAttributeId.SPEED).get_effective_value(), 200.0)


func test_equip_is_rejected_atomically_when_an_attribute_is_missing() -> void:
	var entity := _create_entity()
	var status := entity.modules.status.get_status()
	status.add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	var item := RefCounted.new()
	watch_signals(entity.modules.equipment)
	assert_false(entity.modules.equipment.equip(TestSlotId.WEAPON, item, [_create_speed_modifier(-40.0)]))
	assert_push_error_count(1, "a modifier targeting a missing attribute emits an error")
	assert_signal_not_emitted(entity.modules.equipment, "equipped")
	assert_false(entity.modules.equipment.is_equipped(TestSlotId.WEAPON))
	assert_null(entity.modules.equipment.get_equipped(TestSlotId.WEAPON))
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).get_effective_value(), 100.0)


func test_equip_rejection_keeps_the_current_item_equipped() -> void:
	var entity := _create_entity()
	_configure_status(entity)
	var equipment := entity.modules.equipment
	var first := RefCounted.new()
	equipment.equip(TestSlotId.WEAPON, first, [])
	var status := entity.modules.status.get_status()
	status.remove_attribute(TestAttributeId.SPEED)
	watch_signals(equipment)
	equipment.equip(TestSlotId.WEAPON, RefCounted.new(), [_create_speed_modifier(-40.0)])
	assert_push_error_count(1, "the rejected equip emits an error")
	assert_signal_not_emitted(equipment, "unequipped")
	assert_signal_not_emitted(equipment, "equipped")
	assert_same(equipment.get_equipped(TestSlotId.WEAPON), first)


func test_equip_over_an_occupied_slot_swaps_items() -> void:
	var entity := _create_entity()
	_configure_status(entity)
	var equipment := entity.modules.equipment
	var first := RefCounted.new()
	var second := RefCounted.new()
	equipment.equip(TestSlotId.WEAPON, first, [_create_speed_modifier(-40.0)])
	watch_signals(equipment)
	equipment.equip(TestSlotId.WEAPON, second, [_create_speed_modifier(-10.0)])
	assert_signal_emitted_with_parameters(equipment, "unequipped", [TestSlotId.WEAPON, first])
	assert_signal_emitted_with_parameters(equipment, "equipped", [TestSlotId.WEAPON, second])
	assert_same(equipment.get_equipped(TestSlotId.WEAPON), second)
	assert_eq(entity.modules.status.get_status().get_attribute(TestAttributeId.SPEED).get_effective_value(), 190.0)


func test_unequip_removes_the_item_and_its_modifiers() -> void:
	var entity := _create_entity()
	_configure_status(entity)
	var equipment := entity.modules.equipment
	var item := RefCounted.new()
	equipment.equip(TestSlotId.WEAPON, item, [_create_speed_modifier(-40.0)])
	watch_signals(equipment)
	equipment.unequip(TestSlotId.WEAPON)
	assert_false(equipment.is_equipped(TestSlotId.WEAPON))
	assert_null(equipment.get_equipped(TestSlotId.WEAPON))
	assert_signal_emitted_with_parameters(equipment, "unequipped", [TestSlotId.WEAPON, item])
	assert_eq(entity.modules.status.get_status().get_attribute(TestAttributeId.SPEED).get_effective_value(), 200.0)


func test_unequip_keeps_changes_made_to_current_value() -> void:
	var entity := _create_entity()
	_configure_status(entity)
	var equipment := entity.modules.equipment
	equipment.equip(TestSlotId.WEAPON, RefCounted.new(), [_create_speed_modifier(-40.0)])
	var status := entity.modules.status.get_status()
	status.get_attribute(TestAttributeId.SPEED).current_value = 180.0
	equipment.unequip(TestSlotId.WEAPON)
	assert_eq(status.get_attribute(TestAttributeId.SPEED).get_effective_value(), 180.0)


func test_unequip_of_an_empty_slot_is_rejected() -> void:
	var entity := _create_entity()
	var equipment := entity.modules.equipment
	watch_signals(equipment)
	equipment.unequip(TestSlotId.WEAPON)
	assert_push_error_count(1, "unequipping an empty slot emits an error")
	assert_signal_not_emitted(equipment, "unequipped")


func test_slots_are_independent() -> void:
	var entity := _create_entity()
	_configure_status(entity)
	var equipment := entity.modules.equipment
	var weapon := RefCounted.new()
	var armor := RefCounted.new()
	equipment.equip(TestSlotId.WEAPON, weapon, [_create_speed_modifier(-40.0)])
	equipment.equip(TestSlotId.ARMOR, armor, [Modifier.new(TestModifierId.SLOW, "Blessed", TestAttributeId.HEALTH, 10.0)])
	var status := entity.modules.status.get_status()
	assert_same(equipment.get_equipped(TestSlotId.WEAPON), weapon)
	assert_same(equipment.get_equipped(TestSlotId.ARMOR), armor)
	assert_eq(status.get_attribute(TestAttributeId.SPEED).get_effective_value(), 160.0)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).get_effective_value(), 110.0)
	equipment.unequip(TestSlotId.WEAPON)
	assert_eq(status.get_attribute(TestAttributeId.SPEED).get_effective_value(), 200.0)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).get_effective_value(), 110.0)