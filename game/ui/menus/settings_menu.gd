extends RefCounted
class_name UISettingsMenu


## Identifiers of the settings menu elements.
enum SettingsId {
	ROOT,
	TITLE,
	VOLUME_ROW,
	VOLUME_DEC,
	VOLUME_VALUE,
	VOLUME_INC,
	FULLSCREEN,
	RESOLUTION,
	BACK,
}


## Builds the settings screen: a title, one row per editable setting and a Back
## button. The values live in `settings`, which the UI renders and mutates but
## never owns. on_back is invoked when Back is pressed.
static func build(settings: AgentSettings, on_back: Callable) -> UIScreen:
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

	var fullscreen := _setting_button(SettingsId.FULLSCREEN, "fullscreen")
	var resolution := _setting_button(SettingsId.RESOLUTION, "resolution")

	fullscreen.action = func() -> void:
		settings.toggle_fullscreen()
		fullscreen.text = _fullscreen_text(settings.fullscreen)
	fullscreen.text = _fullscreen_text(settings.fullscreen)

	resolution.action = func() -> void:
		settings.cycle_resolution()
		resolution.text = _resolution_text(settings)
	resolution.text = _resolution_text(settings)

	var volume_row := UIContainer.new(SettingsId.VOLUME_ROW, "volume_row")
	volume_row.orientation = UIContainer.Orientation.ROW
	volume_row.separation = 8
	root.add(volume_row)

	var dec := _setting_button(SettingsId.VOLUME_DEC, "volume_dec")
	var inc := _setting_button(SettingsId.VOLUME_INC, "volume_inc")
	var value_label := UIText.new(SettingsId.VOLUME_VALUE, "volume_value")
	value_label.style.font_size = 20
	value_label.style.color = Color(0.95, 0.97, 1.0)

	dec.text = "−"
	dec.action = func() -> void:
		settings.step_volume(-10)
		value_label.text = _volume_text(settings.volume)
	inc.text = "+"
	inc.action = func() -> void:
		settings.step_volume(10)
		value_label.text = _volume_text(settings.volume)
	value_label.text = _volume_text(settings.volume)

	volume_row.add(dec)
	volume_row.add(value_label)
	volume_row.add(inc)
	root.add(volume_row)

	root.add(fullscreen)
	root.add(resolution)

	var back := UIMainMenu.menu_button(SettingsId.BACK, "Back", on_back)
	root.add(back)

	var screen := UIScreen.new()
	screen.root = root
	screen.group = UIMainMenu.build_group([dec, inc, fullscreen, resolution, back])
	screen.playbacks = [_title_fade(title)]
	return screen


## Creates a styled, unlabeled button whose text is set by the caller.
static func _setting_button(id: int, name: String) -> UIButton:
	var button := UIButton.new(id, name)
	button.style.color = Color(0.24, 0.28, 0.42)
	button.style.font_color = Color(0.92, 0.95, 1.0)
	button.style.border_color = Color(0.55, 0.65, 0.95)
	button.style.border_width = 2.0
	button.style.border_radius = 6.0
	button.style.font_size = 20
	return button


## Returns the displayed text of the fullscreen row.
static func _fullscreen_text(enabled: bool) -> String:
	return "Fullscreen: %s" % ("On" if enabled else "Off")


## Returns the displayed text of the resolution row.
static func _resolution_text(settings: AgentSettings) -> String:
	return "Resolution: %s" % settings.get_resolution_text()


## Returns the displayed text of the volume value.
static func _volume_text(volume: int) -> String:
	return "%d%%" % volume


## Returns a playback that fades the title in from transparent to opaque.
static func _title_fade(title: UIText) -> UIAnimationPlayback:
	var fade := UIAnimationDefinition.new()
	fade.duration = 0.6
	fade.easing = UIAnimationDefinition.Easing.EASE_OUT
	fade.add_track(&"modulate", 1.0)
	title.modulate = 0.0
	return UIAnimationPlayback.new(title, fade)