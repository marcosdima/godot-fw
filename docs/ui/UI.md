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
* `UIInput`: committed `text` and a `placeholder`. The committed value is the model truth; the in-progress draft lives in the editing surface until it commits or is cancelled.
* `UIContainer`: ordered layout. `orientation` (`FREE`, `COLUMN`, `ROW`), `separation`, `margin: Margin`, and `full_view` for containers that fill their parent. Containers both model layout intent and own the children; layout is described with the constraint that no measured geometry is ever written back (see Adapter).

# StyleData and Margin

`StyleData` bundles presentation: `color`, `font_color` (foreground; transparent falls back to `color` so a single-tint surface keeps working), `border_color`, `border_width`, `border_radius`, `shadow_color`, `shadow_size`, `font_size`, and text alignment enums `AlignH` / `AlignV`.

`Margin` resolves axis-aware margins: `get_top`, `get_right`, `get_bottom`, `get_left` honor per-side values, fall back to the matching axis value, then to the total value.

# SelectionGroup

`SelectionGroup` keeps an explicit ordered list of focusable elements and a focused element. Operations: `add`, `remove`, `focus_first`, `focus(element)`, `next`, `previous` (wraparound), `get_focused`, `get_items`. Focus changes are effective-only: focusing the already-focused element emits nothing.

# ScreenStack

`ScreenStack` is a simple stack of screen roots. `push`, `pop`, `current`, `clear`, `is_empty`; the `changed` signal fires on every effective transition. The stack is game-owned; `core` does not decide which screens exist.

# Animation

UI animation is data plus pure playback; `core/` never reads a clock.

* `Track`: a `property`, a target `to` value and a `blend` (`OVERRIDE`, `ADD`, `MULTIPLY`). Target is `Vector2` for `position`, `size` and `scale`, `float` for `modulate`.
* `UIAnimationDefinition`: `duration`, `delay`, `easing` (`LINEAR`, `EASE_IN`, `EASE_OUT`, `EASE_IN_OUT`), `loop` (`NONE`, `RESTART`, `PING_PONG`), optional `swing` (out-and-back: progress travels to `1.0` at the midpoint of each iteration and returns to `0.0` at its end, so the value always finishes exactly at its base), and an ordered `tracks` list built with `add_track`. Only properties in `ANIMATABLE_PROPERTIES` (`position`, `size`, `scale`, `modulate`) are accepted; anything else errors at build time.
* `UIAnimationPlayback`: instantiated for a single element, advanced by the game clock with `advance(delta)`. `value_for(property, base)` returns the composed value; `set_time` seeks; `stop` and `is_finished` report state. The element reference is weak. Blend math: `OVERRIDE` lerps base toward target, `ADD` adds `target * progress`, `MULTIPLY` scales by `target.lerp(1, progress)`.

# Game Boundary

`game/ui/` contains the only contact with the engine.

* `UIControlAdapter` materializes a `UIElement` tree into a `Control` tree: `UIButton` -> `Button`, `UIText` -> `Label`, `UIInput` -> `LineEdit`, `UIContainer` -> `Control`; `UIContainer` -> `Container` is the documented future direction, pending verification that model-driven layout and engine layout can coexist.
* Fields materialize display-only (`editable = false`, `FOCUS_NONE`, `IGNORE`), matching the input-agnostic views of buttons. Native editing is turned on per field by `activate_input` and off by `deactivate_input` / `cancel_input`; the draft is committed to the `UIInput` model on submit and on focus loss, and restored on cancel. A cancel guard absorbs the `focus_exited` the native release triggers so a cancelled draft is never re-committed. Native submit also emits a `submitted(element, text)` signal so the game can act on it.
* Layout is applied one way, model to view. Measured geometry (e.g. control minimum sizes during `arrange`) is kept locally and never written back to the model.
* `full_view` containers fill their parent: their authored position and size are ignored by the adapter.
* Styles apply as theme overrides (`StyleBoxFlat` built from `StyleData`); focus state is rendered by replacing the `normal` stylebox of the focused `Button`.
* The adapter tracks signal connections it makes and disconnects them on `release()`.
* Playbacks registered through `add_playback` are driven by the clock the game provides, not by any core timer.

`UIHost` is the game-side Control that binds a `ScreenStack` (handed in through `setup`), a materializing adapter and the current `UIScreen`. It maps game input (`ui_up`/`ui_down`/`ui_accept`/`ui_cancel`) onto the screen's selection group and submits as `focused.press()`, ticks playbacks in `_process`, and rebuilds the view when the stack changes. For text fields the host keeps the editing lifecycle: group focus on a field starts native editing (`activate_input`), leaving it commits, `ui_accept` while editing is the field's own Enter-commit and advances the group, `ui_cancel` while editing cancels the draft (`cancel_input`) so the next `ui_cancel` pops the screen, and clicking a field that is focused but no longer editing restarts editing. The host stays a generic host: it does not decide which screens exist.

The game composes its screens on top of the host in `app_ui.gd` (`AppUI`, an engine-light `Node` in `main_menu.tscn`). It owns the `ScreenStack`, the `AgentSettings` state shared with the settings screen, and the settings and create-profile screens, and wires the main menu buttons (`AppUI.compose` is the synchronous path used by tests; the scene enters the host with a deferred compose because the host is still setting up its children when the scene runs).

The host also supports one persistent overlay: a game-owned HUD element tree materialized above every screen. `set_hud` (re)builds the overlay from any tree the game hands over; the host only materializes and keeps it current, never owns it. The host re-arranges the overlay on resize, ticks its playbacks in `_process`, and preserves it across screen swaps — the screen housekeeping only removes `Control` children, so a game controller sharing the host's tree (e.g. a `HudDemo` node driving the HUD with core `Entity` state) survives transitions. Overlay controls are authored with `MOUSE_FILTER_IGNORE` so pointer input falls through to the active screen.

# Reference Screens

`game/ui/menus/` contains the reference screens built purely from the model kinds above:

* `main_menu.gd` — a column of buttons (`COLUMN` layout) with a fade-in title playback.
* `settings_menu.gd` — a second, stateful use case: `Fullscreen` and `Resolution` are cycle buttons, `Volume` is a stepper row (`[ − ][ value ][ + ]`) that is the reference `ROW` layout. The edited values live in `game/ui/agent_settings.gd`, an engine-light settings object owned by the game; the UI renders and mutates it but never owns the state.
* `create_profile.gd` — the text-input slice: a `label + UIInput` row (authored sizes) feeding a Create action, an empty-name error line, and a Back button. Selecting the field starts editing, Enter commits and advances to Create, Escape cancels the draft before popping.

Deliberately missing today: drag and left/right adjustment for range values. A real slider is out of scope; when it is required, the intended extension point is a stateless adjust verb on the model plus `ui_left`/`ui_right` routing in the host — not a state-carrying value widget.

# HUD Slice

`game/ui/hud/` is the reference for a persistent HUD built on the existing model → adapter path:

* `hud.gd` (`UIHud`) builds the HUD's element tree: a full-view `FREE` root above every screen (`z_index = 100`) that never traps input, a top-left vitality bar (a tray with a fill the game resizes as a fraction of the bar), a numeric vitality readout, a souls counter and an alert line. Text and fill targets are authored positions and sizes; the bar fill width is the only value the game mutates.
* `hud_demo.gd` (`HudDemo`) is a scene `Node` that drives the tree from a real core `Entity` (`StatusModule` + `Attribute`, here named "Vitality", clamped `0..20`). It is attached to the `UIHost` in `main_menu.tscn`; its `_ready` wires `set_hud` and `sync()` copies entity state into the element tree through effective-only setters. The model stays the source of truth: the demo never writes into the adapter's `Control` tree.
* Damage flash: a one-shot `modulate` playback over the fill (`0.15s`, `EASE_OUT`, swing). The swing makes the track travel base → target → base within the duration, so the fill is opaque again on its own when the playback ends — no view-side restore is needed.
* The demo auto-steps with `beat_seconds` (default `1.0`) when the scene runs live; tests disable processing and drive `step()` manually.

The overlay is game-owned presentation: `core/` knows nothing about it, and the HUD adds no observers, no data binding, and no layout invalidation — the demo pushes state through the same setters and `changed` signals the screens use.

# Clock

Core UI never reads the engine clock and never owns a timer. Advancing playbacks with `advance(delta)` is the game's responsibility; the game decides what delta to feed. This mirrors the world update contract in `# Runtime and Clock` of ARCHITECTURE.md.

# Input

The model has no input bus, no UI manager and no global event system. Input reaches a button only as a `press()` call decided by the game: navigation through a selection group, submit through the focused button. Text input reuses the engine's native editing (caret, selection, clipboard, IME) inside the adapter: the model only ever holds the committed value. Do not introduce a bus preemptively.