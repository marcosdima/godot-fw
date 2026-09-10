extends UIElement
class_name UIContainer


## How children are laid out. ROW and COLUMN arrange children along an axis
## with a separation; FREE places children at their authored positions and is
## the only orientation in which position and size are used directly.
enum Orientation {
	ROW,
	COLUMN,
	FREE,
}


## How children are arranged. Values come from Orientation; the field is an
## int because GDScript enums are not types.
var orientation := Orientation.COLUMN:
	set(value):
		if orientation == value:
			return
		orientation = value
		changed.emit(&"orientation")

## Gap in pixels between children along the arranged axis.
var separation := 0:
	set(value):
		if separation == value:
			return
		separation = value
		changed.emit(&"separation")

## Spacing applied around the arranged children inside this container.
var margin := Margin.new():
	set(value):
		if margin == value:
			return
		margin = value
		changed.emit(&"margin")

## When true the container fills the full area it is given, instead of
## shrinking to its children. Intended for the root of a screen.
var full_view := false:
	set(value):
		if full_view == value:
			return
		full_view = value
		changed.emit(&"full_view")