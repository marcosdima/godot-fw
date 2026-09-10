extends GutTest


var _property_events: Array[StringName] = []


func _on_changed(property: StringName) -> void:
	_property_events.append(property)


func test_text_setter_emits_changed_including_text() -> void:
	var ui_text: UIText = UIText.new(0, "label")
	ui_text.changed.connect(_on_changed)
	_property_events.clear()
	ui_text.text = "Hello"
	ui_text.visible = false
	assert_eq(_property_events, [&"text", &"visible"])


func test_assigning_same_text_does_not_emit_changed() -> void:
	var ui_text: UIText = UIText.new(0, "label")
	watch_signals(ui_text)
	ui_text.text = "Hello"
	ui_text.text = "Hello"
	assert_signal_emit_count(ui_text, "changed", 1)