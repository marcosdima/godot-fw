extends GutTest


enum TestConditionId { BURN }
enum TestApplicationId { FIRE_DAMAGE }


func test_stores_intensity() -> void:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	assert_eq(condition.intensity, 10.0)


func test_is_alive_while_intensity_greater_than_zero() -> void:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	assert_true(condition.is_alive())


func test_is_not_alive_when_intensity_reaches_zero() -> void:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 0.0)
	assert_false(condition.is_alive())


func test_is_not_alive_with_negative_intensity() -> void:
	var condition := Condition.new(TestConditionId.BURN, "Burn", -1.0)
	assert_false(condition.is_alive())


func test_add_and_get_effect_applications() -> void:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	var application := EffectApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage")
	condition.add_effect_application(application)
	assert_eq(condition.get_effect_applications().size(), 1)
	assert_true(condition.get_effect_applications().has(application))


func test_condition_handler_add_get_remove() -> void:
	var handler := ConditionHandler.new()
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	handler.add_condition(condition)
	assert_eq(handler.get_condition(TestConditionId.BURN), condition)
	handler.remove_condition(condition)
	assert_null(handler.get_condition(TestConditionId.BURN))


func test_condition_handler_get_conditions_returns_all() -> void:
	var handler := ConditionHandler.new()
	handler.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))
	assert_eq(handler.get_conditions().size(), 1)