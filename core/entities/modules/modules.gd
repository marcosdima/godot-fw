extends RefCounted
class_name Modules


## Weak reference to the entity these modules belong to, assigned at construction
## and never changed. Held weakly so the Entity -> Modules -> Entity chain does
## not form a RefCounted cycle that would prevent entities from ever being freed.
var _entity: WeakRef

## The entity these modules belong to.
var entity: Entity:
	get:
		if _entity == null:
			return null
		return _entity.get_ref()

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

## Backing field of the lazy rules module.
var _rules: RulesModule

## Backing field of the lazy equipment module.
var _equipment: EquipmentModule


## Creates the modules facade for the given entity. No module is instantiated here.
func _init(p_entity: Entity) -> void:
	_entity = weakref(p_entity)


## Returns the state module, creating and activating it on first access.
var state: StateModule:
	get:
		if _state == null:
			_state = StateModule.new(entity)
			_activate(_state)
		return _state


## Returns the interaction module, creating and activating it on first access.
var interaction: InteractionModule:
	get:
		if _interaction == null:
			_interaction = InteractionModule.new(entity)
			_activate(_interaction)
		return _interaction


## Returns the status module, creating and activating it on first access.
var status: StatusModule:
	get:
		if _status == null:
			_status = StatusModule.new(entity)
			_activate(_status)
		return _status


## Returns the progression module, creating and activating it on first access.
var progression: ProgressionModule:
	get:
		if _progression == null:
			_progression = ProgressionModule.new(entity)
			_activate(_progression)
		return _progression


## Returns the rules module, creating and activating it on first access.
var rules: RulesModule:
	get:
		if _rules == null:
			_rules = RulesModule.new(entity)
			_activate(_rules)
		return _rules


## Returns the equipment module, creating and activating it on first access.
var equipment: EquipmentModule:
	get:
		if _equipment == null:
			_equipment = EquipmentModule.new(entity)
			_activate(_equipment)
		return _equipment


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