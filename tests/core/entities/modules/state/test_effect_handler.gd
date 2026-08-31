extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")


enum TestAttributeId { HEALTH }
enum TestEffectKind { FIRE }
enum TestApplicationId { DAMAGE }


func _create_damage_application(p_rate: int = 1) -> EffectApplication:
	return ConstantApplication.new(TestApplicationId.DAMAGE, "Damage", p_rate, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0))


func test_process_returns_no_effects_without_applications() -> void:
	var handler := EffectHandler.new()
	assert_eq(handler.process().size(), 0)


func test_process_returns_the_effect_when_the_rate_is_reached() -> void:
	var handler := EffectHandler.new()
	handler.add(_create_damage_application(2))
	assert_eq(handler.process().size(), 0)
	var effects := handler.process()
	assert_eq(effects.size(), 1)
	assert_eq(effects[0].kind, TestEffectKind.FIRE)
	assert_eq(effects[0].target, TestAttributeId.HEALTH)
	assert_eq(effects[0].value, -5.0)


func test_process_returns_the_effect_of_rate_one_applications_every_tick() -> void:
	var handler := EffectHandler.new()
	handler.add(_create_damage_application(1))
	assert_eq(handler.process().size(), 1)
	assert_eq(handler.process().size(), 1)


func test_submit_instant_returns_its_effect_once_on_the_next_process() -> void:
	var handler := EffectHandler.new()
	handler.submit_instant(_create_damage_application(1))
	var effects := handler.process()
	assert_eq(effects.size(), 1)
	assert_eq(effects[0].target, TestAttributeId.HEALTH)
	assert_eq(handler.process().size(), 0)


func test_applications_without_effect_generate_nothing() -> void:
	var handler := EffectHandler.new()
	handler.add(EffectApplication.new(TestApplicationId.DAMAGE, "Damage", 1))
	assert_eq(handler.process().size(), 0)


func test_remove_applications_stops_processing() -> void:
	var handler := EffectHandler.new()
	var application := _create_damage_application(1)
	handler.add(application)
	var applications: Array[EffectApplication] = [application]
	handler.remove_applications(applications)
	assert_eq(handler.process().size(), 0)