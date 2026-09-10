extends RefCounted
class_name UICreateProfile


## Identifiers of the create profile screen elements.
enum CreateId {
	ROOT,
	TITLE,
	NAME_ROW,
	NAME_LABEL,
	NAME_INPUT,
	STATUS,
	CREATE,
	BACK,
}


## Builds the create profile screen: a title, a name field and Create and Back
## buttons. The field's committed text is read at Create through its model value;
## on_submit receives the trimmed name when it is not empty. on_back is invoked
## when Back is pressed.
static func build(on_submit: Callable, on_back: Callable) -> UIScreen:
	var root := UIContainer.new(CreateId.ROOT, "create_root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.COLUMN
	root.separation = 8
	root.margin.set_all(32.0)
	root.style.color = Color(0.10, 0.12, 0.15)

	var title := UIText.new(CreateId.TITLE, "title")
	title.text = "Create Profile"
	title.style.font_size = 40
	title.style.color = Color(0.95, 0.97, 1.0)
	root.add(title)

	var name_row := UIContainer.new(CreateId.NAME_ROW, "name_row")
	name_row.orientation = UIContainer.Orientation.ROW
	name_row.separation = 8
	root.add(name_row)

	var name_label := UIText.new(CreateId.NAME_LABEL, "name_label")
	name_label.text = "Name"
	name_label.style.font_size = 20
	name_label.style.color = Color(0.95, 0.97, 1.0)
	name_label.size = Vector2(120.0, 36.0)
	name_row.add(name_label)

	var name_input := UIInput.new(CreateId.NAME_INPUT, "name_input")
	name_input.placeholder = "Character name"
	name_input.style.color = Color(0.16, 0.19, 0.29)
	name_input.style.font_color = Color(0.92, 0.95, 1.0)
	name_input.style.border_color = Color(0.55, 0.65, 0.95)
	name_input.style.border_width = 2.0
	name_input.style.border_radius = 6.0
	name_input.style.font_size = 20
	name_input.size = Vector2(320.0, 36.0)
	name_row.add(name_input)

	var status := UIText.new(CreateId.STATUS, "status")
	status.text = ""
	status.style.font_size = 16
	status.style.color = Color(0.95, 0.55, 0.35)
	root.add(status)

	var create := UIMainMenu.menu_button(CreateId.CREATE, "Create", Callable())
	create.style.font_color = Color(0.92, 0.95, 1.0)
	var back := UIMainMenu.menu_button(CreateId.BACK, "Back", on_back)
	back.style.font_color = Color(0.92, 0.95, 1.0)
	root.add(create)
	root.add(back)

	create.action = func() -> void:
		var name := name_input.text.strip_edges()
		if name.is_empty():
			status.text = "Name is required."
			return
		status.text = ""
		on_submit.call(name)

	var screen := UIScreen.new()
	screen.root = root
	screen.group = UIMainMenu.build_group([name_input, create, back])
	screen.playbacks = [_title_fade(title)]
	return screen


## Returns a playback that fades the title in from transparent to opaque.
static func _title_fade(title: UIText) -> UIAnimationPlayback:
	var fade := UIAnimationDefinition.new()
	fade.duration = 0.6
	fade.easing = UIAnimationDefinition.Easing.EASE_OUT
	fade.add_track(&"modulate", 1.0)
	title.modulate = 0.0
	return UIAnimationPlayback.new(title, fade)