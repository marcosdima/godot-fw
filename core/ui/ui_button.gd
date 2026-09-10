extends UIElement
class_name UIButton


## Text displayed on this button.
var text := "":
	set(value):
		if text == value:
			return
		text = value
		changed.emit(&"text")

## Action executed when the button is pressed. The action receives no
## arguments; captures the context it needs.
var action: Callable


## Executes the button action when it is valid. Doing nothing when the action
## is empty keeps stateless buttons harmless.
func press() -> void:
	if action.is_valid():
		action.call()