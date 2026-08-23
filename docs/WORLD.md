# World

`World` represents the environment in which entities exist.

It is responsible for world-level concerns such as:

* entity registration, spawning and removal;
* the entity collection;
* the update cycle;
* world configuration.

Entities are managed through `EntityHandler`, the entity collection belonging to the World, built on the generic `Handler` primitive. See PRIMITIVES.md and ENTITIES.md.

## Entity Lifecycle

* **register**: adds an externally created entity to the world.
* **spawn**: creates an entity, registers it and returns it.
* **remove**: removes an entity from the world.

Registering an entity whose id already exists in the world emits an error and is ignored; the original entity remains untouched.

The temporal cycle originates in the `World`. Entities do not manage their own tick.

# Update Pipeline

`UpdatePipeline` coordinates the phases of the update cycle.

Established decisions:

* `World` owns and executes the pipeline from its update cycle. The update flow goes exclusively through `UpdatePipeline.update()`.
* `World` must not know or call concrete systems such as Movement, Collision or State.
* Phases are identified by the `UpdatePipeline.Phase` enum, nested in `UpdatePipeline` and defined in `core`. Loose numeric identifiers are not allowed.
* The pipeline executes a phase and then emits that phase's signal. The signal is the mechanism through which modules receive the phase.
* Modules connect directly to the signals of the phases they need.
* There is no module registration and no `ModuleManager`.
* `World` and the pipeline do not know which concrete modules exist.
* Connection order to a phase signal must never become an architectural dependency. If a phase ever requires ordering its participants, it must be resolved through an explicit priority/dependency mechanism, never through accidental connection order.
* Concrete phases and their order are deliberately not defined yet. They will be decided once the module abstractions are finalized.

Status: implemented with zero phases. Concrete phases remain undefined until module abstractions are finalized.

# WorldConfig

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