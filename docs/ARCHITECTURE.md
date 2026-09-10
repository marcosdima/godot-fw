# Architecture

## Purpose

This project is a reusable foundation for videogame development.

It is divided into two main domains:

* `core`: Generic and reusable systems that can be used by different games.
* `game`: The concrete game built on top of `core`.

The goal is to develop the foundation and a working game template in the same project while keeping game-specific logic isolated from the reusable framework.

`game` and `game/docs/` historically belonged to prototype branches. Today the game-side UI runs on `main` as the working vertical slice of the reusable UI domain; game-specific documentation continues to live in `game/`.

## Project Structure

```
project/
├── core/
│   ├── entities/
│   │   ├── entity.gd
│   │   ├── entity_handler.gd
│   │   ├── entity_resolvers.gd
│   │   ├── resolvers/
│   │   └── modules/
│   │       ├── interaction/
│   │       ├── modules.gd
│   │       ├── module.gd
│   │       ├── phase_callback.gd
│   │       ├── phase_connection.gd
│   │       ├── progression/
│   │       ├── rules/
│   │       ├── state/
│   │       ├── status/
│   │       ├── equipment/
│   │       └── inventory/
│   ├── primitives/
│   │   ├── element.gd
│   │   └── handler.gd
│   ├── ui/
│   │   ├── animation/
│   │   │   ├── track.gd
│   │   │   ├── ui_animation_definition.gd
│   │   │   └── ui_animation_playback.gd
│   │   ├── margin.gd
│   │   ├── screen_stack.gd
│   │   ├── selection_group.gd
│   │   ├── style_data.gd
│   │   ├── ui_button.gd
│   │   ├── ui_container.gd
│   │   ├── ui_element.gd
│   │   └── ui_text.gd
│   └── world/
│       ├── area.gd
│       ├── update_pipeline.gd
│       └── world.gd
├── game/
│   └── ui/
│       ├── hud/
│       ├── menus/
│       ├── agent_settings.gd
│       ├── app_ui.gd
│       ├── main_menu.tscn
│       ├── screen.gd
│       ├── ui_control_adapter.gd
│       └── ui_host.gd
├── tests/
│   ├── core/
│   └── game/
├── docs/
└── project.godot
```

The exact internal structure of `core` and `game` may evolve as the architecture develops.

## Documentation Index

Architecture-specific decisions live in focused documents. This file holds the entry point, the transversal decisions and the general principles.

The documentation tree mirrors the `core/` folder structure; transversal documents live at the root.

* [CORE_CONTRACT.md](CORE_CONTRACT.md): The established architectural invariants and strong current contracts that must not be changed silently.
* [AGENT_GUIDELINES.md](AGENT_GUIDELINES.md): The process implementation agents follow to discover, implement, verify and escalate.
* [BRANCHES.md](BRANCHES.md): Branch categories: contracts of experiments and prototypes towards `core`, naming conventions and active branches.
* [PRIMITIVES.md](primitives/PRIMITIVES.md): Base abstractions shared by all domains (`Element`, `Handler`).
* [ENTITIES.md](entities/ENTITIES.md): Entity domain: identity and the composition-oriented entity model.
* [MODULES.md](entities/MODULES.md): Module model: ownership, lazy activation, lifecycle, world changes and module-to-module access.
* [RESOLVERS.md](entities/RESOLVERS.md): Entity resolvers: interpreting conditions and effects in the context of an entity.
* [INTERACTION.md](entities/modules/INTERACTION.md): Interaction domain: available interactions, per-source presentation, focus semantics and execution.
* [STATE_MODULE.md](entities/modules/state/STATE_MODULE.md): State domain: conditions, effects, effect applications, signals and the state update cycle.
* [STATUS_MODULE.md](entities/modules/status/STATUS_MODULE.md): Status domain: the status module, attributes, modifiers and status mutation.
* [PROGRESSION.md](entities/modules/PROGRESSION.md): Progression domain: progression values as a per-entity capability.
* [EQUIPMENT.md](entities/modules/EQUIPMENT.md): Equipment domain: slotted items and status modifiers applied while equipped.
* [INVENTORY.md](entities/modules/INVENTORY.md): Inventory domain: opaque per-entity item storage keyed by instance identity.
* [RULES.md](entities/modules/rules/RULES.md): Rules domain: reactive per-entity relations that react to module facts.
* [WORLD.md](world/WORLD.md): World domain: environment, entity lifecycle management, dimension-agnostic areas, update cycle and `UpdatePipeline`.
* [UI.md](ui/UI.md): UI domain: engine-light interface model in `core/ui` and the materializing adapter in `game/ui`.

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

Composition is the preferred way to represent capabilities or optional systems. It is not an absolute rule: inheritance remains appropriate whenever a type is genuinely a specialization of another type.

For example:

```
Entity
└── Modules
    └── StateModule
```

is preferable to creating a large inheritance hierarchy only to guarantee that an entity has capabilities.

Inheritance is appropriate when a type is genuinely a specialization of another type. For example:

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

Contractually, the same principle governs evolution: prefer the smallest abstraction that satisfies an actual requirement, and do not let this preference prevent a larger abstraction when evidence genuinely requires one. See CORE_CONTRACT.md.

## Entity back-references

Ownership and lifetime safety is a structural invariant: owned objects must not keep their owner alive, and owned objects must not be reachable in a way that creates unintended lifetime cycles.

Objects owned by an entity hold their reference back to it weakly.

* `Module.entity` and `Resolver.entity` are weak references.
* `Rule._entity` is a weak reference.
* The `Modules` and `EntityResolvers` facades hold their entity weakly.
* `EffectApplication.condition` is a weak reference to its owning condition.

Owner-to-owned references remain strong: `Entity -> Modules`, `Entity -> EntityResolvers`, `Modules -> Module`, `EntityResolvers -> Resolver`, `RulesModule -> Rule`.

A strong back-reference would create a `RefCounted` cycle: the objects in the cycle would never reach a zero reference count and entities would never be freed. Owned objects die with their entity, so a weak back-reference is always valid while the owned object is alive.

`WeakRef` is the current mechanism used to realize this invariant. The invariant is the contract; if a better mechanism appears, the invariant remains.

# Runtime and Clock

Core is step-based: advancing the simulation means calling `world.update()`, which executes exactly one update cycle. Who repeatedly advances the cycle over time is decided by the runtime, never by `core`.

Core never starts timers, threads or engine processes, and never reads an engine clock. The loop that calls `world.update()` belongs to the runtime. Tests drive worlds manually, tick by tick; a game maps its own clock to `world.update()` calls.

This keeps `core` engine-independent and leaves the choice of clock entirely to the game. See WORLD.md for the concrete update cycle and its pipeline.

The same rule holds for UI: `core/ui` playbacks advance only through `advance(delta)` calls made by the game, and the game decides the clock. See UI.md.

# Signals

Systems may expose signals to notify other systems when relevant state changes occur.

Signals are per-entity and emit on the module that owns the state change. They represent effective changes only: a signal is emitted when the state actually changes, not when an attempt is made.

Implemented signals:

* `StateModule`: `condition_added`, `condition_removed`, `effect_applied`.
* `InteractionModule`: `interaction_added`, `interaction_removed`, `focused_changed`.
* `EquipmentModule`: `equipped`, `unequipped`.
* `InventoryModule`: `item_added`, `item_removed`.
* `Progression`: `value_changed`.
* `Area`: `occupant_entered`, `occupant_exited`.
* `UpdatePipeline`: the phase signals, including `state`.
* `UIElement`: `changed`, `child_added`, `child_removed`.
* `SelectionGroup`: `focused_changed`.
* `ScreenStack`: `changed`.
* `UIAnimationPlayback`: `finished`, `stopped`.

Signals should allow systems such as UI, animation, audio, gameplay logic, or rules to react without requiring the emitting module to know about those consumers.

Prefer direct Godot signals where a direct relationship exists.

Do not introduce a global event bus merely for the sake of having one. A global event bus may be considered later if a concrete architectural need for decoupled communication appears.

# System Overview

Concise summaries of each major system. Detailed behavior lives in the linked domain document; this is a map, not a duplicate.

## Primitives

`Element` is the common base for identifiable elements (`id`, `name`). `Handler` generically manages collections of `Element` instances (add, remove, lookup, iteration). Specialized handlers extend the base for domain-specific operations.

See [PRIMITIVES.md](primitives/PRIMITIVES.md).

## Entity

`Entity` is the common abstraction of objects that exist in a `World`. Identity belongs to the entity; the current static incremental counter is temporary. The entity is oriented toward composition: it owns a `Modules` facade and an `EntityResolvers` facade, and holds the reference to the `World` it belongs to.

See [ENTITIES.md](entities/ENTITIES.md).

## Modules

Modules are optional capabilities of an entity, created lazily on first access and permanent once instantiated. `entity.modules.<name>` is the only access path. Modules may access sibling modules at operation time; there is no dependency declaration system and no registration with the World.

See [MODULES.md](entities/MODULES.md).

## Resolvers

Resolvers are per-entity collaborators, not modules. They interpret gameplay facts (a condition to add, an effect to apply) in the context of an entity before those facts affect its state. They are pure decision points: they return a result but never mutate state themselves.

See [RESOLVERS.md](entities/RESOLVERS.md).

## State

`StateModule` administers conditions and processes effects. It participates in the pipeline `Phase.STATE` with its `tick()` method, which runs the fixed decay → remove-dead → activate-new → process-effects cycle. Conditions and effects are decided by resolvers; the module consumes their results and emits signals about what happened.

See [STATE_MODULE.md](entities/modules/state/STATE_MODULE.md).

## Status

`StatusModule` administers `Status`, a dictionary of `Attribute`s with `base_value`, `current_value` and `Modifier`s that contribute to the effective value. Mutation is delegated to `Attribute.current_value`, where bounds are enforced. The module participates in no pipeline phase.

See [STATUS_MODULE.md](entities/modules/status/STATUS_MODULE.md).

## Progression

`ProgressionModule` provides per-entity progression values that change over time or through rules, exposing `value_changed`. The module participates in no pipeline phase.

See [PROGRESSION.md](entities/modules/PROGRESSION.md).

## Interaction

`InteractionModule` maintains the available interactions of an entity, the currently focused one and the offerings presented by external sources. Availability is source-based and multi-reason: base interactions are added manually, and external sources can present offerings that are tracked and retracted. It participates in no pipeline phase.

See [INTERACTION.md](entities/modules/INTERACTION.md).

## Equipment

`EquipmentModule` holds items in slots and applies their modifiers to the entity's status while equipped. Equipping is atomic and removes exactly the modifier instances it applied. It participates in no pipeline phase.

See [EQUIPMENT.md](entities/modules/EQUIPMENT.md).

## Inventory

`InventoryModule` holds opaque items keyed by instance identity, in insertion order. It participates in no pipeline phase.

See [INVENTORY.md](entities/modules/INVENTORY.md).

## Rules

`Rule` represents a reactive relation between module facts: when a subscribed module fact happens, the rule evaluates the current state of the entity and may produce a consequence by calling public module APIs. `RulesModule` owns the rules of an entity, registers them on demand and subscribes them to the facts they declare. Rules run in connection order; there is no guaranteed order across rules. The module participates in no pipeline phase.

See [RULES.md](entities/modules/rules/RULES.md).

## World, Update Pipeline and Area

`World` represents the environment in which entities exist: registration, spawning and removal, the entity collection and the update cycle. `UpdatePipeline` coordinates `Phase.STATE` and any future phases; modules connect directly to phase signals and the World never knows concrete modules. `Area` is a dimension-agnostic region tracking occupants; real spatial detection belongs to the game.

See [WORLD.md](world/WORLD.md).

## UI

`core/ui` is an engine-light interface model: a `UIElement` tree (containers, buttons, text and text input with a committed-value model) with styles, selection and simple animation. The model never touches Godot. `game/ui` materializes it into `Control` nodes through `UIControlAdapter` and binds the stack, input and clock through `UIHost`; the game composes its screens on the host through `AppUI`. Layout is applied one way, model to view; measurements are never written back. The runtime clock that advances playbacks belongs to the game.

See [UI.md](ui/UI.md).

## Update Cycle Summary

```
world.update()
    └── UpdatePipeline completes Phase.STATE
            └── StateModule.tick() runs the state cycle
```

The state tick order is a behavioral contract. See CORE_CONTRACT.md and STATE_MODULE.md.

# Cross-Module Relationships

Modules may access sibling modules directly through `entity.modules.<name>` at operation time. The table below records the accesses present in the current implementation. It is observational, not prescriptive: direct coupling is allowed when sensible, and future accesses may be added without declaring dependencies.

| Source                          | Target          | Purpose                              |
| ------------------------------- | --------------- | ------------------------------------ |
| `StateModule`                   | `StatusModule`  | apply effects to attributes          |
| `EquipmentModule`               | `StatusModule`  | apply/remove modifiers while equipped |

Rules access whatever modules their reaction needs through the entity at call time; that is game-side configuration, described in RULES.md.

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