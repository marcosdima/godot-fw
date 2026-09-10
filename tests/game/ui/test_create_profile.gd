extends GutTest


var _screen: UIScreen = null
var _submitted := ""
var _back_calls := 0


func before_each() -> void:
	_submitted = ""
	_back_calls = 0
	_screen = UICreateProfile.build(
		func(name: String) -> void: _submitted = name,
		func() -> void: _back_calls += 1
	)


func _by(id: int) -> UIElement:
	return _find_by_id(_screen.root, id)


func _find_by_id(element: UIElement, id: int) -> UIElement:
	if element.id == id:
		return element
	for child in element.get_children():
		var found := _find_by_id(child, id)
		if found != null:
			return found
	return null


func test_builds_title_field_buttons_and_status() -> void:
	var title := _by(UICreateProfile.CreateId.TITLE)
	assert_not_null(title)
	assert_eq((title as UIText).text, "Create Profile")
	var name_row := _by(UICreateProfile.CreateId.NAME_ROW)
	assert_true(name_row is UIContainer)
	assert_eq((name_row as UIContainer).orientation, UIContainer.Orientation.ROW)
	var status := _by(UICreateProfile.CreateId.STATUS)
	assert_eq((status as UIText).text, "")
	var create := _by(UICreateProfile.CreateId.CREATE)
	assert_eq((create as UIButton).text, "Create")
	var back := _by(UICreateProfile.CreateId.BACK)
	assert_eq((back as UIButton).text, "Back")


func test_name_field_has_a_placeholder_and_legible_foreground() -> void:
	var input := _by(UICreateProfile.CreateId.NAME_INPUT) as UIInput
	assert_not_null(input)
	assert_eq(input.placeholder, "Character name")
	assert_false(input.style.font_color.is_equal_approx(Color.TRANSPARENT))


func test_group_order_is_field_then_create_then_back() -> void:
	var items := _screen.group.get_items()
	assert_eq(items.size(), 3)
	assert_eq(items[0].id, UICreateProfile.CreateId.NAME_INPUT)
	assert_eq(items[1].id, UICreateProfile.CreateId.CREATE)
	assert_eq(items[2].id, UICreateProfile.CreateId.BACK)
	_screen.group.focus_first()
	assert_eq(_screen.group.get_focused().id, UICreateProfile.CreateId.NAME_INPUT)


func test_create_with_an_empty_name_shows_the_error_and_does_not_submit() -> void:
	var create := _by(UICreateProfile.CreateId.CREATE) as UIButton
	create.press()
	assert_eq((_by(UICreateProfile.CreateId.STATUS) as UIText).text, "Name is required.")
	assert_eq(_submitted, "")


func test_create_submits_the_trimmed_name_and_clears_the_error() -> void:
	var input := _by(UICreateProfile.CreateId.NAME_INPUT) as UIInput
	input.text = "  Marcos  "
	var create := _by(UICreateProfile.CreateId.CREATE) as UIButton
	create.press()
	assert_eq(_submitted, "Marcos")
	assert_eq((_by(UICreateProfile.CreateId.STATUS) as UIText).text, "")


func test_back_invokes_on_back() -> void:
	var back := _by(UICreateProfile.CreateId.BACK) as UIButton
	back.press()
	assert_eq(_back_calls, 1)