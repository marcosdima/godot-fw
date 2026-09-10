extends GutTest


func test_empty_stack_has_no_current() -> void:
	var stack := ScreenStack.new()
	assert_true(stack.is_empty())
	assert_null(stack.current)


func test_push_makes_the_screen_current_and_emits_changed() -> void:
	var stack := ScreenStack.new()
	var root: UIElement = UIElement.new(0, "root")
	watch_signals(stack)
	stack.push(root)
	assert_same(stack.current, root)
	assert_signal_emitted_with_parameters(stack, "changed", [root])


func test_push_replaces_current_and_keeps_history() -> void:
	var stack := ScreenStack.new()
	var main: UIElement = UIElement.new(0, "main")
	var settings: UIElement = UIElement.new(1, "settings")
	stack.push(main)
	stack.push(settings)
	assert_same(stack.current, settings)


func test_pushing_current_screen_again_is_a_no_op() -> void:
	var stack := ScreenStack.new()
	var root: UIElement = UIElement.new(0, "root")
	stack.push(root)
	watch_signals(stack)
	stack.push(root)
	assert_signal_not_emitted(stack, "changed")
	assert_eq(stack.current, root)


func test_push_rejects_null_screen() -> void:
	var stack := ScreenStack.new()
	watch_signals(stack)
	stack.push(null)
	assert_push_error_count(1, "null push emits an error")
	assert_true(stack.is_empty())


func test_pop_returns_to_the_previous_screen() -> void:
	var stack := ScreenStack.new()
	var main: UIElement = UIElement.new(0, "main")
	var settings: UIElement = UIElement.new(1, "settings")
	stack.push(main)
	stack.push(settings)
	watch_signals(stack)
	stack.pop()
	assert_same(stack.current, main)
	assert_signal_emitted_with_parameters(stack, "changed", [main])


func test_pop_last_screen_empties_the_stack() -> void:
	var stack := ScreenStack.new()
	var main: UIElement = UIElement.new(0, "main")
	stack.push(main)
	stack.pop()
	assert_true(stack.is_empty())
	assert_null(stack.current)


func test_pop_empty_stack_is_a_no_op() -> void:
	var stack := ScreenStack.new()
	watch_signals(stack)
	stack.pop()
	assert_signal_not_emitted(stack, "changed")


func test_clear_empties_the_stack_and_emits_null() -> void:
	var stack := ScreenStack.new()
	var main: UIElement = UIElement.new(0, "main")
	stack.push(main)
	watch_signals(stack)
	stack.clear()
	assert_true(stack.is_empty())
	assert_null(stack.current)
	assert_signal_emitted_with_parameters(stack, "changed", [null])


func test_clear_empty_stack_is_a_no_op() -> void:
	var stack := ScreenStack.new()
	watch_signals(stack)
	stack.clear()
	assert_signal_not_emitted(stack, "changed")