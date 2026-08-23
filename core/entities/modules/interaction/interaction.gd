extends RefCounted
class_name Interaction


## Action executed when this interaction is performed.
## Its context is bound by whoever creates the interaction.
var action: Callable

## Called when this interaction becomes the focused one. Optional.
var on_focused: Callable

## Called when this interaction stops being the focused one. Optional.
var on_unfocused: Callable


## Creates a new interaction with the given action and optional lifecycle callbacks.
func _init(p_action: Callable, p_on_focused: Callable = Callable(), p_on_unfocused: Callable = Callable()) -> void:
	action = p_action
	on_focused = p_on_focused
	on_unfocused = p_on_unfocused