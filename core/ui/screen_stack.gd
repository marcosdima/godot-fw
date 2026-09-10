extends RefCounted
class_name ScreenStack


## Emitted after the current screen actually changes, with the new current
## screen. Emits null when the stack empties.
signal changed(current: UIElement)


## Screens in push order; the last one is the current screen.
var _screens: Array[UIElement] = []


## Pushes the given screen, making it current. Pushing the screen that is
## already current is a no-op.
func push(screen: UIElement) -> void:
	if screen == null:
		push_error("Cannot push a null screen")
		return
	if not _screens.is_empty() and _screens.back() == screen:
		return
	_screens.append(screen)
	changed.emit(screen)


## Pops the current screen, returning to the previous one. Popping from an
## empty stack is a no-op; popping the last screen empties the stack and
## emits changed with null.
func pop() -> void:
	if _screens.is_empty():
		return
	_screens.pop_back()
	changed.emit(current)


## Returns the current (top) screen, or null when the stack is empty.
var current: UIElement:
	get:
		if _screens.is_empty():
			return null
		return _screens.back()


## Returns true when the stack is empty.
func is_empty() -> bool:
	return _screens.is_empty()


## Removes every screen from the stack. Does nothing when the stack is empty.
func clear() -> void:
	if _screens.is_empty():
		return
	_screens.clear()
	changed.emit(null)