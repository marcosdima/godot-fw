extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")


enum TestAttributeId { HEALTH, MISSING }
enum TestApplicationId { DAMAGE }


func _create_status() -> Status:
	var status := Status.new()
	status.add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	return status


func test_apply_effect_modifies_current_value_through_status() -> void:
	var handler := EffectHandler.new()
	var status := _create_status()
	handler.apply_effect(Effect.new(TestAttributeId.HEALTH, -5.0), status)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 95.0)


func test_apply_effect_respects_attribute_min_value() -> void:
	var handler := EffectHandler.new()
	var status := Status.new()
	status.add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 10.0, 0.0))
	handler.apply_effect(Effect.new(TestAttributeId.HEALTH, -40.0), status)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 0.0)


func test_apply_effect_ignores_unknown_target() -> void:
	var handler := EffectHandler.new()
	var status := _create_status()
	handler.apply_effect(Effect.new(TestAttributeId.MISSING, -5.0), status)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 100.0)


func test_process_fires_application_at_its_rate() -> void:
	var handler := EffectHandler.new()
	var status := _create_status()
	handler.add(ConstantApplication.new(TestApplicationId.DAMAGE, "Damage", 2, Effect.new(TestAttributeId.HEALTH, -5.0)))
	handler.process(status)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 100.0)
	handler.process(status)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 95.0)


func test_process_fires_rate_one_application_every_tick() -> void:
	var handler := EffectHandler.new()
	var status := _create_status()
	handler.add(ConstantApplication.new(TestApplicationId.DAMAGE, "Damage", 1, Effect.new(TestAttributeId.HEALTH, -5.0)))
	handler.process(status)
	handler.process(status)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 90.0)


func test_submit_instant_applies_once_on_next_process() -> void:
	var handler := EffectHandler.new()
	var status := _create_status()
	handler.submit_instant(ConstantApplication.new(TestApplicationId.DAMAGE, "Damage", 1, Effect.new(TestAttributeId.HEALTH, -5.0)))
	handler.process(status)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 95.0)
	handler.process(status)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 95.0)


func test_remove_applications_stops_processing() -> void:
	var handler := EffectHandler.new()
	var status := _create_status()
	var application := ConstantApplication.new(TestApplicationId.DAMAGE, "Damage", 1, Effect.new(TestAttributeId.HEALTH, -5.0))
	handler.add(application)
	var applications: Array[EffectApplication] = [application]
	handler.remove_applications(applications)
	handler.process(status)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 100.0)