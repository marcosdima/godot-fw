# UI

The UI domain provides a composable, engine-light interface model in `core/ui/` and a thin Godot adapter in `game/ui/` that materializes the model into `Control` nodes.

The model in `core` is pure data and logic: it has no concept of `Node`, `Control`, trees, rendering clocks or input. The engine, the adapter, the input mapping and the runtime clock live in `game`.

# Model Boundary

The UI model is a tree of `UIElement` instances.

* Owner-to-owned references are strong: a container keeps its children alive.
* `UIElement.parent` is a weak back-reference (`WeakRef`), so children never keep their parent alive. This follows the entity ownership invariant of CORE_CONTRACT.md.
* The model does not depend on Godot. UI classes extend `RefCounted`, never `Node`.
* Signals are effective-only: they are emitted when state actually changes, not on every attempt.

## Signals

* `UIElement.changed(property: StringName)`: emitted when a property changes to a different value. The property name identifies what changed.
* `UIElement.child_added(child)` / `child_removed(child)`: structural changes.
* `SelectionGroup.focused_changed(previous, current)`: focus moved.
* `ScreenStack.changed(current)`: the stack top changed.
* `UIAnimationPlayback.finished` / `stopped`: playback state transitions.

# UIElement

`UIElement` is the base of the interface model. It provides identity (`id`, `name` from `Element`), an ordered child list, a weak parent back-reference and the common visual properties:

* `visible`, `enabled`
* `position`, `size`, `scale` (`Vector2`)
* `z_index` (`int`)
* `modulate` (`float`, 0.0–1.0 opacity)
* `style: StyleData` (placed on the base for now; re-evaluated if it grows)

Every setter emits `changed` only when the value actually differs.

Tree operations: `add`, `remove`, `clear`, `get_children`. `add` guards against self-cycles and ancestor/descendant cycles and re-parents an element by removing it from its previous parent first.

## Kinds

* `UIText`: text content.
* `UIButton`: text content and a `Callable` action executed by `press()`. Losing focus never activates a button: submit is explicitly resolved by the game as `focused.press()`.
* `UIContainer`: ordered layout. `orientation` (`FREE`, `COLUMN`, `ROW`), `separation`, `margin: Margin`, and `full_view` for containers that fill their parent. Containers both model layout intent and own the children; layout is described with the constraint that no measured geometry is ever written back (see Adapter).

# StyleData and Margin

`StyleData` bundles presentation: `color`, `border_color`, `border_width`, `border_radius`, `shadow_color`, `shadow_size`, `font_size`, and text alignment enums `AlignH` / `AlignV`.

`Margin` resolves axis-aware margins: `get_top`, `get_right`, `get_bottom`, `get_left` honor per-side values, fall back to the matching axis value, then to the total value.

# SelectionGroup

`SelectionGroup` keeps an explicit ordered list of focusable elements and a focused element. Operations: `add`, `remove`, `focus_first`, `focus(element)`, `next`, `previous` (wraparound), `get_focused`, `get_items`. Focus changes are effective-only: focusing the already-focused element emits nothing.

# ScreenStack

`ScreenStack` is a simple stack of screen roots. `push`, `pop`, `current`, `clear`, `is_empty`; the `changed` signal fires on every effective transition. The stack is game-owned; `core` does not decide which screens exist.

# Animation

UI animation is data plus pure playback; `core/` never reads a clock.

* `Track`: a `property`, a target `to` value and a `blend` (`OVERRIDE`, `ADD`, `MULTIPLY`). Target is `Vector2` for `position`, `size` and `scale`, `float` for `modulate`.
* `UIAnimationDefinition`: `duration`, `delay`, `easing` (`LINEAR`, `EASE_IN`, `EASE_OUT`, `EASE_IN_OUT`), `loop` (`NONE`, `RESTART`, `PING_PONG`), and an ordered `tracks` list built with `add_track`. Only properties in `ANIMATABLE_PROPERTIES` (`position`, `size`, `scale`, `modulate`) are accepted; anything else errors at build time.
* `UIAnimationPlayback`: instantiated for a single element, advanced by the game clock with `advance(delta)`. `value_for(property, base)` returns the composed value; `set_time` seeks; `stop` and `is_finished` report state. The element reference is weak. Blend math: `OVERRIDE` lerps base toward target, `ADD` adds `target * progress`, `MULTIPLY` scales by `target.lerp(1, progress)`.

# Game Boundary

`game/ui/` contains the only contact with the engine.

* `UIControlAdapter` materializes a `UIElement` tree into a `Control` tree: `UIButton` -> `Button`, `UIText` -> `Label`, `UIContainer` -> `Control`; `UIContainer` -> `Container` is the documented future direction, pending verification that model-driven layout and engine layout can coexist.
* Layout is applied one way, model to view. Measured geometry (e.g. control minimum sizes during `arrange`) is kept locally and never written back to the model.
* `full_view` containers fill their parent: their authored position and size are ignored by the adapter.
* Styles apply as theme overrides (`StyleBoxFlat` built from `StyleData`); focus state is rendered by replacing the `normal` stylebox of the focused `Button`.
* The adapter tracks signal connections it makes and disconnects them on `release()`.
* Playbacks registered through `add_playback` are driven by the clock the game provides, not by any core timer.

`UIHost` is the game-side Control that owns a `ScreenStack`, a materializing adapter and the current `UIScreen`. It maps game input (`ui_up`/`ui_down`/`ui_accept`/`ui_cancel`) onto the screen's selection group and submits as `focused.press()`, ticks playbacks in `_process`, and rebuilds the view when the stack changes.

# Clock

Core UI never reads the engine clock and never owns a timer. Advancing playbacks with `advance(delta)` is the game's responsibility; the game decides what delta to feed. This mirrors the world update contract in `# Runtime and Clock` of ARCHITECTURE.md.

# Input

The model has no input bus, no UI manager and no global event system. Input reaches a button only as a `press()` call decided by the game: navigation through a selection group, submit through the focused button. Do not introduce a bus preemptively.