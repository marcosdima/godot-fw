extends RefCounted
class_name UIContractsMenu


## Identifiers of the contracts screen elements.
enum ContractsId {
	ROOT,
	TITLE,
	STATUS,
	ENTRY_START,
	FOOTER_ROW,
	FOOTER_HINT,
	EXIT,
}


## The static list data driving the contracts screen. Each entry is a
## Dictionary with a unique `name` shown on its button and a longer `desc`
## rendered by the selection status line. The data lives outside the
## UIElement tree; entries are materialized row by row at build time.
const CONTRACTS: Array[Dictionary] = [
	{ "name": "Sector 7 Rendezvous", "desc": "Meet the courier at the off grid depot." },
	{ "name": "Asset Recovery", "desc": "Retrieve the sealed sample crate from the vault." },
	{ "name": "Watchtower Recon", "desc": "Catalog guard rotations and map the perimeter." },
	{ "name": "Silent Persuasion", "desc": "Obtain the access badge without raising alarms." },
	{ "name": "Trail Intercept", "desc": "Ambush the transport on the mountain road." },
	{ "name": "Containment Sweep", "desc": "Purge stray traces left in the abandoned lab." },
	{ "name": "Containment Breach Extract the S 2 Prototype Unit", "desc": "Full suppression team, zero trace protocol." },
	{ "name": "Double Exchange", "desc": "Swap the decoy documents and leave a clean ledger." },
]


## Builds the contracts screen: a title, one selectable entry per element of
## `data`, a status line that follows the selection and a footer row with an
## Exit button. on_submit is invoked with the selected entry (a Dictionary);
## on_back when Exit is pressed (Escape pops through the host generically).
static func build(data: Array, on_submit: Callable, on_back: Callable) -> UIScreen:
	var root := UIContainer.new(ContractsId.ROOT, "contracts_root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.COLUMN
	root.separation = 10
	root.margin.set_all(32.0)
	root.style.color = Color(0.10, 0.10, 0.13)

	var title := UIText.new(ContractsId.TITLE, "title")
	title.text = "Contracts"
	title.style.font_size = 40
	title.style.color = Color(0.95, 0.97, 1.0)
	root.add(title)

	var entries: Array[UIElement] = []
	var by_name: Dictionary = {}
	for index in data.size():
		var contract: Dictionary = data[index]
		var entry := UIMainMenu.menu_button(
			ContractsId.ENTRY_START + index,
			contract.name,
			func() -> void: on_submit.call(contract),
		)
		root.add(entry)
		entries.append(entry)
		by_name[entry.name] = contract

	var status := UIText.new(ContractsId.STATUS, "status")
	status.text = "Selection: —"
	status.style.font_size = 16
	status.style.font_color = Color(0.95, 0.97, 1.0)
	root.add(status)

	var footer_row := UIContainer.new(ContractsId.FOOTER_ROW, "footer_row")
	footer_row.orientation = UIContainer.Orientation.ROW
	footer_row.separation = 8
	var hint := UIText.new(ContractsId.FOOTER_HINT, "footer_hint")
	hint.text = "Move: up/down   Submit: enter   Back: escape"
	hint.style.font_size = 14
	hint.style.font_color = Color(0.75, 0.80, 0.92)
	var exit := UIMainMenu.menu_button(ContractsId.EXIT, "Exit", on_back)
	footer_row.add(hint)
	footer_row.add(exit)
	root.add(footer_row)

	var group_items: Array[UIElement] = entries.duplicate()
	group_items.append(exit)

	var screen := UIScreen.new()
	screen.root = root
	screen.group = UIMainMenu.build_group(group_items)
	screen.group.focused_changed.connect(func(_previous: UIElement, current: UIElement) -> void: status.text = _status_text(current, by_name))
	screen.playbacks = [_title_fade(title)]
	return screen


## Returns the status line text for the focused element, resolving the entry
## description through the name lookup table. Unknown elements fall back to a
## neutral placeholder.
static func _status_text(focused: UIElement, by_name: Dictionary) -> String:
	if focused == null:
		return "Selection: —"
	var contract: Dictionary = by_name.get(focused.name, {})
	if contract.is_empty():
		return "Selection: —"
	return "Selection: %s — %s" % [contract.name, contract.desc]


## Returns a playback that fades the title in from transparent to opaque.
static func _title_fade(title: UIText) -> UIAnimationPlayback:
	var fade := UIAnimationDefinition.new()
	fade.duration = 0.6
	fade.easing = UIAnimationDefinition.Easing.EASE_OUT
	fade.add_track(&"modulate", 1.0)
	title.modulate = 0.0
	return UIAnimationPlayback.new(title, fade)