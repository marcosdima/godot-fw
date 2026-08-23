extends RefCounted
class_name Modules


## The entity these modules belong to.
var _entity: Entity

## Every currently instantiated module. No semantic ordering.
var _active: Array[Module] = []

## Backing field of the lazy state module.
var _state: StateModule


## Creates the modules facade for the given entity. No module is instantiated here.
func _init(p_entity: Entity) -> void:
	_entity = p_entity


## Returns the state module, creating and activating it on first access.
var state: StateModule:
	get:
		if _state == null:
			_state = StateModule.new(_entity)
			_activate(_state)
		return _state


## Detaches every active module. Used when the entity leaves its current world context.
func detach_all() -> void:
	for module in _active:
		module.detach()


## Attaches every active module. Used when the entity gains a world context.
func attach_all() -> void:
	for module in _active:
		module.attach()


## Registers a module as active and attaches it.
func _activate(module: Module) -> void:
	_active.append(module)
	module.attach()