extends GutTest


var _demo: HudDemo = null


func before_each() -> void:
	_demo = HudDemo.new()
	add_child_autofree(_demo)
	_demo.set_process(false)


func test_demo_starts_full_on_vitality() -> void:
	assert_eq(_demo.get_vitality(), 20.0)
	assert_eq(_demo.get_souls(), 0)
	assert_eq((UIHud.find_id(_demo.get_hud(), UIHud.HudId.VITALITY_TEXT) as UIText).text, "20/20")
	assert_eq((UIHud.find_id(_demo.get_hud(), UIHud.HudId.ALERT) as UIText).text, "")


func test_step_sequence_is_deterministic() -> void:
	var expected := [16.0, 20.0, 8.0, 11.0, 7.0, 12.0, 0.0, 3.0]
	for step in 8:
		_demo.step()
		assert_eq(_demo.get_vitality(), expected[step], "vitality mismatch at step %d" % (step + 1))


func test_step_updates_hud_texts_and_souls() -> void:
	_demo.step()
	assert_eq((UIHud.find_id(_demo.get_hud(), UIHud.HudId.VITALITY_TEXT) as UIText).text, "16/20")
	assert_eq((UIHud.find_id(_demo.get_hud(), UIHud.HudId.SOULS) as UIText).text, "Souls: 1")
	assert_eq((UIHud.find_id(_demo.get_hud(), UIHud.HudId.ALERT) as UIText).text, "Hit!")
	_demo.step()
	assert_eq((UIHud.find_id(_demo.get_hud(), UIHud.HudId.ALERT) as UIText).text, "Healed")


func test_sync_repeats_are_effective_only() -> void:
	var hud := _demo.get_hud()
	var fill := UIHud.find_id(hud, UIHud.HudId.VITALITY_FILL)
	var vitality := UIHud.find_id(hud, UIHud.HudId.VITALITY_TEXT)
	var size_emits := [0]
	var text_emits := [0]
	fill.changed.connect(func(property: StringName) -> void:
		if property == &"size":
			size_emits[0] += 1)
	vitality.changed.connect(func(property: StringName) -> void:
		if property == &"text":
			text_emits[0] += 1)
	_demo.step()
	assert_eq(size_emits[0], 1)
	assert_eq(text_emits[0], 1)
	var size_after: int = size_emits[0]
	var text_after: int = text_emits[0]
	_demo.sync()
	_demo.sync()
	_demo.sync()
	assert_eq(size_emits[0], size_after)
	assert_eq(text_emits[0], text_after)


func test_damage_flash_dims_and_restores_the_fill() -> void:
	var pair := _hosted_demo()
	var host: UIHost = pair[0]
	var demo: HudDemo = pair[1]
	await get_tree().process_frame
	var fill_control := host.get_hud_adapter().get_control(UIHud.find_id(demo.get_hud(), UIHud.HudId.VITALITY_FILL)) as Control
	assert_eq(fill_control.modulate.a, 1.0)
	demo.step()
	host._process(0.05)
	assert_lt(fill_control.modulate.a, 1.0)
	host._process(0.2)
	await get_tree().process_frame
	assert_eq(fill_control.modulate.a, 1.0)


func test_heal_step_does_not_register_a_flash() -> void:
	var pair := _hosted_demo()
	var host: UIHost = pair[0]
	var demo: HudDemo = pair[1]
	await get_tree().process_frame
	var fill_control := host.get_hud_adapter().get_control(UIHud.find_id(demo.get_hud(), UIHud.HudId.VITALITY_FILL)) as Control
	demo.step()
	host._process(0.05)
	host._process(0.2)
	await get_tree().process_frame
	assert_eq(fill_control.modulate.a, 1.0)
	demo.step()
	host._process(0.05)
	assert_eq(fill_control.modulate.a, 1.0)


func test_auto_step_drives_the_hud_live() -> void:
	_demo.beat_seconds = 0.05
	_demo.set_process(true)
	await wait_seconds(0.3)
	assert_gt(_demo.get_souls(), 0)


## Builds a host with a demo attached and returns both. The demo's _ready wires
## the HUD to the host; the process loop is disabled so steps stay deterministic.
func _hosted_demo() -> Array:
	var host := UIHost.new()
	var demo := HudDemo.new()
	host.add_child(demo)
	add_child_autofree(host)
	demo.set_process(false)
	return [host, demo]