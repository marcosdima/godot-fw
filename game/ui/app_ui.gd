extends Node
class_name AppUI


## Weak reference to the UIHost this composition drives. Held weakly so the
## screens' action callbacks never keep a freed host alive.
var _host_ref: WeakRef

## The stack the game screens live on, owned by this composition.
var _stack: ScreenStack = null

## The settings state edited by the settings screen, kept across reopens.
var _settings: AgentSettings = null

## The settings screen, built once over its shared state.
var _settings_ui: UIScreen = null

## The create profile screen, built on demand.
var _create_profile_ui: UIScreen = null

## The contracts list screen, built on demand.
var _contracts_ui: UIScreen = null


## Composes the standard game screens on top of the given host and shows the
## main menu. Synchronous; call after the host is inside a tree so building the
## current screen can add its controls. Returns the AppUI that owns the
## composition, which the caller must keep alive.
static func compose(host: UIHost, quit: Callable = Callable()) -> AppUI:
	var app := AppUI.new()
	app._setup(host, quit)
	return app


## Enters the host after the tree finished setting up children, so the compose
## can safely add the screen controls below the host.
func _ready() -> void:
	var host := get_parent() as UIHost
	if host != null:
		_enter.call_deferred(host)


## Builds the screens on the scene-owned host, quitting through the running
## game when the main menu Quit button is pressed.
func _enter(host: UIHost) -> void:
	_setup(host, func() -> void: get_tree().quit())


## Wires the standard screens to the given host: a fresh stack, the settings
## state shared with its screen, and the main menu on top of the stack.
func _setup(host: UIHost, quit: Callable) -> void:
	if not quit.is_valid():
		quit = func() -> void: pass
	_host_ref = weakref(host)
	var stack := ScreenStack.new()
	_stack = stack
	var main_ui := UIMainMenu.build(
		_open_settings,
		quit,
		_open_contracts,
		_open_create_profile,
	)
	_settings = AgentSettings.new()
	_settings_ui = UISettingsMenu.build(_settings, func() -> void: stack.pop())
	host.setup(stack)
	host.register(main_ui)
	host.register(_settings_ui)
	stack.push(main_ui.root)


## Pushes the settings screen, reusing the shared state built at compose time.
func _open_settings() -> void:
	if _settings_ui != null and _stack.current != _settings_ui.root:
		_stack.push(_settings_ui.root)


## Pushes the contracts list screen, building it the first time it is requested.
func _open_contracts() -> void:
	if _contracts_ui == null:
		var host := _host_ref.get_ref() as UIHost
		if host == null:
			return
		_contracts_ui = UIContractsMenu.build(
			UIContractsMenu.CONTRACTS,
			func(_contract: Dictionary) -> void: _stack.pop(),
			func() -> void: _stack.pop(),
		)
		host.register(_contracts_ui)
	if _stack.current != _contracts_ui.root:
		_stack.push(_contracts_ui.root)


## Pushes the create profile screen, building it the first time it is requested.
func _open_create_profile() -> void:
	if _create_profile_ui == null:
		var host := _host_ref.get_ref() as UIHost
		if host == null:
			return
		_create_profile_ui = UICreateProfile.build(
			func(_profile_name: String) -> void: _stack.pop(),
			func() -> void: _stack.pop(),
		)
		host.register(_create_profile_ui)
	if _stack.current != _create_profile_ui.root:
		_stack.push(_create_profile_ui.root)