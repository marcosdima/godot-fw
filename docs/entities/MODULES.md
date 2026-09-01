# Modules

`Modules` is the facade through which an `Entity` owns and accesses its capabilities.

Modules are optional capabilities of an entity. There are no default modules: `Modules.new(entity)` does not instantiate anything. Every module is created lazily on first access.

# Ownership

* A `Module` belongs to exactly one `Entity`.
* A module cannot be transferred between entities.
* A module keeps a weak reference to its entity, assigned at construction and never changed. Weak so the Entity -> Modules -> Module -> Entity chain does not form a `RefCounted` cycle that would prevent entities from ever being freed. See Entity back-references in ARCHITECTURE.md.
* The entity owns its `Modules` object and delegates module lifecycle concerns to it.
* The entity does not directly manage concrete modules; it communicates through `Modules`.

Conceptually:

```
Entity
└── Modules
    ├── state
    ├── status
    ├── progression
    ├── interaction
    ├── rules
    └── _active
```

# Lazy Activation

Accessing a module property creates it if it does not already exist:

```
entity.modules.state
    ↓
StateModule.new(entity)
    ↓
_active.append(state)
    ↓
state.attach()
```

Creating a module means activating it. `Modules` always calls `attach()` when a module becomes active.

`attach()` is called even if `entity.world == null`. If there is no World, an implementation that needs the World simply has nothing to connect to and returns normally. The module is still considered active.

If a World is assigned later, `Modules` calls `attach()` again for the active modules.

There is no separate "active but unattached" state.

# Module Base

`Module` is a concrete base class, not an abstract class. It is a plain logic class and must not inherit from Godot types unless a concrete requirement makes it necessary.

```
Module
├── entity
├── _get_phase_callbacks()
├── attach()
└── detach()
```

`entity` is assigned when the module is constructed and cannot change. It is held weakly; see Entity back-references in ARCHITECTURE.md.

Modules declare their participation in the world update cycle by overriding `_get_phase_callbacks()`, which returns one `PhaseCallback` per participated phase: a pure data container holding the phase and the callback invoked when that phase runs. Base modules participate in none.

`attach()` connects every declared callback to the corresponding signal of the entity's current World `UpdatePipeline` and records each connection made as a `PhaseConnection`: a pure data container holding the connected signal and the callable. Without a World there is nothing to connect to and the module attaches normally. `detach()` disconnects exactly the connections recorded during `attach()`.

Connection order to a phase signal carries no architectural meaning. If participants of a phase ever require ordering, resolve it explicitly. See WORLD.md.

No protection against duplicated attach exists; the World and Modules lifecycle guarantees the correct sequence.

Concrete modules never connect to pipeline signals manually. Overriding `attach()` or `detach()` for other external relationships requires calling `super()` so the phase connections are preserved.

`PhaseCallback` and `PhaseConnection` are defined in their own files under `entities/modules/`; neither manages connections nor contains logic.

Module creation produces a usable active module. Do not introduce a separate setup or initialization step; `Module.new(entity)` creates the module and `Modules` immediately registers it as active and calls `attach()`.

A concrete module may use Godot-specific APIs when its behavior explicitly requires them. The base abstraction remains engine-independent.

# Persistence

A module remains alive for the lifetime of its entity once instantiated.

There is currently no individual module deactivation or removal API.

```
not instantiated
    ↓
lazy access
    ↓
instantiated + active
    ↓
remains active
    ↓
entity destroyed
```

If a future concrete requirement needs module suspension or deactivation, introduce it then rather than assuming it now.

# Active Collection

`Modules` maintains `_active: Array[Module]`, containing every currently instantiated module.

`_active` has no semantic ordering. No architecture may depend on the order of this collection.

If module ordering or dependencies become necessary later, they must be solved through an explicit mechanism rather than accidental collection or signal connection order.

# World Relationship

Modules belong to Entities, not Worlds.

Module internal state survives an entity changing World. However, a module may need to reconnect to the new World's `UpdatePipeline`.

Modules do not store their own World reference. They access the current World through their entity, which remains the source of truth for its current World.

# World Changes

`Entity.set_world(world)` is the only supported mechanism for changing an entity's World. The transition is coordinated through `Modules`:

```
detach active modules        # while entity.world still refers to the old World
change Entity.world          # through the World lifecycle methods
attach active modules        # while entity.world refers to the new World
```

This ordering is intentional and must be preserved.

If there is no previous World, there is nothing meaningful to detach. If the new World is null, active modules receive `attach()` and decide that there is nothing to connect to.

World and pipeline do not know which concrete modules exist. There is no module registration system and no `ModuleManager`.

See WORLD.md for how the World lifecycle methods maintain the entity-world relationship.

# Module-to-Module Access

Modules may access other modules through `entity.modules.<module>`.

There is no dependency declaration system. Accessing a non-instantiated module lazily creates it. This is intentional.

Do not introduce dependency injection, dependency registries, service locators, or similar abstractions unless a concrete problem requires them.

Avoid accessing sibling modules during module construction, attach or detach; lazy resolution during those windows can recurse.

# StateModule

`StateModule` is the state capability of an entity. See STATE_MODULE.md for its internal responsibilities.

It is an ordinary lazy module: created on first access like any other module.

Its update cycle runs through the world update cycle: the module participates in `UpdatePipeline.Phase.STATE` with its `tick()` method. `tick()` remains available for driving the module directly, which is how state logic is exercised without a world.

It resolves added conditions and generated effects through the entity's resolvers, see RESOLVERS.md, and emits signals about what happened.

# InteractionModule

`InteractionModule` is the interaction capability of an entity. See INTERACTION.md for the complete model.

It maintains the available interactions, the currently focused one and the offerings presented by external sources. It is an ordinary lazy module and does not connect to world context.

# StatusModule

`StatusModule` is the status capability of an entity. See STATUS_MODULE.md for its internal responsibilities.

It is an ordinary lazy module and participates in no pipeline phase.

# ProgressionModule

`ProgressionModule` is the progression capability of an entity. See PROGRESSION.md.

It is an ordinary lazy module and participates in no pipeline phase.

# RulesModule

`RulesModule` is the reactive rules capability of an entity. See RULES.md under `entities/modules/rules/`.

It owns the rules of the entity, registers them on demand and subscribes them to the module facts they declare. It is an ordinary lazy module and participates in no pipeline phase.

# Entity Resolvers

Resolvers are per-entity collaborators, not modules. They live under `entities/resolvers/`, are created with the entity and are accessed through `entity.resolvers`. See RESOLVERS.md.

# Folder Location

Module infrastructure lives under `entities/modules/`. Concrete module implementations live under `entities/modules/<module>/`.