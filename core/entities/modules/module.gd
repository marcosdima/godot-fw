extends RefCounted
class_name Module


## Weak reference to the entity this module belongs to, assigned at construction
## and never changed. Held weakly so the Entity -> Modules -> Module -> Entity
## chain does not form a RefCounted cycle that would prevent entities from ever
## being freed.
var _entity: WeakRef

## The entity this module belongs to.
var entity: Entity:
	get:
		if _entity == null:
			return null
		return _entity.get_ref()

## Connections made during attach(), disconnected during detach().
var _phase_connections: Array[PhaseConnection] = []


## Creates a new module bound to the given entity.
func _init(p_entity: Entity) -> void:
	_entity = weakref(p_entity)


## Returns the pipeline phases this module participates in.
## Base modules participate in none; concrete modules override this.
func _get_phase_callbacks() -> Array[PhaseCallback]:
	return []


## Called when the module becomes active or when its entity changes world context.
## Connects every declared phase callback to the corresponding signal of the
## current world's update pipeline and records each connection made.
## Without a world there is nothing to connect to and the module attaches normally.
func attach() -> void:
	var world := entity.get_world()
	if world == null:
		return
	for participation in _get_phase_callbacks():
		var phase_signal := world.update_pipeline.phase_signal(participation.phase)
		phase_signal.connect(participation.callback)
		_phase_connections.append(PhaseConnection.new(phase_signal, participation.callback))


## Called before the entity leaves its current world context.
## Disconnects exactly the connections recorded during attach().
func detach() -> void:
	for connection in _phase_connections:
		connection.pipeline_signal.disconnect(connection.callback)
	_phase_connections.clear()