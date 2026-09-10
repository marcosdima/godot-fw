extends GutTest


func test_build_materializes_a_full_view_free_root() -> void:
	var hud := UIHud.build()
	var root := hud as UIContainer
	assert_not_null(root)
	assert_eq(root.name, "hud_root")
	assert_true(root.full_view)
	assert_eq(root.orientation, UIContainer.Orientation.FREE)
	assert_eq(root.z_index, UIHud.OVERLAY_Z_INDEX)


func test_find_id_locates_every_element() -> void:
	var hud := UIHud.build()
	for id in UIHud.HudId.values():
		var element := UIHud.find_id(hud, id)
		assert_not_null(element, "missing HUD element %d" % id)
		assert_eq(element.id, id)


func test_bar_sits_top_left_and_its_fill_matches_the_surface() -> void:
	var hud := UIHud.build()
	var bar := UIHud.find_id(hud, UIHud.HudId.VITALITY_BAR)
	assert_eq(bar.position, UIHud.VITALITY_BAR_POSITION)
	assert_eq(bar.size, UIHud.VITALITY_BAR_SIZE)
	var tray := UIHud.find_id(hud, UIHud.HudId.VITALITY_TRAY)
	var fill := UIHud.find_id(hud, UIHud.HudId.VITALITY_FILL)
	assert_eq(tray.position, Vector2.ZERO)
	assert_eq(fill.position, Vector2.ZERO)
	assert_eq(fill.size, tray.size)


func test_rect_elements_are_inert_buttons() -> void:
	var hud := UIHud.build()
	for id in [UIHud.HudId.VITALITY_TRAY, UIHud.HudId.VITALITY_FILL]:
		var rect := UIHud.find_id(hud, id) as UIButton
		assert_not_null(rect)
		assert_true(rect.enabled)
		assert_eq(rect.text, "")
		assert_false(rect.action.is_valid())


func test_texts_are_laid_out_under_the_bar() -> void:
	var hud := UIHud.build()
	var bar := UIHud.find_id(hud, UIHud.HudId.VITALITY_BAR)
	var vitality := UIHud.find_id(hud, UIHud.HudId.VITALITY_TEXT) as UIText
	var souls := UIHud.find_id(hud, UIHud.HudId.SOULS) as UIText
	var alert := UIHud.find_id(hud, UIHud.HudId.ALERT) as UIText
	assert_eq(vitality.style.align_h, StyleData.AlignH.LEFT)
	assert_eq(souls.style.align_h, StyleData.AlignH.LEFT)
	assert_eq(alert.style.align_h, StyleData.AlignH.LEFT)
	assert_gt(vitality.position.y, bar.position.y + bar.size.y)
	assert_gt(souls.position.y, vitality.position.y)
	assert_gt(alert.position.y, souls.position.y)


func test_materializes_authored_geometry_reads_updates() -> void:
	var adapter := UIControlAdapter.new()
	var hud := UIHud.build()
	var control := adapter.build(hud)
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	adapter.arrange(hud)
	var bar_control := adapter.get_control(UIHud.find_id(hud, UIHud.HudId.VITALITY_BAR)) as Control
	assert_eq(bar_control.position, UIHud.VITALITY_BAR_POSITION)
	assert_eq(bar_control.size, UIHud.VITALITY_BAR_SIZE)
	var fill := UIHud.find_id(hud, UIHud.HudId.VITALITY_FILL) as UIButton
	fill.size = Vector2(120.0, UIHud.VITALITY_BAR_SIZE.y)
	var fill_control := adapter.get_control(fill) as Control
	assert_eq(fill_control.size.x, 120.0)
	assert_eq(fill_control.position.x, 0.0)