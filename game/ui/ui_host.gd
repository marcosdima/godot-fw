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


## Initializes the host from a scene: builds the standard screens on top of a
## fresh stack. Programmatic hosts call setup() instead.
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _stack == null:
		_initialize_default_screens()


## Binds the screen stack to this host and materializes its current screen.
func setup(stack: ScreenStack) -> void:
	_stack = stack
	_adapter = UIControlAdapter.new()
	_stack.changed.connect(_on_screen_changed)
	_on_screen_changed(_stack.current)


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
	if _pending_arrange:
		if _root_control != null and _root_control.size != Vector2.ZERO:
			var root: UIContainer = _current.root
			if root is UIContainer:
				_adapter.arrange(root)
			_pending_arrange = false


## Re-arranges the current screen whenever the engine resizes its root control.
func _on_root_resized() -> void:
	if _adapter != null and _current != null and _current.root is UIContainer:
		_adapter.arrange(_current.root)


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
		var focused: UIButton = group.get_focused() as UIButton
		if focused != null:
			focused.press()
	elif event.is_action_pressed("ui_cancel"):
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
	if _current_group != null and _current_group.is_connected(&"focused_changed", _on_focused_changed):
		_current_group.disconnect(&"focused_changed", _on_focused_changed)
	if _root_control != null and _root_control.is_connected(&"resized", _on_root_resized):
		_root_control.resized.disconnect(_on_root_resized)
	_root_control = _adapter.build(_current.root)
	for child in get_children():
		if child != _root_control:
			remove_child(child)
	add_child(_root_control)
	_root_control.resized.connect(_on_root_resized)
	_pending_arrange = true
	for playback in _current.playbacks:
		_adapter.add_playback(playback)
	_current_group = _current.group
	if _current_group != null:
		if _current_group.get_focused() == null:
			_current_group.focus_first()
		_adapter.highlight(_current_group.get_focused())
		_current_group.focused_changed.connect(_on_focused_changed)


## Marks the newly focused element as selected in the view.
func _on_focused_changed(_previous: UIElement, current: UIElement) -> void:
	_adapter.highlight(current)


## Creates the standard main and settings screens and shows the main menu.
func _initialize_default_screens() -> void:
	var stack := ScreenStack.new()
	var main_ui := UIMainMenu.build(
		func() -> void: _open_settings(),
		func() -> void: get_tree().quit()
	)
	_agent_settings = AgentSettings.new()
	_settings_ui = UISettingsMenu.build(_agent_settings, func() -> void: stack.pop())
	setup(stack)
	register(main_ui)
	register(_settings_ui)
	stack.push(main_ui.root)


## Pushes the settings screen, building it the first time it is requested.
func _open_settings() -> void:
	if _settings_ui == null:
		_agent_settings = AgentSettings.new()
		_settings_ui = UISettingsMenu.build(_agent_settings, func() -> void: _stack.pop())
		register(_settings_ui)
	if _stack.current != _settings_ui.root:
		_stack.push(_settings_ui.root)