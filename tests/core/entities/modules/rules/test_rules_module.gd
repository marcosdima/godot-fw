extends GutTest


enum TestSourceId { PING }


## Minimal fact source used to exercise the subscription mechanic without
## depending on a concrete module.
class FakeSource extends RefCounted:
	signal ping(value: int)

	var ping_count: int = 0

	func ping_now(value: int) -> void:
		ping_count += 1
		ping.emit(value)


## Rule that subscribes to a FakeSource fact and records the triggered values.
class RecordingRule extends Rule:
	var source: FakeSource
	var last_value: int = -1
	var triggered_count: int = 0

	func _init(p_entity: Entity, p_source: FakeSource) -> void:
		super(p_entity)
		source = p_source

	func subscribe() -> void:
		_add_subscription(source.ping, _on_ping)

	func _on_ping(value: int) -> void:
		last_value = value
		triggered_count += 1


func test_add_rule_subscribes_and_get_rules_returns_it() -> void:
	var entity := Entity.new("Mortal")
	var source := FakeSource.new()
	var rule := RecordingRule.new(entity, source)
	entity.modules.rules.add_rule(rule)

	source.ping_now(TestSourceId.PING)

	assert_eq(rule.triggered_count, 1)
	assert_eq(rule.last_value, TestSourceId.PING)
	assert_eq(entity.modules.rules.get_rules().size(), 1)
	assert_same(entity.modules.rules.get_rules()[0], rule)


func test_add_rule_is_idempotent() -> void:
	var entity := Entity.new("Mortal")
	var source := FakeSource.new()
	var rule := RecordingRule.new(entity, source)
	var rules := entity.modules.rules

	rules.add_rule(rule)
	rules.add_rule(rule)

	assert_eq(rules.get_rules().size(), 1)


func test_remove_rule_unsubscribes_the_rule() -> void:
	var entity := Entity.new("Mortal")
	var source := FakeSource.new()
	var rule := RecordingRule.new(entity, source)
	var rules := entity.modules.rules

	rules.add_rule(rule)
	rules.remove_rule(rule)
	source.ping_now(TestSourceId.PING)

	assert_eq(rule.triggered_count, 0)
	assert_eq(rules.get_rules().size(), 0)


func test_rule_and_rules_module_are_freed_with_the_entity() -> void:
	var entity := Entity.new("Mortal")
	var source := FakeSource.new()
	var rule := RecordingRule.new(entity, source)
	entity.modules.rules.add_rule(rule)
	var entity_ref: WeakRef = weakref(entity)
	var rules_ref: WeakRef = weakref(entity.modules.rules)
	var rule_ref: WeakRef = weakref(rule)

	entity = null
	rule = null
	source = null

	assert_null(entity_ref.get_ref())
	assert_null(rules_ref.get_ref())
	assert_null(rule_ref.get_ref())