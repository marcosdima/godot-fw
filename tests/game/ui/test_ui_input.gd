extends GutTest


func test_defaults_are_empty() -> void:
	var input := UIInput.new(1, "field")
	assert_eq(input.text, "")
	assert_eq(input.placeholder, "")


func test_text_emits_changed_with_effective_changes_only() -> void:
	var input := UIInput.new(1, "field")
	var changes: Array[StringName] = []
	input.changed.connect(func(property: StringName) -> void: changes.append(property))
	input.text = "Marcos"
	input.text = "Marcos"
	assert_eq(changes.size(), 1)
	assert_eq(changes[0], &"text")
	assert_eq(input.text, "Marcos")


func test_placeholder_emits_changed_with_effective_changes_only() -> void:
	var input := UIInput.new(1, "field")
	var changes: Array[StringName] = []
	input.changed.connect(func(property: StringName) -> void: changes.append(property))
	input.placeholder = "Name"
	input.placeholder = "Name"
	assert_eq(changes.size(), 1)
	assert_eq(changes[0], &"placeholder")
	assert_eq(input.placeholder, "Name")