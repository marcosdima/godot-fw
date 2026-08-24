# State Module

`StateModule` is the state capability of an entity, implemented as a Module. See MODULES.md for the module model.

It represents the current state of an entity.

State remains optional: entities that never access their state module simply do not have one.

An entity gains state by accessing its state module (`entity.modules.state`), which creates it lazily on first access.

`StateModule` holds a reference to its owning entity through the `Module` base. This does not couple it to 2D, 3D, physics, or a specific entity implementation.

`StateModule` is tick-based. Its update cycle advances in discrete ticks rather than continuous time. The module participates in `UpdatePipeline.Phase.STATE` with its `tick()` method, so its ticks arrive through its world pipeline connection. `tick()` remains available for driving the module directly, which is how logic is exercised without a world.

Conceptually:

```
Entity
└── Modules
    └── StateModule
        ├── Status
        ├── ConditionHandler
        ├── EffectHandler
        └── RuleHandler
```

`StateModule` should not depend on concrete game-specific types.

The handlers used by the state module are built on the generic `Handler` primitive. See PRIMITIVES.md.

## Status

`Status` represents the current values of an entity's attributes.

Conceptually:

```
Status
└── Attribute
    ├── base_value
    ├── current_value
    └── modifiers
```

Examples of possible attributes:

* Health
* Speed
* Strength

The actual attributes used by a game are game-specific.

## Attribute

An `Attribute` represents a measurable property of an entity.

An attribute has a base value and may have modifiers.

The base value should represent the underlying value.

`base_value` represents the original value and is never modified by the state module.

`current_value` represents the mutable current state of the attribute. Effects modify `current_value`.

Modifiers do not modify `current_value` directly. The effective value is calculated separately from `current_value` and the active modifiers.

## Modifier

A `Modifier` represents a temporary or contextual modification to an `Attribute`.

For example:

```
Speed
base_value = 100

Slow modifier = -40

effective value = 60
```

When the modifier expires or is removed, the attribute returns to its previous effective value.

Modifiers should not permanently alter the underlying attribute value.

The exact lifetime and interaction rules for modifiers are not yet finalized.

# Conditions

A `Condition` represents a state acquired by an entity during gameplay.

Conditions generally have:

* an identity;
* an intensity;
* one or more `EffectApplication`s;
* a lifetime determined by their intensity/state.

Examples:

* Burn
* Wet
* Poison
* Frozen

The base `Condition` class belongs to `core`.

Concrete conditions belong to `game`.

Example:

```
core
└── Condition

game
└── BurnCondition
```

`StateModule` must not contain knowledge of concrete conditions.

## Condition Intensity

Intensity represents the remaining strength/lifetime of a condition.

When a condition reaches a state where its intensity is no longer sufficient to remain alive, it should be removed from the state module.

A condition is alive while its intensity is greater than zero. `Condition.is_alive()` is defined as `intensity > 0` and encapsulates this rule so that `StateModule` does not need to know how condition lifetime is represented. `StateModule` must use `is_alive()` instead of directly checking intensity.

# Effects

An `Effect` is a transient data representation of an effect applied at a particular moment.

It contains information such as:

* target identifier;
* value.

An `Effect` should remain a lightweight data object and should not contain complex behavior.

An `Effect` must not reference an `Attribute`, `Status`, or `Entity`. It only carries the target identifier and the value to apply.

Once processed, an `Effect` does not need to remain registered.

For example:

```
Effect
target = Health
value = -5
```

The concrete meaning of an effect is determined by the system processing it.

# Effect Applications

`EffectApplication` describes how an effect is generated and applied over time.

It is the persistent/process-level abstraction. It can persist across multiple `StateModule` ticks.

It may belong to a `Condition`, but does not inherently require one. It may also represent an instant effect submitted directly to `EffectHandler`.

Its rate is expressed in `StateModule` ticks, not seconds.

Do not introduce separate `InstantEffectApplication` / `PersistentEffectApplication` classes. A single `EffectApplication` abstraction covers both cases.

This distinction is intentional:

```
Condition
└── EffectApplication
    └── Effect
```

`EffectApplication` represents the process or definition of applying an effect.

`Effect` represents the concrete result at a particular moment.

An application may calculate different effects depending on the current state of its associated condition.

For example:

```
BurnCondition
intensity = 10

    ↓

FireDamageApplication

    ↓

Effect
target = Health
value = calculated from Burn intensity
```

Concrete effect applications may belong to `game` when their behavior is game-specific.

## EffectApplication Sources

`EffectApplication`s can originate from two sources:

* **Conditions**, for persistent effects that last as long as the condition is alive.
* **Direct gameplay actions**, for instant effects submitted directly to `EffectHandler`.

# State Handlers

The state module manages its collections through specialized handlers built on the generic `Handler` primitive. See PRIMITIVES.md.

## EffectHandler

`EffectHandler` remains a `Handler` because it stores active `EffectApplication`s and their processing state.

It processes applications on `StateModule` ticks.

It generates and processes `Effect`s.

It resolves `Effect` targets through `Status` and applies them to the corresponding `Attribute`s.

Applications associated with a `Condition` are removed when that `Condition` is removed.

`ConditionHandler` provides typed access to conditions. The evaluation contract of `RuleHandler` is documented in RULES.md.

# Update Cycle

The conceptual update order is:

```
1. Evaluate rules.
2. Remove conditions that are no longer alive, together with their registered effect applications.
3. Activate newly active conditions.
4. Register their effect applications.
5. Apply effects according to their applications.
```

Conditions brought to a dead state by rules exit the circuit at step 2, before their effect applications are processed in that same tick.

Rules are evaluated at step 1. Their inputs, effects, evaluation order and priority contract are documented in RULES.md.

The exact implementation may evolve.

The update system should remain generic and must not contain game-specific condition logic.