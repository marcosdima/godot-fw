extends GutTest


enum TestConditionId { BURN, WET, FIREPROOF }
enum TestProgressionId { FIRE_RESISTANCE }


## Removes BURN whenever BURN and WET coexist, regardless of the order they are
## added in.
class RemoveBurnWhenWetRule extends Rule:
	func subscribe() -> void:
		var state := get_entity().modules.state
		_add_subscription(state.condition_added, _on_condition_added)

	func _on_condition_added(_added: Condition) -> void:
		var state := get_entity().modules.state
		var burn := state.get_condition(TestConditionId.BURN)
		if burn != null and state.get_condition(TestConditionId.WET) != null:
			state.remove_condition(burn)


## Adds FIREPROOF once fire resistance reaches ten.
class GainFireproofRule extends Rule:
	func subscribe() -> void:
		var progression := get_entity().modules.progression.get_progression()
		_add_subscription(progression.value_changed, _on_value_changed)

	func _on_value_changed(progression_id: int, new_value: int) -> void:
		var state := get_entity().modules.state
		if progression_id == TestProgressionId.FIRE_RESISTANCE and new_value >= 10 \
				and state.get_condition(TestConditionId.FIREPROOF) == null:
			state.add_condition(Condition.new(TestConditionId.FIREPROOF, "Fireproof", 100.0))


func test_burn_is_removed_when_wet_comes_after_burn() -> void:
	var entity := Entity.new("Mortal")
	entity.modules.rules.add_rule(RemoveBurnWhenWetRule.new(entity))
	var state := entity.modules.state

	state.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))
	state.add_condition(Condition.new(TestConditionId.WET, "Wet", 10.0))

	assert_null(state.get_condition(TestConditionId.BURN))
	assert_not_null(state.get_condition(TestConditionId.WET))


func test_burn_is_removed_when_wet_comes_before_burn() -> void:
	var entity := Entity.new("Mortal")
	entity.modules.rules.add_rule(RemoveBurnWhenWetRule.new(entity))
	var state := entity.modules.state

	state.add_condition(Condition.new(TestConditionId.WET, "Wet", 10.0))
	state.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))

	assert_null(state.get_condition(TestConditionId.BURN))
	assert_not_null(state.get_condition(TestConditionId.WET))


func test_fireproof_is_added_when_fire_resistance_reaches_ten() -> void:
	var entity := Entity.new("Mortal")
	entity.modules.rules.add_rule(GainFireproofRule.new(entity))
	var progression := entity.modules.progression.get_progression()

	progression.set_value(TestProgressionId.FIRE_RESISTANCE, 5)
	assert_null(entity.modules.state.get_condition(TestConditionId.FIREPROOF))

	progression.advance(TestProgressionId.FIRE_RESISTANCE, 5)
	assert_not_null(entity.modules.state.get_condition(TestConditionId.FIREPROOF))