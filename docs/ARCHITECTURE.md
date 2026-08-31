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
│   ├── entities/
│   │   ├── entity.gd
│   │   ├── entity_handler.gd
│   │   ├── resolvers/
│   │   └── modules/
│   │       ├── interaction/
│   │       ├── progression/
│   │       ├── rules/
│   │       ├── state/
│   │       └── status/
│   ├── primitives/
│   └── world/
│       ├── area.gd
│       ├── update_pipeline.gd
│       └── world.gd
├── game/
├── tests/
├── docs/
└── project.godot
```

The exact internal structure of `core` and `game` may evolve as the architecture develops.

## Documentation Index

Architecture-specific decisions live in focused documents. This file holds the entry point, the transversal decisions and the general principles.

The documentation tree mirrors the `core/` folder structure; transversal documents live at the root.

* [PRIMITIVES.md](primitives/PRIMITIVES.md): Base abstractions shared by all domains (`Element`, `Handler`).
* [ENTITIES.md](entities/ENTITIES.md): Entity domain: identity and the composition-oriented entity model.
* [MODULES.md](entities/MODULES.md): Module model: ownership, lazy activation, lifecycle, world changes and module-to-module access.
* [RESOLVERS.md](entities/RESOLVERS.md): Entity resolvers: interpreting conditions and effects in the context of an entity.
* [INTERACTION.md](entities/modules/INTERACTION.md): Interaction domain: available interactions, focus semantics and execution.
* [STATE_MODULE.md](entities/modules/state/STATE_MODULE.md): State domain: conditions, effects, effect applications, signals and the state update cycle.
* [STATUS_MODULE.md](entities/modules/status/STATUS_MODULE.md): Status domain: the status module, attributes, modifiers and status mutation.
* [PROGRESSION.md](entities/modules/progression/PROGRESSION.md): Progression domain: progression values as a per-entity capability.
* [RULES.md](entities/modules/rules/RULES.md): Rules domain: reactive per-entity relations that react to module facts.
* [WORLD.md](world/WORLD.md): World domain: environment, entity lifecycle management, update cycle and `UpdatePipeline`.
* [BRANCHES.md](BRANCHES.md): Branch categories: contracts of experiments and prototypes towards `core`, naming conventions and active branches.


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
* Game-specific effect kinds and identifiers.
* Game-specific resolvers, such as an effect resolver reduced by fire resistance.
* Game-specific rule definitions, such as a rule that removes Burn while Wet is present.
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
└── Modules
    └── StateModule
```

is preferable to creating a large inheritance hierarchy only to guarantee that an entity has capabilities.

Inheritance is appropriate when a type is genuinely a specialization of another type.

For example:

```
Element
└── Attribute
```

is appropriate because `Attribute` is genuinely a specialized identifiable element.

## Core should remain generic

Generic systems must not contain knowledge of concrete game mechanics.

For example, `StateModule` may manage conditions and effects, but it must not contain logic specifically referring to `Burn`, `Wet`, `Poison`, or other game-specific concepts.

Game-specific behavior must be expressed through the abstractions provided by `core`.

## Identifiers

Game-specific identifiers must not be represented by unexplained numeric literals.

Do not write:

```
Effect.new(1, AttributeId.HEALTH, -0.5)
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

enum EffectKind {
    FIRE,
    POISON,
}
```

Then:

```
Effect.new(EffectKind.FIRE, AttributeId.HEALTH, -0.5)
```

The generic `core` systems may store identifiers without knowing their game-specific meaning.

The concrete meaning of those identifiers belongs to `game`.

Do not introduce string identifiers when an enum is appropriate.

## Prefer the smallest abstraction

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

## Entity back-references

Objects owned by an entity hold their reference back to it weakly.

* `Module.entity` and `Resolver.entity` are weak references.
* The `Modules` and `EntityResolvers` facades hold their entity weakly.
* `EffectApplication.condition` is a weak reference to its owning condition.

Owner-to-owned references remain strong: `Entity -> Modules`, `Entity -> EntityResolvers`, `Modules -> Module`, `EntityResolvers -> Resolver`.

A strong back-reference would create a `RefCounted` cycle: the objects in the cycle would never reach a zero reference count and entities would never be freed. Owned objects die with their entity, so a weak back-reference is always valid while the owned object is alive.

# Signals

Systems may expose signals to notify other systems when relevant state changes occur.

`StateModule` currently emits `condition_added`, `condition_removed` and `effect_applied`. Other examples, not yet implemented, include:

* `modifier_added`
* `modifier_removed`

Signals should allow systems such as UI, animation, audio, or gameplay logic to react without requiring the state module to know about those consumers.

Prefer direct Godot signals where a direct relationship exists.

Do not introduce a global event bus merely for the sake of having one.

A global event bus may be considered later if a concrete architectural need for decoupled communication appears.

# Future

Deliberately deferred architectural possibilities. Do not implement these until a concrete need appears.

* Ordering guarantees across rules reacting to the same fact, if a game ever needs two rules on the same signal with a defined order. Rules today react in connection order.
* Built-in generic rule implementations in core, if a recurring reaction pattern emerges across games. The semantics currently belong to the game.
* Sustained condition modulation (for example, weakening a condition while another state is present). Today this is expressed by composing discrete reactions; if that proves insufficient, the next piece should be a condition modifier abstraction, not a rule engine.
* Condition/intensity manipulation beyond the current intensity-only model.
* Modifier expiry: giving modifiers a lifetime within the update cycle, probably through a StatusModule phase callback.
* TagModule: possible future capability for tagging entities. Not part of the current implementation.
* Time-dependent phases: extending the phase signal contract with delta/time once the first time-based module appears. STATE remains intentionally tick-based until then.
* Explicit participant priority within a phase, if a second STATE participant ever makes connection order relevant.
* An entity disposal API, if manual remove-before-release proves error-prone in practice.
