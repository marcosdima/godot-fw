extends RefCounted
class_name Modules


## The entity these modules belong to.
var _entity: Entity

## Every currently instantiated module. No semantic ordering.
var _active: Array[Module] = []

## Backing field of the lazy state module.
var _state: StateModule

## Backing field of the lazy interaction module.
var _interaction: InteractionModule

## Backing field of the lazy status module.
var _status: StatusModule

## Backing field of the lazy progression module.
var _progression: ProgressionModule


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


## Returns the interaction module, creating and activating it on first access.
var interaction: InteractionModule:
	get:
		if _interaction == null:
			_interaction = InteractionModule.new(_entity)
			_activate(_interaction)
		return _interaction


## Returns the status module, creating and activating it on first access.
var status: StatusModule:
	get:
		if _status == null:
			_status = StatusModule.new(_entity)
			_activate(_status)
		return _status


## Returns the progression module, creating and activating it on first access.
var progression: ProgressionModule:
	get:
		if _progression == null:
			_progression = ProgressionModule.new(_entity)
			_activate(_progression)
		return _progression


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