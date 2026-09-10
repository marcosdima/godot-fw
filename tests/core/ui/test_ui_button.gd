extends GutTest


func test_press_executes_the_action() -> void:
	var pressed := [false]
	var button: UIButton = UIButton.new(0, "button")
	button.action = func() -> void: pressed[0] = true
	button.press()
	assert_true(pressed[0])


func test_press_without_action_is_a_no_op() -> void:
	var button: UIButton = UIButton.new(0, "button")
	button.press()
	assert_false(button.action.is_valid())


func test_assigning_same_text_does_not_emit_changed() -> void:
	var button: UIButton = UIButton.new(0, "button")
	watch_signals(button)
	button.text = "Play"
	button.text = "Play"
	assert_signal_emit_count(button, "changed", 1)


func test_text_setter_emits_changed_with_text() -> void:
	var button: UIButton = UIButton.new(0, "button")
	watch_signals(button)
	button.text = "Play"
	assert_signal_emitted_with_parameters(button, "changed", [&"text"])