# World

`World` represents the environment in which entities exist.

It is responsible for world-level concerns such as:

* entity registration, spawning and removal;
* the entity collection;
* the update cycle;
* world configuration.

Entities are managed through `EntityHandler`, the entity collection belonging to the World, built on the generic `Handler` primitive. See PRIMITIVES.md and ENTITIES.md.

The collection is exposed directly as `world.entity_handler`. Lookup and membership operations belong to the handler; the World owns only the lifecycle and does not mirror the handler's API.

## Entity Lifecycle

* **register**: adds an externally created entity to the world, sets its world and attaches its active modules.
* **spawn**: creates an entity, registers it and returns it.
* **remove**: removes an entity from the world, detaches its active modules and clears its world.

Registering an entity whose id already exists here, or that already belongs to another world, emits an error and is ignored. Removing an entity that does not belong to this world emits an error and is ignored.

An entity must be removed from its world before being released. Pipeline connections hold strong references to their callbacks, so a registered entity whose modules participate in the update cycle remains alive and keeps receiving ticks even when the game no longer uses it. Enforcing this removal order is a responsibility of the runtime.

An entity's world is maintained exclusively through these lifecycle methods. `Entity.set_world(world)` changes worlds by composing them: detach in the old world, then register in the new one. See ENTITIES.md and MODULES.md.

The temporal cycle originates in the `World`. Entities do not manage their own tick. Who repeatedly advances the cycle over time is decided in Runtime and Clock below.

# Update Pipeline

`UpdatePipeline` coordinates the phases of the update cycle.

Established decisions:

* `World` owns and executes the pipeline from its update cycle. The update flow goes exclusively through `update_pipeline.update()`.
* `World` must not know or call concrete systems such as Movement, Collision or State.
* Phases are identified by the `UpdatePipeline.Phase` enum, nested in `UpdatePipeline` and defined in `core`. Loose numeric identifiers are not allowed.
* The pipeline keeps the signal of each phase internally in a dictionary whose insertion order defines the execution order. Phase order belongs exclusively to the pipeline.
* `phase_signal(phase)` returns the signal of a phase. Phase signals receive no arguments.
* Executing a phase consists of emitting its phase signal. The signal is the mechanism through which modules receive the phase.
* Modules connect directly to the signals of the phases they need, through the participations they declare. See MODULES.md for the connection mechanics.
* There is no module registration and no `ModuleManager`.
* `World` and the pipeline do not know which concrete modules exist.
* Connection order to a phase signal must never become an architectural dependency. If a phase ever requires ordering its participants, it must be resolved through an explicit priority/dependency mechanism, never through accidental connection order.
* Currently the only defined phase is `Phase.STATE`. Other phases will be added only when a concrete need appears.

Status: implemented with `Phase.STATE` as its only phase.

# Runtime and Clock

Core is step-based: advancing the simulation means calling `world.update()`, which executes exactly one update cycle.

Core never starts timers, threads or engine processes, and never reads an engine clock. The loop that calls `world.update()` repeatedly belongs to the runtime, never to `core`:

* Tests drive worlds manually, tick by tick.
* The game owns the clock. A future Godot entry point (for example a Main2D node) maps its engine ticks to `world.update()` calls.

This keeps `core` engine-independent and leaves the choice of clock (frame, physics tick, fixed accumulator) entirely to the game.

## Mutation During a Phase

* The pipeline never iterates entities, so spawning, registering or removing entities during a phase is structurally safe.
* Handlers expose snapshots of their collections, so modules may mutate their own state while that state is being iterated.
* Structural changes performed during a phase take effect on subsequent ticks, not on the current one.

# Area

`Area` is a core abstraction representing a region that keeps track of which occupants are inside it. It is dimension-agnostic: occupants are plain `Object`s, so entities, nodes and any other runtime object can be tracked without core knowing the dimension.

Real spatial detection belongs to the game: core provides only the API for the game to notify entries and exits.

## Occupants

Occupants are keyed by object identity: the same instance appears once, and two distinct instances are distinct occupants. `Area` has no identity, name or id of its own; identity belongs to the occupant.

`Area` does not mix with collision layers, physics, proximity, 2D/3D or nodes; those concerns belong to the game. A game wrapper (for example a node with an area detection shape) decides which object enters: a body may enter as its `Entity`, as its node, or as both, consistently per area.

## Admission

* `enter(occupant) -> bool`: validates through `can_enter(occupant)`. Rejects occupants already inside or denied by the admission filter. On success returns true and emits `occupant_entered`.
* `exit(occupant)`: operates only on occupants inside; otherwise the attempt is rejected with an error. On success emits `occupant_exited`.
* `can_enter(occupant) -> bool`: evaluates an optional admission filter callable. Without a filter, any occupant may enter. The filter applies only at admission time; occupants already inside are never revalidated.
* `has_occupant(occupant)` and `get_occupants()` provide membership queries. `get_occupants()` returns the original instances in insertion order.

Signals `occupant_entered(occupant)` and `occupant_exited(occupant)` are emitted only when the state actually changes.

## Lifetime

The game must call `exit` before destroying an occupant, mirroring the interaction source contract. Core does not sweep stale references; only the game knows when an occupant is destroyed.

# WorldConfig

`WorldConfig` contains configurable world-level settings.

Status: not implemented. The configuration surface will be defined when a concrete need appears.

For example:

```
WorldConfig
├── Physics
│   ├── gravity
│   └── physics_ticks_per_second
│
└── Rules
```

World-specific configuration should not contain game-specific behavior unless explicitly required.