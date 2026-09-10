extends RefCounted
class_name Margin


## Convenience margins applied to a container. Margins are optional: an unset
## side falls back to its axis, then to a total value, then to 0.0.
## Unset values are stored as NAN so that authored values and fallbacks stay
## distinguishable; resolved getters return the effective number.
var left := NAN:
	set(value):
		left = value

## Right margin.
var right := NAN:
	set(value):
		right = value

## Top margin.
var top := NAN:
	set(value):
		top = value

## Bottom margin.
var bottom := NAN:
	set(value):
		bottom = value

## Horizontal fallback for left and right when either side is unset.
var horizontal := NAN:
	set(value):
		horizontal = value

## Vertical fallback for top and bottom when either side is unset.
var vertical := NAN:
	set(value):
		vertical = value

## Total fallback for every side when the side and its axis are both unset.
var total := NAN:
	set(value):
		total = value


## Sets a single total margin applied to every side when sides and axes are unset.
func set_all(value: float) -> void:
	total = value


## Sets the horizontal fallback applied to left and right when either is unset.
func set_horizontal(value: float) -> void:
	horizontal = value


## Sets the vertical fallback applied to top and bottom when either is unset.
func set_vertical(value: float) -> void:
	vertical = value


## Returns the effective left margin: left, else horizontal, else total, else 0.0.
func get_left() -> float:
	return _resolve(left, horizontal, total)


## Returns the effective right margin: right, else horizontal, else total, else 0.0.
func get_right() -> float:
	return _resolve(right, horizontal, total)


## Returns the effective top margin: top, else vertical, else total, else 0.0.
func get_top() -> float:
	return _resolve(top, vertical, total)


## Returns the effective bottom margin: bottom, else vertical, else total, else 0.0.
func get_bottom() -> float:
	return _resolve(bottom, vertical, total)


## Returns the first non-NAN value in the given chain, or 0.0 when all are NAN.
func _resolve(side: float, axis: float, total_value: float) -> float:
	if not is_nan(side):
		return side
	if not is_nan(axis):
		return axis
	if not is_nan(total_value):
		return total_value
	return 0.0