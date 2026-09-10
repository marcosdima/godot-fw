extends UIElement
class_name UIInput


## Text committed by the field. While the field is being edited, this holds the
## value from the last commit; the draft being typed lives in the editing
## surface until it commits or is cancelled.
var text := "":
	set(value):
		if text == value:
			return
		text = value
		changed.emit(&"text")

## Hint shown while the field has no text.
var placeholder := "":
	set(value):
		if placeholder == value:
			return
		placeholder = value
		changed.emit(&"placeholder")