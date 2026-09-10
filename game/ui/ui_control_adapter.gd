extends RefCounted
class_name UIControlAdapter


## Emitted after a text field commits its buffer through native submit (Enter),
## with the element and the committed text. The game decides the effect, which
## is typically advancing the selection group.
signal submitted(element: UIElement, text: String)

## Controls keyed by their element.
var _controls: Dictionary = {}

## Signal connections made while materializing, disconnected on release. Each
## entry is a three-element array [object, signal_name, callable].
var _connections: Array = []

## The root element currently materialized, or null.
var _root_element: UIElement = null

## The root control currently materialized, or null.
var _root_control: Control = null

## The element currently shown as selected, or null.
var _highlighted: UIElement = null

## Playbacks driven by tick().
var _playbacks: Array[UIAnimationPlayback] = []

## The element currently being edited as a native text field, or null.
var _active_input: UIElement = null

## True while a field cancel is in progress. The focus_exited triggered by the
## cancel must restore the committed draft instead of re-committing it.
var _cancel_pending := false


## Builds a Control tree for the given element tree, releasing any previous one.
## Returns the root control, already tree-ready for the caller to add.
func build(element: UIElement) -> Control:
	release()
	_root_element = element
	_root_control = _materialize(element)
	arrange(element)
	return _root_control


## Frees every materialized control, disconnects every signal and resets the
## adapter to an empty state. Safe to call when nothing has been built.
func release() -> void:
	for connection in _connections:
		var signal_object: Object = connection[0]
		var signal_name: StringName = connection[1]
		var callable: Callable = connection[2]
		if signal_object.is_connected(signal_name, callable):
			signal_object.disconnect(signal_name, callable)
	_connections.clear()
	_controls.clear()
	_playbacks.clear()
	_highlighted = null
	_active_input = null
	_cancel_pending = false
	if _root_control != null:
		_root_control.queue_free()
		_root_control = null
	_root_element = null


## Shows the given element as the currently selected one, restoring the visual
## of any previously selected element first.
func highlight(element: UIElement) -> void:
	if _highlighted == element:
		return
	if _highlighted != null:
		_apply_style(_highlighted)
	_highlighted = element
	if element != null:
		var control: Control = _controls.get(element)
		if control is Button:
			(control as Button).add_theme_stylebox_override("normal", _make_stylebox(element.style, true))
		elif control is LineEdit:
			(control as LineEdit).add_theme_stylebox_override("normal", _make_stylebox(element.style, true))
			(control as LineEdit).add_theme_stylebox_override("focus", _make_stylebox(element.style, true))


## Starts native editing of the given field: the control becomes editable,
## focusable and mouse-clickable, and grabs focus when it is inside the tree.
func activate_input(element: UIElement) -> void:
	var control: Control = _controls.get(element)
	if control == null or not control is LineEdit:
		return
	_active_input = element
	var input := control as LineEdit
	input.editable = true
	input.focus_mode = Control.FOCUS_ALL
	input.mouse_filter = Control.MOUSE_FILTER_PASS
	input.caret_blink = true
	if input.is_inside_tree():
		input.grab_focus()


## Stops native editing of the given field, committing its draft to the model.
## Call when the group focus leaves the field.
func deactivate_input(element: UIElement) -> void:
	var control: Control = _controls.get(element)
	if control == null or not control is LineEdit:
		return
	_commit_input(element, control)
	_deactivate_input(element, control)


## Stops native editing of the given field and reverts its draft to the last
## committed text. The cancel guard is armed before the native focus is
## released so the focus_exited it triggers restores instead of committing.
func cancel_input(element: UIElement) -> void:
	var control: Control = _controls.get(element)
	if control == null or not control is LineEdit:
		return
	_cancel_pending = true
	(control as LineEdit).text = (element as UIInput).text
	_deactivate_input(element, control)
	if _cancel_pending:
		_cancel_pending = false


## Commits the field buffer into the model when it differs. Model writes are
## effective-only, so repeated commits leave the value untouched.
func _commit_input(element: UIElement, control: Control) -> void:
	if element is UIInput:
		(element as UIInput).text = (control as LineEdit).text


## Restores the field to its display-only state and releases native focus.
func _deactivate_input(element: UIElement, control: Control) -> void:
	var input := control as LineEdit
	input.editable = false
	input.focus_mode = Control.FOCUS_NONE
	input.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input.caret_blink = false
	if _active_input == element:
		_active_input = null
	if input.is_inside_tree():
		input.release_focus()


## Handles the native submit of a field: commits the buffer and reports the
## submit so the game can move the selection group.
func _on_input_submitted(element: UIElement, text: String) -> void:
	var control: Control = _controls.get(element)
	if control == null:
		return
	_commit_input(element, control)
	submitted.emit(element, text)


## Handles the native focus loss of a field. When a cancel armed the guard, the
## draft was deliberately reverted, so this call restores instead of commits.
func _on_input_focus_exited(element: UIElement) -> void:
	if _cancel_pending:
		_cancel_pending = false
		return
	if _active_input != element:
		return
	var control: Control = _controls.get(element)
	if control == null:
		return
	_commit_input(element, control)


## Registers a playback so tick() drives it against its element's control.
func add_playback(playback: UIAnimationPlayback) -> void:
	_playbacks.append(playback)
	playback.finished.connect(func() -> void: _playbacks.erase(playback))
	playback.stopped.connect(func() -> void: _playbacks.erase(playback))


## Advances every registered playback by the runtime-provided delta and applies
## the resulting values to the materialized controls.
func tick(delta: float) -> void:
	for playback in _playbacks:
		playback.advance(delta)
		var element: UIElement = playback.element
		if element == null:
			continue
		var control: Control = _controls.get(element)
		if control == null:
			continue
		for track in playback._definition.tracks:
			var property: StringName = track.property
			match property:
				&"position":
					control.position = playback.value_for(&"position", element.position)
				&"size":
					control.size = playback.value_for(&"size", element.size)
				&"scale":
					control.scale = playback.value_for(&"scale", element.scale)
				&"modulate":
					var value := playback.value_for(&"modulate", element.modulate) as float
					control.modulate = Color(1.0, 1.0, 1.0, value)


## Returns the control materialized for the given element, or null.
func get_control(element: UIElement) -> Control:
	return _controls.get(element)


## Returns the deepest UIElement whose control contains the given global
## position, or null. This is the mouse hit-test used for hover and click
## mapping; it only reports elements, never the view.
func element_at(global_position: Vector2) -> UIElement:
	var best: UIElement = null
	var best_depth := 0
	for element in _controls:
		var control: Control = _controls[element]
		if control != null and control.visible and control.get_global_rect().has_point(global_position):
			var depth := _depth(element)
			if best == null or depth > best_depth:
				best = element
				best_depth = depth
	return best


## Returns the depth of the element in its tree, root-first.
func _depth(element: UIElement) -> int:
	var depth := 0
	var cursor: UIElement = element
	while cursor.parent != null:
		depth += 1
		cursor = cursor.parent
	return depth


## Returns true when the element is a container that fills its parent, whose
## authored position and size are managed by the layout engine instead.
func _is_full_view(element: UIElement) -> bool:
	return element is UIContainer and (element as UIContainer).full_view


## Creates the control that materializes the given element.
func _materialize(element: UIElement) -> Control:
	var control := _create_control(element)
	_controls[element] = control
	_connect(element)
	_connect_input_control(element, control)
	_apply_all(element, control)
	for child in element.get_children():
		var child_control := _materialize(child)
		control.add_child(child_control)
	return control


## Creates the concrete Control for the element kind. The view is
## input-agnostic: every control is non-interactive so the UI model stays the
## single authority for navigation, hover and activation.
func _create_control(element: UIElement) -> Control:
	if element is UIText:
		return Label.new()
	if element is UIButton:
		var button := Button.new()
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
		return button
	if element is UIInput:
		var input := LineEdit.new()
		input.mouse_filter = Control.MOUSE_FILTER_IGNORE
		input.focus_mode = Control.FOCUS_NONE
		input.editable = false
		return input
	var control := Control.new()
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if element is UIContainer and (element as UIContainer).full_view:
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
	return control


## Connects the element signals to adapter updates.
func _connect(element: UIElement) -> void:
	var on_changed := func(property: StringName) -> void: _apply(element, property)
	var on_child_added := func(child: UIElement) -> void: _on_child_added(element, child)
	var on_child_removed := func(child: UIElement) -> void: _on_child_removed(element, child)
	element.changed.connect(on_changed)
	element.child_added.connect(on_child_added)
	element.child_removed.connect(on_child_removed)
	_connections.append([element, &"changed", on_changed])
	_connections.append([element, &"child_added", on_child_added])
	_connections.append([element, &"child_removed", on_child_removed])


## Connects the native editing signals of a text field so its commits and focus
## loss reflect in the model.
func _connect_input_control(element: UIElement, control: Control) -> void:
	if not control is LineEdit:
		return
	var on_submitted := func(text: String) -> void: _on_input_submitted(element, text)
	var on_focus_exited := func() -> void: _on_input_focus_exited(element)
	control.text_submitted.connect(on_submitted)
	control.focus_exited.connect(on_focus_exited)
	_connections.append([control, &"text_submitted", on_submitted])
	_connections.append([control, &"focus_exited", on_focus_exited])


## Applies every meaningful property of the element to its control.
func _apply_all(element: UIElement, control: Control) -> void:
	if not _is_full_view(element):
		control.position = element.position
		control.size = element.size
		control.scale = element.scale
	control.z_index = element.z_index
	control.visible = element.visible
	control.modulate = Color(1.0, 1.0, 1.0, element.modulate)
	if control is Button:
		(control as Button).disabled = not element.enabled
	_apply_style(element)
	if element is UIText:
		(control as Label).text = (element as UIText).text
	if element is UIButton:
		(control as Button).text = (element as UIButton).text
	if element is UIInput and control is LineEdit:
		(control as LineEdit).text = (element as UIInput).text
		(control as LineEdit).placeholder_text = (element as UIInput).placeholder


## Applies a single property change to the matching control. Properties that
## affect layout re-arrange the owning container.
func _apply(element: UIElement, property: StringName) -> void:
	var control: Control = _controls.get(element)
	if control == null:
		return
	match property:
		&"position":
			if not _is_full_view(element):
				control.position = element.position
		&"size":
			if not _is_full_view(element):
				control.size = element.size
		&"scale":
			if not _is_full_view(element):
				control.scale = element.scale
		&"z_index":
			control.z_index = element.z_index
		&"visible":
			control.visible = element.visible
		&"enabled":
			if control is Button:
				(control as Button).disabled = not element.enabled
		&"modulate":
			control.modulate = Color(1.0, 1.0, 1.0, element.modulate)
		&"style":
			_apply_style(element)
		&"text":
			if element is UIText and control is Label:
				(control as Label).text = (element as UIText).text
			elif element is UIButton and control is Button:
				(control as Button).text = (element as UIButton).text
			elif element is UIInput and control is LineEdit and _active_input != element:
				(control as LineEdit).text = (element as UIInput).text
		&"placeholder":
			if element is UIInput and control is LineEdit:
				(control as LineEdit).placeholder_text = (element as UIInput).placeholder
		&"orientation", &"separation", &"margin", &"full_view":
			if element is UIContainer:
				arrange(element as UIContainer)
		_:
			_apply_all(element, control)


## Applies the element style to its control as Godot theme overrides.
func _apply_style(element: UIElement) -> void:
	var control: Control = _controls.get(element)
	if control == null:
		return
	if control is Label:
		var label := control as Label
		label.add_theme_color_override("font_color", _font_color(element))
		label.add_theme_constant_override("outline_size", 0)
		label.horizontal_alignment = _align_h(element.style.align_h)
		label.vertical_alignment = _align_v(element.style.align_v)
		if element.style.font_size > 0:
			label.add_theme_font_size_override("font_size", element.style.font_size)
	elif control is Button:
		var button := control as Button
		var stylebox := _make_stylebox(element.style, false)
		button.add_theme_stylebox_override("normal", stylebox)
		button.add_theme_stylebox_override("hover", stylebox)
		button.add_theme_stylebox_override("focus", stylebox)
		button.add_theme_stylebox_override("pressed", stylebox)
		var font_color := _font_color(element)
		button.add_theme_color_override("font_color", font_color)
		button.add_theme_color_override("font_hover_color", font_color)
		button.add_theme_color_override("font_pressed_color", font_color)
		button.add_theme_color_override("font_focus_color", font_color)
		if element.style.font_size > 0:
			button.add_theme_font_size_override("font_size", element.style.font_size)
	elif control is LineEdit:
		var input := control as LineEdit
		var input_stylebox := _make_stylebox(element.style, false)
		input.add_theme_stylebox_override("normal", input_stylebox)
		input.add_theme_stylebox_override("hover", input_stylebox)
		input.add_theme_stylebox_override("focus", input_stylebox)
		input.add_theme_stylebox_override("pressed", input_stylebox)
		input.add_theme_color_override("font_color", _font_color(element))
		var placeholder_color := _font_color(element)
		placeholder_color.a *= 0.5
		input.add_theme_color_override("font_placeholder_color", placeholder_color)
		if element.style.font_size > 0:
			input.add_theme_font_size_override("font_size", element.style.font_size)
	else:
		control.add_theme_stylebox_override("panel", _make_stylebox(element.style, false))


## Returns the foreground of the element: its authored font color when set,
## falling back to the surface color.
func _font_color(element: UIElement) -> Color:
	if not element.style.font_color.is_equal_approx(Color.TRANSPARENT):
		return element.style.font_color
	return element.style.color


## Returns a StyleBoxFlat built from the style data, optionally highlighted.
func _make_stylebox(style: StyleData, highlighted: bool) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	var color := style.color
	if highlighted:
		color = color.lightened(0.25)
	stylebox.bg_color = color
	stylebox.set_corner_radius_all(int(style.border_radius))
	stylebox.border_color = style.border_color
	stylebox.set_border_width_all(int(style.border_width))
	stylebox.shadow_color = style.shadow_color
	stylebox.shadow_size = int(style.shadow_size)
	return stylebox


## Arranges the children of the given container according to its orientation,
## measuring each child with its authored size, its control's minimum size, or
## the laid-out size of a nested container. Nested containers are arranged
## first so their measurements feed the parent. Children use their natural
## width; surplus space centers them within the container. Full-view containers
## fill their parent, other containers grow to fit their content. Measured
## geometry is kept locally and never written back to the model.
func arrange(container: UIContainer) -> void:
	var control: Control = _controls.get(container)
	if control == null:
		return
	for child in container.get_children():
		if child is UIContainer:
			arrange(child as UIContainer)
	var margin := container.margin
	match container.orientation:
		UIContainer.Orientation.FREE:
			for child in container.get_children():
				var child_control: Control = _controls.get(child)
				if child_control == null:
					continue
				child_control.position = child.position
				child_control.size = _size_for(child, child_control)
		UIContainer.Orientation.COLUMN:
			var measured := _measure(container)
			var width := control.size.x - margin.get_left() - margin.get_right()
			if not container.full_view:
				control.size = Vector2(
					maxf(control.size.x, _widest(measured) + margin.get_left() + margin.get_right()),
					_column_height(measured, container.separation) + margin.get_top() + margin.get_bottom()
				)
				width = control.size.x - margin.get_left() - margin.get_right()
			_place_column(container, measured, width, margin)
		_: # ROW
			var measured := _measure(container)
			var height := control.size.y - margin.get_top() - margin.get_bottom()
			if not container.full_view:
				control.size = Vector2(
					_row_width(measured, container.separation) + margin.get_left() + margin.get_right(),
					maxf(control.size.y, _tallest(measured) + margin.get_top() + margin.get_bottom())
				)
				height = control.size.y - margin.get_top() - margin.get_bottom()
			_place_row(container, measured, height, margin)


## Returns the layout size of the given child: its authored size when set, the
## laid-out size of an already-arranged nested container, and the control's
## minimum size otherwise.
func _size_for(element: UIElement, control: Control) -> Vector2:
	if element.size != Vector2.ZERO:
		return element.size
	if element is UIContainer and not (element as UIContainer).full_view \
			and control.size != Vector2.ZERO:
		return control.size
	return control.get_minimum_size()


func _measure(container: UIContainer) -> Array[Array]:
	var measured: Array[Array] = []
	for child in container.get_children():
		var child_control: Control = _controls.get(child)
		if child_control == null:
			continue
		var size := _size_for(child, child_control)
		measured.append([child, child_control, size])
	return measured


## Places a column of children top to bottom, vertically centered when the
## container is taller than its content, and horizontally centered when the
## container is wider than a child.
func _place_column(container: UIContainer, measured: Array[Array], width: float, margin: Margin) -> void:
	var total := _column_height(measured, container.separation)
	var control: Control = _controls.get(container)
	var available: float = control.size.y - margin.get_top() - margin.get_bottom()
	var top := margin.get_top()
	if container.full_view and available > total:
		top += (available - total) * 0.5
	var cursor_y := top
	for entry in measured:
		var child_size: Vector2 = entry[2]
		var pos := Vector2(margin.get_left(), cursor_y)
		if width > child_size.x:
			pos.x = margin.get_left() + (width - child_size.x) * 0.5
		entry[1].position = pos
		entry[1].size = child_size
		cursor_y += child_size.y + container.separation


## Places a row of children left to right, horizontally centered when the
## container is wider than its content, and vertically centered when the
## container is taller than a child.
func _place_row(container: UIContainer, measured: Array[Array], height: float, margin: Margin) -> void:
	var total := _row_width(measured, container.separation)
	var control: Control = _controls.get(container)
	var available: float = control.size.x - margin.get_left() - margin.get_right()
	var left := margin.get_left()
	if container.full_view and available > total:
		left += (available - total) * 0.5
	var cursor_x := left
	for entry in measured:
		var child_size: Vector2 = entry[2]
		var pos := Vector2(cursor_x, margin.get_top())
		if height > child_size.y:
			pos.y = margin.get_top() + (height - child_size.y) * 0.5
		entry[1].position = pos
		entry[1].size = child_size
		cursor_x += child_size.x + container.separation


## Returns the total height of the measured children plus their separations.
func _column_height(measured: Array[Array], separation: float) -> float:
	var total := 0.0
	for i in measured.size():
		total += measured[i][2].y
		if i > 0:
			total += separation
	return total


## Returns the total width of the measured children plus their separations.
func _row_width(measured: Array[Array], separation: float) -> float:
	var total := 0.0
	for i in measured.size():
		total += measured[i][2].x
		if i > 0:
			total += separation
	return total


## Returns the widest measured child width.
func _widest(measured: Array[Array]) -> float:
	var widest := 0.0
	for entry in measured:
		widest = maxf(widest, entry[2].x)
	return widest


## Returns the tallest measured child height.
func _tallest(measured: Array[Array]) -> float:
	var tallest := 0.0
	for entry in measured:
		tallest = maxf(tallest, entry[2].y)
	return tallest


## Raises a child on the matching container when the model gains a child.
func _on_child_added(parent_element: UIElement, child: UIElement) -> void:
	var parent_control: Control = _controls.get(parent_element)
	if parent_control == null:
		return
	var child_control := _materialize(child)
	parent_control.add_child(child_control)
	if parent_element is UIContainer:
		arrange(parent_element as UIContainer)


## Removes the control of a removed child, including its subtree, and
## re-arranges the parent container.
func _on_child_removed(parent_element: UIElement, child: UIElement) -> void:
	_release_subtree(child)
	if parent_element is UIContainer:
		arrange(parent_element as UIContainer)


## Frees the controls of the given element and its descendants and unregisters
## them, without restarting the whole view.
func _release_subtree(element: UIElement) -> void:
	var control = _controls.get(element)
	if control != null:
		_controls.erase(element)
		control.queue_free()
	if _highlighted == element:
		_highlighted = null
	if _active_input == element:
		_active_input = null
		_cancel_pending = false
	for child in element.get_children():
		_release_subtree(child)


## Maps StyleData horizontal alignment to the Label alignment enum. The
## alignment is an int because GDScript enums are not types.
func _align_h(alignment: int) -> HorizontalAlignment:
	match alignment:
		StyleData.AlignH.LEFT:
			return HORIZONTAL_ALIGNMENT_LEFT
		StyleData.AlignH.RIGHT:
			return HORIZONTAL_ALIGNMENT_RIGHT
		_:
			return HORIZONTAL_ALIGNMENT_CENTER


## Maps StyleData vertical alignment to the Label alignment enum.
func _align_v(alignment: int) -> VerticalAlignment:
	match alignment:
		StyleData.AlignV.TOP:
			return VERTICAL_ALIGNMENT_TOP
		StyleData.AlignV.BOTTOM:
			return VERTICAL_ALIGNMENT_BOTTOM
		_:
			return VERTICAL_ALIGNMENT_CENTER