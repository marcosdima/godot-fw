extends RefCounted
class_name Area


## Emitted when an occupant successfully enters this area.
signal occupant_entered(occupant: Object)

## Emitted when an occupant successfully exits this area.
signal occupant_exited(occupant: Object)

## Optional callable filter evaluated at admission time.
## Receives the candidate occupant and returns whether it may enter.
## Occupants already inside are never revalidated against it.
var admission_filter: Callable = Callable()

## Occupants currently inside this area, in insertion order.
var _occupants: Array[Object] = []


## Returns true if the given occupant may enter this area.
## Occupants already inside cannot enter again. When an admission filter is set,
## it decides the outcome; otherwise any occupant may enter.
func can_enter(occupant: Object) -> bool:
	if _occupants.has(occupant):
		return false
	if admission_filter.is_valid():
		return admission_filter.call(occupant)
	return true


## Adds an occupant to this area and emits occupant_entered.
## Returns false and rejects the occupant when it is already inside
## or when the admission filter denies it.
func enter(occupant: Object) -> bool:
	if not can_enter(occupant):
		push_error("Occupant %d cannot enter this area" % occupant.get_instance_id())
		return false
	_occupants.append(occupant)
	occupant_entered.emit(occupant)
	return true


## Removes an occupant from this area and emits occupant_exited.
## Ignored with an error when the occupant is not inside this area.
func exit(occupant: Object) -> void:
	if not _occupants.has(occupant):
		push_error("Occupant %d is not inside this area" % occupant.get_instance_id())
		return
	_occupants.erase(occupant)
	occupant_exited.emit(occupant)


## Returns true if the given occupant is currently inside this area.
func has_occupant(occupant: Object) -> bool:
	return _occupants.has(occupant)


## Returns the occupants currently inside this area, in insertion order.
## The occupant instances are the same references.
func get_occupants() -> Array[Object]:
	return _occupants.duplicate()