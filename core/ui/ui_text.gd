extends UIElement
class_name UIText


## Text displayed by this element.
var text := "":
	set(value):
		if text == value:
			return
		text = value
		changed.emit(&"text")