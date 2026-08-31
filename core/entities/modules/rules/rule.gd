extends RefCounted
class_name Rule


## Weak reference to the entity this rule reacts within, assigned at construction
## and never changed. Held weakly so the Entity -> RulesModule -> Rule -> Entity
## chain does not form a RefCounted cycle that would prevent entities from ever
## being freed. See Entity back-references in ARCHITECTURE.md.
var _entity: WeakRef

## Signal subscriptions made by this rule, used to disconnect them on unsubscribe.
var _subscriptions: Array[Dictionary] = []


## Creates a rule bound to the given entity. The entity never changes.
func _init(p_entity: Entity) -> void:
	_entity = weakref(p_entity)


## Returns the entity this rule reacts within, or null if it is no longer alive.
func get_entity() -> Entity:
	if _entity == null:
		return null
	return _entity.get_ref()


## Game override: subscribes this rule to the module facts it reacts to, using
## _add_subscription() so unsubscribe() can undo them.
func subscribe() -> void:
	pass


## Disconnects every subscription this rule made.
## Game overrides must call super() so the tracked connections are removed.
func unsubscribe() -> void:
	for subscription in _subscriptions:
		if subscription.signal.is_connected(subscription.callable):
			subscription.signal.disconnect(subscription.callable)
	_subscriptions.clear()


## Connects this rule to a module fact and tracks the connection for unsubscribe.
func _add_subscription(trigger: Signal, callable: Callable) -> void:
	trigger.connect(callable)
	_subscriptions.append({"signal": trigger, "callable": callable})