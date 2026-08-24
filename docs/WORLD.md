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

An entity must be removed from its world before being released. Otherwise its module connections to the update pipeline keep it alive and receiving updates.

An entity's world is maintained exclusively through these lifecycle methods. `Entity.set_world(world)` changes worlds by composing them: detach in the old world, then register in the new one. See ENTITIES.md and MODULES.md.

The temporal cycle originates in the `World`. Entities do not manage their own tick.

# Update Pipeline

`UpdatePipeline` coordinates the phases of the update cycle.

Established decisions:

* `World` owns and executes the pipeline from its update cycle. The update flow goes exclusively through `update_pipeline.update()`.
* `World` must not know or call concrete systems such as Movement, Collision or State.
* Phases are identified by the `UpdatePipeline.Phase` enum, nested in `UpdatePipeline` and defined in `core`. Loose numeric identifiers are not allowed.
* The pipeline keeps the signal of each phase internally in a dictionary whose insertion order defines the execution order. Phase order belongs exclusively to the pipeline.
* `phase_signal(phase)` returns the signal of a phase. Phase signals receive no arguments.
* The pipeline executes a phase and then emits that phase's signal. The signal is the mechanism through which modules receive the phase.
* Modules connect directly to the signals of the phases they need, through the participations they declare. See MODULES.md for the connection mechanics.
* There is no module registration and no `ModuleManager`.
* `World` and the pipeline do not know which concrete modules exist.
* Connection order to a phase signal must never become an architectural dependency. If a phase ever requires ordering its participants, it must be resolved through an explicit priority/dependency mechanism, never through accidental connection order.
* Currently the only defined phase is `Phase.STATE`. Other phases will be added only when a concrete need appears.

Status: implemented with `Phase.STATE` as its only phase.

# Area

`Area` is a core abstraction representing a region that keeps track of which entities are inside it.

Real spatial detection belongs to the game: core provides only the API for the game to notify entries and exits.

Area is composed of an `EntityHandler` holding the entities currently inside. It has no identity, name or id of its own; identity belongs to `Entity`.

## Admission

* `enter(entity) -> bool`: validates through `can_enter(entity)`. Rejects entities already inside or denied by the admission filter. On success returns true and emits `entity_entered`.
* `exit(entity)`: operates only on registered entities; otherwise the attempt is rejected with an error. On success emits `entity_exited`.
* `can_enter(entity) -> bool`: evaluates an optional admission filter callable. Without a filter, any entity may enter. The filter applies only at admission time; entities already inside are never revalidated.
* `has_entity(entity)` and `get_entities()` provide membership queries.

Signals `entity_entered(entity)` and `entity_exited(entity)` are emitted only when the state actually changes.

Area does not mix with collision layers, physics, proximity, 2D/3D or nodes; those concerns belong to the game.

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
└── State
    └── rules
```

World-specific configuration should not contain game-specific behavior unless explicitly required.