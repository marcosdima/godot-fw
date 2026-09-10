extends RefCounted
class_name UISettingsMenu


## Identifiers of the settings menu elements.
enum SettingsId {
	ROOT,
	TITLE,
	BACK,
}


## Builds the settings screen: a title and a Back button. on_back is invoked
## when Back is pressed.
static func build(on_back: Callable) -> UIScreen:
	var root := UIContainer.new(SettingsId.ROOT, "settings_root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.COLUMN
	root.separation = 8
	root.margin.set_all(32.0)
	root.style.color = Color(0.10, 0.12, 0.15)

	var title := UIText.new(SettingsId.TITLE, "title")
	title.text = "Settings"
	title.style.font_size = 40
	title.style.color = Color(0.95, 0.97, 1.0)
	root.add(title)

	var back := UIMainMenu.menu_button(SettingsId.BACK, "Back", on_back)
	root.add(back)

	var screen := UIScreen.new()
	screen.root = root
	screen.group = UIMainMenu.build_group([back])
	return screen