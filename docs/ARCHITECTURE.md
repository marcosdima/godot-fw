# Architecture

## Purpose

This project is a reusable foundation for videogame development.

It is divided into two main domains:

* `core`: Generic and reusable systems that can be used by different games.
* `game`: The concrete game built on top of `core`.

The goal is to develop the foundation and a working game template in the same project while keeping game-specific logic isolated from the reusable framework.

## Project Structure

```
project/
├── core/
├── game/
├── docs/
└── project.godot
```

The exact internal structure of `core` and `game` may evolve as the architecture develops.

## Dependency Rules

### Core

`core` contains generic concepts and systems.

`core` must never depend on `game`.

`core` should avoid depending on Godot when the functionality does not require the engine.

For example, data-oriented classes such as `Attribute`, `Effect`, or `Condition` should not inherit from `Node` unless there is a concrete reason to do so.

### Game

`game` may depend on `core`.

Game-specific implementations belong in `game`.

Examples:

* Concrete conditions such as `BurnCondition` or `WetCondition`.
* Game-specific rules.
* Game-specific effects.
* Game-specific entities.
* Game-specific attributes.
* Game-specific UI.

# General Design Principles

## Composition over inheritance

Inheritance should represent a real "is-a" relationship.

Do not use inheritance merely to reuse code.

Prefer composition when representing capabilities or optional systems.

For example:

```
Entity
└── StateSystem
```

is preferable to creating a large inheritance hierarchy only to guarantee that an entity has state.

Inheritance is appropriate when a type is genuinely a specialization of another type.

For example:

```
Entity
└── DynamicEntity
```

can be appropriate when `DynamicEntity` is genuinely a specialized entity.

## Core should remain generic

Generic systems must not contain knowledge of concrete game mechanics.

For example, `StateSystem` may manage conditions, effects and rules, but it must not contain logic specifically referring to `Burn`, `Wet`, `Poison`, or other game-specific concepts.

Game-specific behavior must be expressed through the abstractions provided by `core`.

# Element

`Element` is the common base abstraction for identifiable elements.

It provides:

* `id`
* `name`
* common string representation

Elements should share common behavior through this abstraction when appropriate.

Do not add functionality to `Element` merely because multiple classes could theoretically use it.

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
    └── EffectHandler
```

`StateSystem` should not depend on concrete game-specific types.

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

Rules primarily operate on condition intensity.

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

# Handlers

Handlers provide generic management of collections of `Element` instances.

The base `Handler` provides operations such as:

* add
* remove
* lookup by ID
* contains
* clear
* get value
* set value

Specialized handlers may extend this behavior when domain-specific operations are required.

Examples:

```
Handler
├── ConditionHandler
└── EffectHandler
```

Handlers should remain focused on managing their respective data and should not become general-purpose managers.

## EffectHandler

`EffectHandler` remains a `Handler` because it stores active `EffectApplication`s and their processing state.

It processes applications on `StateSystem` ticks.

It generates and processes `Effect`s.

It resolves `Effect` targets through `Status` and applies them to the corresponding `Attribute`s.

Applications associated with a `Condition` are removed when that `Condition` is removed.

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

The exact implementation may evolve.

The update system should remain generic and must not contain game-specific condition logic.

## EffectApplication Sources

`EffectApplication`s can originate from two sources:

* **Conditions**, for persistent effects that last as long as the condition is alive.
* **Direct gameplay actions**, for instant effects submitted directly to `EffectHandler`.

# Rules

`Rule` represents an abstract interaction or modification involving conditions.

Rules exist to prevent condition interactions from being hardcoded into the state system.

For example, the interaction between `Burn` and `Wet` should not be implemented as:

```
if Burn and Wet:
    remove Burn
```

Instead, the game should be able to define a rule describing that interaction.

Example conceptual rule:

```
WeakenRule

target = Burn
presence = Wet
factor = 0.5
```

## Scope

Rules operate at the `StateSystem` level.

A `StateSystem` may have its own rules, specific to that entity.

The `World` may eventually define a set of general rules applicable to StateSystems. See Future.

Rules must not depend on `Entity` or `World`.

## Rule Inputs

Rules operate only on Conditions.

They do not operate on Attributes or Effects.

Effects are transient results and do not independently represent state to react to.

## Rule Effects

For the initial implementation, rules may modify only `Condition.intensity`.

Rules do not directly modify the `ConditionHandler`. The `StateSystem` evaluates rules and performs the necessary structural changes through the `ConditionHandler`.

Reducing a condition's intensity to zero or below is the mechanism for removing it. A rule that cancels a condition this way is a valid rule concept.

When a rule brings a condition to an intensity that is no longer alive, that condition and its effect applications leave the circuit before effect applications are processed in that same tick.

## Evaluation

The `StateSystem` evaluates rules sequentially, in priority order.

Each rule receives the current conditions and may modify their intensity directly.

Rules evaluated later observe modifications made by rules evaluated earlier.

## Priority

Rules have an integer priority. Higher numeric priority executes first.

Ordering is deterministic and shared by all StateSystems. Rules with equal priority are ordered by ascending identifier.

Registration order must not affect evaluation order.

## Ownership

The rule infrastructure (`Rule`, `RuleHandler`) belongs to `core`.

Concrete rules belong to `game`.

# World

`World` represents the environment in which entities exist.

It is responsible for world-level systems such as:

* entity registration/spawning;
* entity collections;
* physics/world configuration;
* rules available to the world.

`WorldConfig` contains configurable world-level settings.

For example:

```
WorldConfig
├── Physics
│   ├── gravity
│   └── physics_ticks_per_second
│
└── State
    └── rules
```

World-specific configuration should not contain game-specific behavior unless explicitly required.

# Entities

Entities represent objects that exist in the world.

The project currently considers three fundamental entity categories:

```
Entity
├── Static
├── Dynamic
└── Area
```

The exact relationship between these types and Godot's node classes is still subject to refinement.

The entity abstraction should not be unnecessarily coupled to 2D.

For example, a concept representing a dynamic entity should not inherently require the name or implementation `DynamicEntity2D` unless the entity is specifically tied to 2D; and that is game-specific.

# Signals

Systems may expose signals to notify other systems when relevant state changes occur.

Examples include:

* `condition_added`
* `condition_removed`
* `effect_applied`
* `modifier_added`
* `modifier_removed`

Signals should allow systems such as UI, animation, audio, or gameplay logic to react without requiring the state system to know about those consumers.

Prefer direct Godot signals where a direct relationship exists.

Do not introduce a global event bus merely for the sake of having one.

A global event bus may be considered later if a concrete architectural need for decoupled communication appears.

# Identifiers

Game-specific identifiers must not be represented by unexplained numeric literals.

Do not write:

```
Effect.new(1, -0.5)
```

when the number represents a game concept.

Game-specific identifiers should be represented using enums.

For example:

```
enum AttributeId {
    HEALTH,
    SPEED,
    STRENGTH,
}
```

Then:

```
Effect.new(AttributeId.HEALTH, -0.5)
```

The generic `core` systems may store identifiers without knowing their game-specific meaning.

The concrete meaning of those identifiers belongs to `game`.

# Architectural Decisions

When a new requirement appears, prefer the smallest abstraction that solves the problem.

Do not introduce:

* managers;
* service locators;
* global event buses;
* unnecessary interfaces;
* deep inheritance hierarchies;
* unnecessary singletons;

unless there is a concrete architectural reason.

If a requirement cannot be cleanly implemented using the current architecture, the preferred behavior is to propose alternatives and discuss the architectural change before implementing it.

# Future

Deliberately deferred architectural possibilities. Do not implement these until a concrete need appears.

* WorldConfig/World integration with StateSystem rules: automatically supplying world-level rules to StateSystems, if it requires additional coupling. Example: IdleRule(Burn) decreasing Burn intensity over time as a world rule, while a Blaze defines an entity-specific CancelRule(Burn) that reacts to the resulting state.
* Rules that create Conditions. Example: Wet + Cold -> Sick.
* Rules affecting Attributes or Effects.
* Condition/intensity manipulation beyond the current intensity-only model.
