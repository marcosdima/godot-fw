# Modules

`Modules` is the facade through which an `Entity` owns and accesses its capabilities.

Modules are optional capabilities of an entity. There are no default modules: `Modules.new(entity)` does not instantiate anything. Every module is created lazily on first access.

# Ownership

* A `Module` belongs to exactly one `Entity`.
* A module cannot be transferred between entities.
* A module keeps a permanent reference to its entity.
* The entity owns its `Modules` object and delegates module lifecycle concerns to it.
* The entity does not directly manage concrete modules; it communicates through `Modules`.

Conceptually:

```
Entity
└── Modules
    ├── state
    ├── movement
    ├── ...
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
├── attach()
└── detach()
```

`entity` is assigned when the module is constructed and cannot change.

`attach()` and `detach()` are no-op methods in the base class and may be overridden by concrete modules.

Typical responsibilities of concrete modules:

* connecting/disconnecting from `UpdatePipeline` phase signals;
* registering/unregistering external callbacks;
* establishing/removing other external relationships.

Module creation produces a usable active module. Do not introduce a separate setup or initialization step; `Module.new(entity)` creates the module and `Modules` immediately registers it as active and calls `attach()`.

A concrete module may use Godot-specific APIs when its behavior explicitly requires them (for example, connecting to pipeline signals). The base abstraction remains engine-independent.

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

Avoid accessing sibling modules during module construction; lazy resolution during that window can recurse.

# StateModule

`StateModule` is the state capability of an entity. See STATE_SYSTEM.md for its internal responsibilities.

It is an ordinary lazy module: created on first access like any other module.

Its update cycle is currently driven externally through `tick()`. When concrete `UpdatePipeline` phases are defined, the module will connect to the phases it needs through `attach()`.

# InteractionModule

`InteractionModule` is the interaction capability of an entity. See INTERACTION.md for the complete model.

It maintains the available interactions and the currently focused one. It is an ordinary lazy module and does not connect to world context.

# Folder Location

Module infrastructure lives under `entities/modules/`. Concrete module implementations live under `entities/modules/<module>/`.