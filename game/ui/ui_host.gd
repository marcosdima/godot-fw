extends Control
class_name UIHost


## Screens of the game keyed by their root element.
var _screens: Dictionary = {}

## The stack that owns the screen transitions.
var _stack: ScreenStack = null

## The adapter that materializes the current screen.
var _adapter: UIControlAdapter = null

## The screen bundle currently shown.
var _current: UIScreen = null

## The Control that materializes the current screen root.
var _root_control: Control = null

## Set when the current screen was rebuilt and still needs its final arrange.
var _pending_arrange := false

## The settings screen pushed by the main menu.
var _settings_ui: UIScreen = null

## The settings state edited by the settings screen.
var _agent_settings: AgentSettings = null

## The create profile screen pushed by the main menu, built on demand.
var _create_profile_ui: UIScreen = null

## The input currently being edited natively, or null.
var _editing: UIElement = null

## The HUD element tree owned by the game, materialized above every screen.
var _hud: UIElement = null

## The adapter materializing the HUD layer, or null.
var _hud_adapter: UIControlAdapter = null

## The Control that materializes the HUD root, or null.
var _hud_control: Control = null


## Initializes the host from a scene: builds the standard screens on top of a
## fresh stack. Programmatic hosts call setup() instead.
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _stack == null:
		_initialize_default_screens()
	_attach_hud_control()


## Binds the screen stack to this host and materializes its current screen.
func setup(stack: ScreenStack) -> void:
	_stack = stack
	_adapter = UIControlAdapter.new()
	_adapter.submitted.connect(_on_input_submitted)
	_stack.changed.connect(_on_screen_changed)
	_on_screen_changed(_stack.current)


## Attaches the given element tree as a persistent HUD overlay shown above every
## screen. The tree is owned by the caller; the host only materializes it and
## keeps it current. Passing null (or the current tree again) is a no-op.
func set_hud(hud: UIElement) -> void:
	if _hud == hud:
		return
	_detach_hud()
	_hud = hud
	if _hud == null:
		return
	if _hud_adapter == null:
		_hud_adapter = UIControlAdapter.new()
	_hud_control = _hud_adapter.build(_hud)
	_hud_control.name = "hud"
	if is_inside_tree():
		_attach_hud_control()


## Returns the adapter materializing the HUD overlay, or null.
func get_hud_adapter() -> UIControlAdapter:
	return _hud_adapter


## Releases the current HUD materialization, if any. The control is removed
## from the tree immediately so an incoming replacement can reuse its name.
func _detach_hud() -> void:
	if _hud_adapter != null and _hud_control != null:
		if _hud_control.get_parent() != null:
			_hud_control.get_parent().remove_child(_hud_control)
		_hud_adapter.release()
		_hud_control = null


## Adds the materialized HUD control to this host and lays it out. Re-adding is
## a no-op, which lets programmatic hosts attach the HUD before entering tree.
## While a child is still entering the tree the host refuses add_child calls
## ("busy setting up children"), so the add is re-checked on the next frame.
func _attach_hud_control() -> void:
	if _hud_adapter == null or _hud_control == null:
		return
	if _hud_control.get_parent() != self:
		_finish_attach_hud.call_deferred(_hud_control)
	if _hud is UIContainer:
		_hud_adapter.arrange(_hud as UIContainer)


## Runs the delayed HUD add after the host finished setting up its children.
## Idempotent: later calls find the control already parented and bail out.
func _finish_attach_hud(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.get_parent() != self:
		add_child(target)


## Registers a screen bundle so it can be pushed by the stack.
func register(screen: UIScreen) -> void:
	_screens[screen.root] = screen


## Pushes the given screen bundle onto the bound stack.
func push(screen: UIScreen) -> void:
	register(screen)
	_stack.push(screen.root)


## Returns the currently shown screen bundle, or null.
func get_current_screen() -> UIScreen:
	return _current


## Returns the adapter materializing the current view, or null.
func get_adapter() -> UIControlAdapter:
	return _adapter


## Advances the playbacks of the current screen and applies the final arrange
## once the control has been sized by the engine.
func _process(delta: float) -> void:
	if _adapter != null:
		_adapter.tick(delta)
	if _hud_adapter != null:
		_hud_adapter.tick(delta)
	if _pending_arrange:
		if _root_control != null and _root_control.size != Vector2.ZERO:
			var root: UIContainer = _current.root
			if root is UIContainer:
				_adapter.arrange(root)
			_pending_arrange = false


## Re-arranges the current screen and the HUD whenever the engine resizes their
## shared root control.
func _on_root_resized() -> void:
	if _adapter != null and _current != null and _current.root is UIContainer:
		_adapter.arrange(_current.root)
	if _hud_adapter != null and _hud is UIContainer:
		_hud_adapter.arrange(_hud as UIContainer)


## Maps mouse position to the model: hovering a button moves the selection
## group onto it; a left click activates the hovered button through the model.
func _gui_input(event: InputEvent) -> void:
	if _current == null or _current.group == null:
		return
	var mouse_position := get_global_mouse_position()
	if event is InputEventMouse:
		mouse_position = (event as InputEventMouse).global_position
	var hovered: UIElement = _adapter.element_at(mouse_position)
	if event is InputEventMouseMotion:
		if hovered is UIButton and _current.group.get_focused() != hovered:
			_current.group.focus(hovered)
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if hovered is UIButton:
			(hovered as UIButton).press()
		elif hovered is UIInput and _current.group.get_focused() != hovered:
			_current.group.focus(hovered)


## Maps navigation and submit input to the current screen's selection group.
func _unhandled_input(event: InputEvent) -> void:
	if _current == null or _current.group == null or _stack == null:
		return
	var group := _current.group
	if event.is_action_pressed("ui_down"):
		group.next()
	elif event.is_action_pressed("ui_up"):
		group.previous()
	elif event.is_action_pressed("ui_accept"):
		var focused: UIElement = group.get_focused()
		if focused is UIInput:
			if _editing != focused:
				_adapter.activate_input(focused)
				_editing = focused
			return
		var button: UIButton = focused as UIButton
		if button != null:
			button.press()
	elif event.is_action_pressed("ui_cancel"):
		if _editing != null and _editing is UIInput:
			_adapter.cancel_input(_editing)
			_editing = null
			return
		if not _stack.is_empty():
			_stack.pop()


## The group whose focus is wired to the view, or null until a screen is shown.
var _current_group: SelectionGroup = null


## Rebuilds the view when the stack changes: releases the previous screen's
## controls and materializes the new one.
func _on_screen_changed(_screen: UIElement) -> void:
	_current = _screens.get(_screen) if _screen != null else null
	if _current == null:
		_adapter.release()
		return
	_editing = null
	if _current_group != null and _current_group.is_connected(&"focused_changed", _on_focused_changed):
		_current_group.disconnect(&"focused_changed", _on_focused_changed)
	if _root_control != null and _root_control.is_connected(&"resized", _on_root_resized):
		_root_control.resized.disconnect(_on_root_resized)
	_root_control = _adapter.build(_current.root)
	for child in get_children():
		if child == _root_control or (_hud_control != null and child == _hud_control):
			continue
		if child is Control:
			remove_child(child)
	add_child(_root_control)
	if _hud_control != null and _hud_control.get_parent() != self:
		add_child(_hud_control)
	_root_control.resized.connect(_on_root_resized)
	_pending_arrange = true
	for playback in _current.playbacks:
		_adapter.add_playback(playback)
	_current_group = _current.group
	if _current_group != null:
		if _current_group.get_focused() == null:
			_current_group.focus_first()
		_current_group.focused_changed.connect(_on_focused_changed)
		_on_focused_changed(null, _current_group.get_focused())


## Synchronizes native editing and the view highlight with the group focus:
## leaving an input commits or cancels it, entering one starts native editing.
func _on_focused_changed(_previous: UIElement, current: UIElement) -> void:
	if _editing != null:
		_adapter.deactivate_input(_editing)
		_editing = null
	if current is UIInput:
		_adapter.activate_input(current)
		_editing = current
	_adapter.highlight(current)


## Advances the selection group after a field submits through Enter, unless the
## focus already moved off the submitting field.
func _on_input_submitted(element: UIElement, _text: String) -> void:
	if _current == null or _current.group == null:
		return
	if _current.group.get_focused() != element:
		return
	_current.group.next()


## Creates the standard main and settings screens and shows the main menu.
func _initialize_default_screens() -> void:
	var stack := ScreenStack.new()
	var main_ui := UIMainMenu.build(
		func() -> void: _open_settings(),
		func() -> void: get_tree().quit(),
		func() -> void: _open_create_profile()
	)
	_agent_settings = AgentSettings.new()
	_settings_ui = UISettingsMenu.build(_agent_settings, func() -> void: stack.pop())
	setup(stack)
	register(main_ui)
	register(_settings_ui)
	stack.push(main_ui.root)


## Pushes the create profile screen, building it the first time it is requested.
func _open_create_profile() -> void:
	if _create_profile_ui == null:
		_create_profile_ui = UICreateProfile.build(
			func(_profile_name: String) -> void: _stack.pop(),
			func() -> void: _stack.pop()
		)
		register(_create_profile_ui)
	if _stack.current != _create_profile_ui.root:
		_stack.push(_create_profile_ui.root)


## Pushes the settings screen, building it the first time it is requested.
func _open_settings() -> void:
	if _settings_ui == null:
		_agent_settings = AgentSettings.new()
		_settings_ui = UISettingsMenu.build(_agent_settings, func() -> void: _stack.pop())
		register(_settings_ui)
	if _stack.current != _settings_ui.root:
		_stack.push(_settings_ui.root)