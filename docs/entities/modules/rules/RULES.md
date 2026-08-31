# Rules

`Rule` represents a reactive relation between module facts: when a fact happens, the rule evaluates the current state of the entity and may produce a consequence.

Rules are per-entity, live in a module owned by the entity (`RulesModule`) and are configured by the game. `core` provides the mechanism; the game defines the concrete relations.

## Fact Driven

Rules react to facts already happened, exposed by modules through their signals:

* a condition added or removed (`condition_added`, `condition_removed`);
* a progression value changed (`value_changed`);
* any future module signal.

Rules do not run on every tick and do not observe decision points such as resolvers. They decide nothing about whether a fact should have happened; they react to it.

Examples of relations a game defines:

```gdscript
# Burn removed while Wet is present, regardless of entry order.
class RemoveBurnWhenWetRule extends Rule:
	func subscribe() -> void:
		var state := get_entity().modules.state
		_add_subscription(state.condition_added, _on_condition_added)

	func _on_condition_added(_added: Condition) -> void:
		var state := get_entity().modules.state
		var burn := state.get_condition(GameConditionId.BURN)
		if burn != null and state.get_condition(GameConditionId.WET) != null:
			state.remove_condition(burn)
```

```gdscript
# Fireproof gained once fire resistance reaches ten.
class GainFireproofRule extends Rule:
	func subscribe() -> void:
		var progression := get_entity().modules.progression.get_progression()
		_add_subscription(progression.value_changed, _on_value_changed)

	func _on_value_changed(progression_id: int, new_value: int) -> void:
		var state := get_entity().modules.state
		if progression_id == GameProgressionId.FIRE_RESISTANCE and new_value >= 10 \
				and state.get_condition(GameConditionId.FIREPROOF) == null:
			state.add_condition(Condition.new(GameConditionId.FIREPROOF, "Fireproof", 100.0))
```

The first rule reacts to any added condition and evaluates the current coexistence, so it works regardless of the order Burn and Wet enter. There is no tracking of known conditions.

## Rule Base

`Rule` is a plain `RefCounted` bound to an entity:

* `_init(p_entity)` stores a weak reference to the entity. The chain Entity -> Modules -> RulesModule -> Rule -> Entity must not form a `RefCounted` cycle. See Entity back-references in ARCHITECTURE.md.
* `get_entity()` returns that entity.
* `subscribe()` is the game override that connects the rule to the facts it reacts to, using `_add_subscription()` so `unsubscribe()` can undo them.
* `_add_subscription(trigger, callable)` connects a rule to a module signal and records the connection.
* `unsubscribe()` disconnects exactly what the rule subscribed. Game overrides call `super()`.

## RulesModule

`RulesModule` is an ordinary lazy module, accessed through `entity.modules.rules`:

* `add_rule(rule)` registers the rule and calls `rule.subscribe()`.
* `remove_rule(rule)` unregisters the rule and calls `rule.unsubscribe()`.
* `get_rules()` returns a copy of the registered rules in registration order.

There are no identifiers, priorities or evaluation order. Rules reacting to the same fact run in connection order, and core guarantees no ordering across them.

## Consequences

A rule produces consequences by calling module APIs: adding or removing conditions, applying instant applications, or advancing progressions. The state module remains the only owner of its conditions; rules never mutate `intensity` or handler internals directly.

## Scope

Rules must not depend on `Entity` or `World`. A rule reads other modules through its entity at call time and only the modules its reaction needs.

## Core and Game

`core` provides the mechanism: `Rule` base and `RulesModule` under `entities/modules/rules/`.

The game defines the concrete rules, the game identifiers they react to and the configuration:

```gdscript
entity.modules.rules.add_rule(RemoveBurnWhenWetRule.new(entity))
```

## Testing

The mechanism is exercised with a fake fact source and a recording rule: registration subscribes, removal unsubscribes, and rules are released together with their entity. Concrete relations are integration-tested against real modules in both entry orders.