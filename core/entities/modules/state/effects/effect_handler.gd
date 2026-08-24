extends Handler
class_name EffectHandler


## Tick counter per active application.
var _tick_counters: Dictionary = {}

## Instant applications awaiting their single processing pass.
var _pending_instant: Array[EffectApplication] = []


## Advances the effect processing by one StateModule tick.
func process(status: Status) -> void:
	_process_pending_instant(status)
	_process_applications(status)


## Resolves the target of the given effect through the status and applies its value to the corresponding attribute.
func apply_effect(effect: Effect, status: Status) -> void:
	var attribute := status.get_attribute(effect.target)
	if attribute != null:
		attribute.current_value += effect.value


## Submits an instant application to be processed once on the next tick, then discarded.
func submit_instant(application: EffectApplication) -> void:
	_pending_instant.append(application)


## Removes the given applications and their processing state from this handler.
func remove_applications(applications: Array[EffectApplication]) -> void:
	for application in applications:
		remove(application)
		_tick_counters.erase(application)


## Processes pending instant applications once and discards them.
func _process_pending_instant(status: Status) -> void:
	for application in _pending_instant:
		var effect: Effect = application.generate_effect()
		if effect != null:
			apply_effect(effect, status)
	_pending_instant.clear()


## Processes active applications, generating and applying effects when their rate is reached.
func _process_applications(status: Status) -> void:
	for application in get_elements():
		var counter: int = _tick_counters.get(application, 0) + 1
		if counter >= application.rate:
			_tick_counters[application] = 0
			var effect: Effect = application.generate_effect()
			if effect != null:
				apply_effect(effect, status)
		else:
			_tick_counters[application] = counter