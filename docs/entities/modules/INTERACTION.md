# Interaction

`InteractionModule` is the interaction capability of an entity, implemented as a Module. See MODULES.md for the module model.

It maintains the interactions currently available to the entity, which one is focused, and the offerings presented by external sources.

# Flow

An available interaction is never executed automatically.

```
available → focused → execute
```

For example, the game detects that a table offers an interaction, presents it to the player's `InteractionModule`, and lets the player select among several. When the game receives the corresponding input, it asks the module to execute the focused interaction.

# Responsibility Split

Core keeps state and reconciles it: the available set, the focused interaction, the offerings presented per source and the observability of their changes.

Everything else belongs to the game:

* detecting when an interaction becomes available;
* presenting and retracting offerings when detection changes;
* presenting the available set to the player;
* handling input;
* deciding whether an entity can actually perform an interaction (cooldowns, requirements, etc.);
* retracting sources before they are destroyed.

Core does not know about proximity, direction, vision, areas, physics, 2D, 3D, input, or any other detection mechanism. There is no `InteractionArea` concept in core.

# Interaction

`Interaction` is a pure data object with no behavior:

```
Interaction
├── action
├── on_focused
└── on_unfocused
```

## Action

The action is executed when the focused interaction is performed.

It receives **no arguments from core**. Its context (the door, the table, the dialogue) is bound by whoever creates the interaction through `Callable.bind()`.

## Lifecycle Callbacks

`on_focused` and `on_unfocused` are optional callbacks fired on focus transitions. Core does not know what they do; the game may use them for HUD, indicators, etc.

Callbacks are invoked only when valid (`Callable.is_valid()`). During a focus switch, the old interaction's `on_unfocused` fires before the new one's `on_focused`.

# Availability

An interaction is available while at least one reason keeps it:

```
availability = manual add OR offered by a source
```

* `add(interaction)` registers a manual reason.
* `present(source, interactions)` registers the offering of a source.
* An interaction leaves the set only when its last reason is removed.

Membership is by instance. A shared instance appears once in the set even when several reasons keep it. Instances are never cloned: offerings store shallow copies of the presented arrays.

# Presentation by Source

A source is any external object that presents interactions to the module. Core does not assume what a source is.

* `present(source, interactions)` states the complete current offering of that source: it adds the new interactions and removes the ones the source stopped offering, unless another reason keeps them.
* Presenting again with a different set replaces the previous offering atomically. This is how a source updates its offering while being presented, for example a door replacing `Open` with `Close`.
* `present(source, [])` is equivalent to `retract(source)`.
* Presenting the exact same offering again is a no-op: no signals and no focus change.
* `retract(source)` removes exactly that source's offering without affecting other sources. Retracting an unknown source is an idempotent no-op.
* Duplicated instances inside one offering are reduced to the first occurrence.

## Source Identity

The source object is used as-is as the dictionary key, so source identity is object identity. No source ids or tokens exist.

This decision was validated on Godot 4.7: `weakref()` returns a new `WeakRef` instance per call and is therefore not a stable dictionary key, while object references hash by identity.

## Lifetime Contract

The game must retract a source before destroying it. If a source disappears without `retract`, its offering stays retained while the module lives for `RefCounted` sources, or its key becomes an invalid reference for freed nodes.

Core does not sweep stale offerings. Only the game knows when a source is destroyed, so reconciling that moment belongs to the game.

# Focus Semantics

* Only one interaction can be focused at a time.
* Focus is stored as an instance reference, not as an index.
* `add` focuses the first available interaction only when the set was empty; adding to a non-empty set never changes the focus.
* Removing the focused interaction through `remove()` unfocuses it (`on_unfocused` fires) and leaves nothing focused. Removing a non-focused interaction preserves the current focus.
* When `present` or `retract` removes the focused interaction, the focus moves to the first available interaction, or to null when the set becomes empty.
* `next()` and `previous()` cycle through the available set with wrap-around. With zero interactions they do nothing. From no focus they select the first available.
* `focus(interaction)` directly focuses an available interaction, for selection UIs beyond cycling.
* Membership checks are by instance.
* Adding a duplicate instance emits an error and is ignored.
* `execute_focused()` runs the focused interaction's action, or does nothing without focus.
* Focus transitions that would re-select the current interaction do not happen: lifecycle callbacks do not refire and `focused_changed` is not emitted.

# Order

The available set keeps insertion order, which defines navigation order.

* A first `present` appends its interactions at the end, in the given order.
* A replacement keeps the position of the interactions that remain, removes the departed ones in place and appends the new ones at the end.
* There are no priorities, ids or external orderings.

# Signals

The module emits signals so consumers can react without polling, following the same pattern as `StateModule`:

* `interaction_added(interaction)`: an interaction became available.
* `interaction_removed(interaction)`: an interaction stopped being available.
* `focused_changed(previous, current)`: an actual focus transition, emitted after the lifecycle callbacks. Either parameter may be null.

Signals represent effective changes: when an operation leaves the state unchanged, such as an identical re-presentation, retracting an unknown source or adding an already available instance, nothing is emitted. Within one operation the emission order is `interaction_removed`, then `interaction_added`, then `focused_changed`.

# Shared Instances

The same `Interaction` instance may be added to several entities' modules safely: focus lives in each module, not in the interaction.

The same instance may also be presented by several sources of the same module: it appears once and stays available until its last reason is removed.

Callables holding references to freed objects are not validated by core. The game is responsible for removing interactions whose providers are destroyed.

# Collection

The available set is a plain array preserving insertion order: the union of the manual reasons and the per-source offerings, deduplicated by instance. Per-source offerings are kept in a dictionary keyed by the source object.

`Interaction` intentionally does not extend `Element`, and the module intentionally does not use `Handler`: there is no identifier lookup use case, and stable insertion order matters more than keyed access.

# Folder Location

The interaction module lives under `entities/modules/interaction/`.