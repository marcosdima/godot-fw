# State System

The state system represents the current state of an entity.

The system is designed to be composable and should not require every entity to have a state.

An entity that requires state owns a `StateSystem`.

`StateSystem` is independent of the physical representation of an entity or world. It must not depend on 2D, 3D, physics, or a specific entity implementation.

`StateSystem` is tick-based. Its update cycle advances in discrete ticks rather than continuous time.

Conceptually:

```
Entity
└── StateSystem
    ├── Status
    ├── ConditionHandler
    ├── EffectHandler
    └── RuleHandler
```

`StateSystem` should not depend on concrete game-specific types.

The handlers used by the state system are built on the generic `Handler` primitive. See PRIMITIVES.md.

## Status

`Status` represents the current values of an entity's attributes.

Conceptually:

```
Status
└── Attribute
    ├── base_value
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

`base_value` represents the original value and is never modified by the state system.

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

`StateSystem` must not contain knowledge of concrete conditions.

## Condition Intensity

Intensity represents the remaining strength/lifetime of a condition.

When a condition reaches a state where its intensity is no longer sufficient to remain alive, it should be removed from the state system.

A condition is alive while its intensity is greater than zero. `Condition.is_alive()` is defined as `intensity > 0` and encapsulates this rule so that `StateSystem` does not need to know how condition lifetime is represented. `StateSystem` must use `is_alive()` instead of directly checking intensity.

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

It is the persistent/process-level abstraction. It can persist across multiple `StateSystem` ticks.

It may belong to a `Condition`, but does not inherently require one. It may also represent an instant effect submitted directly to `EffectHandler`.

Its rate is expressed in `StateSystem` ticks, not seconds.

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

The state system manages its collections through specialized handlers built on the generic `Handler` primitive. See PRIMITIVES.md.

## EffectHandler

`EffectHandler` remains a `Handler` because it stores active `EffectApplication`s and their processing state.

It processes applications on `StateSystem` ticks.

It generates and processes `Effect`s.

It resolves `Effect` targets through `Status` and applies them to the corresponding `Attribute`s.

Applications associated with a `Condition` are removed when that `Condition` is removed.

`ConditionHandler` provides typed access to conditions. The evaluation contract of `RuleHandler` is documented in RULES.md.

# State System Update

The conceptual update order is:

```
1. Evaluate rules.
2. Update conditions.
3. Remove conditions that are no longer alive, together with their registered effect applications.
4. Activate newly active conditions.
5. Register their effect applications.
6. Apply effects according to their applications.
```

Conditions brought to a dead state by rules exit the circuit at step 3, before their effect applications are processed in that same tick.

Rules are evaluated at step 1. Their inputs, effects, evaluation order and priority contract are documented in RULES.md.

The exact implementation may evolve.

The update system should remain generic and must not contain game-specific condition logic.