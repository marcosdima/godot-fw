extends GutTest


enum TestAttributeId { HEALTH }
enum TestApplicationId { DAMAGE }


func test_stores_target_and_value() -> void:
	var effect := Effect.new(TestAttributeId.HEALTH, -5.0)
	assert_eq(effect.target, TestAttributeId.HEALTH)
	assert_eq(effect.value, -5.0)


func test_default_rate_is_one_tick() -> void:
	var application := EffectApplication.new(TestApplicationId.DAMAGE, "Damage")
	assert_eq(application.rate, 1)


func test_stores_custom_rate() -> void:
	var application := EffectApplication.new(TestApplicationId.DAMAGE, "Damage", 3)
	assert_eq(application.rate, 3)


func test_base_generate_effect_returns_null() -> void:
	var application := EffectApplication.new(TestApplicationId.DAMAGE, "Damage")
	assert_null(application.generate_effect())