extends RefCounted
class_name UIMainMenu


## Identifiers of the main menu elements.
enum MenuId {
	ROOT,
	TITLE,
	PLAY,
	SETTINGS,
	QUIT,
	CREATE_PROFILE,
}


## Builds the main menu screen: a title, a column of buttons and a selection
## group over them. on_settings is invoked when Settings is pressed;
## on_quit when Quit is pressed; on_profile when Create Profile is pressed and
## is optional, in which case the button is not added.
static func build(on_settings: Callable, on_quit: Callable, on_profile: Callable = Callable()) -> UIScreen:
	var root := UIContainer.new(MenuId.ROOT, "main_root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.COLUMN
	root.separation = 8
	root.margin.set_all(32.0)
	root.style.color = Color(0.10, 0.10, 0.13)

	var title := UIText.new(MenuId.TITLE, "title")
	title.text = "Agents"
	title.style.font_size = 48
	title.style.color = Color(0.95, 0.97, 1.0)
	root.add(title)

	var play := menu_button(MenuId.PLAY, "Play", func() -> void: pass)
	var settings := menu_button(MenuId.SETTINGS, "Settings", on_settings)
	var quit := menu_button(MenuId.QUIT, "Quit", on_quit)
	root.add(play)
	root.add(settings)
	root.add(quit)
	var group_items: Array[UIElement] = [play, settings, quit]
	if on_profile.is_valid():
		var profile := menu_button(MenuId.CREATE_PROFILE, "Create Profile", on_profile)
		root.add(profile)
		group_items.append(profile)

	var screen := UIScreen.new()
	screen.root = root
	screen.group = build_group(group_items)
	screen.playbacks = [_title_fade(title)]
	return screen


## Creates a styled menu button with the given text and action.
static func menu_button(id: int, label: String, action: Callable) -> UIButton:
	var button := UIButton.new(id, label.to_snake_case())
	button.text = label
	button.action = action
	button.style.color = Color(0.24, 0.28, 0.42)
	button.style.border_color = Color(0.55, 0.65, 0.95)
	button.style.border_width = 2.0
	button.style.border_radius = 6.0
	button.style.font_size = 20
	return button


## Returns a selection group over the given elements, focused on the first one.
static func build_group(items: Array[UIElement]) -> SelectionGroup:
	var group := SelectionGroup.new()
	for item in items:
		group.add(item)
	return group


## Returns a playback that fades the title in from transparent to opaque.
static func _title_fade(title: UIText) -> UIAnimationPlayback:
	var fade := UIAnimationDefinition.new()
	fade.duration = 0.6
	fade.easing = UIAnimationDefinition.Easing.EASE_OUT
	fade.add_track(&"modulate", 1.0)
	title.modulate = 0.0
	return UIAnimationPlayback.new(title, fade)