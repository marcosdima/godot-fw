# Interaction

`InteractionModule` is the interaction capability of an entity, implemented as a Module. See MODULES.md for the module model.

It maintains the interactions currently available to the entity and which one is focused.

# Flow

An available interaction is never executed automatically.

```
available → focused → execute
```

For example, the game detects that a table offers an interaction, adds it to the player's `InteractionModule`, and lets the player select among several. When the game receives the corresponding input, it asks the module to execute the focused interaction.

# Responsibility Split

Core only keeps state: the available set and the focused interaction.

Everything else belongs to the game:

* detecting when an interaction becomes available;
* presenting the available set to the player;
* handling input;
* deciding whether an entity can actually perform an interaction (cooldowns, requirements, etc.).

Core does not know about proximity, direction, vision, areas, 2D, 3D, or any other detection mechanism. There is no `InteractionArea` concept in core.

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

# Focus Semantics

* Only one interaction can be focused at a time.
* Focus is stored as an instance reference, not as an index.
* Adding an interaction when none is focused focuses it automatically. Adding to a non-empty focused set never changes the focus.
* Removing the focused interaction unfocuses it (`on_unfocused` fires) and leaves nothing focused. Removing a non-focused interaction preserves the current focus.
* `next()` and `previous()` cycle through the available set with wrap-around. With zero interactions they do nothing. From no focus they select the first available.
* `focus(interaction)` directly focuses an available interaction, for selection UIs beyond cycling.
* Membership checks are by instance.
* Adding a duplicate instance emits an error and is ignored.
* `execute_focused()` runs the focused interaction's action, or does nothing without focus.

# Shared Instances

The same `Interaction` instance may be added to several entities' modules safely: focus lives in each module, not in the interaction.

Callables holding references to freed objects are not validated by core. The game is responsible for removing interactions whose providers are destroyed.

# Collection

Available interactions are kept in a plain array preserving insertion order, which defines navigation order.

`Interaction` intentionally does not extend `Element`, and the module intentionally does not use `Handler`: there is no identifier lookup use case, and stable insertion order matters more than keyed access.

# Folder Location

The interaction module lives under `entities/modules/interaction/`.