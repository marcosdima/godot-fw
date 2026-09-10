extends GutTest


func test_style_defaults_are_neutral() -> void:
	var style := StyleData.new()
	assert_eq(style.color, Color.WHITE)
	assert_eq(style.border_color, Color.TRANSPARENT)
	assert_eq(style.border_width, 0.0)
	assert_eq(style.border_radius, 0.0)
	assert_eq(style.shadow_color, Color.TRANSPARENT)
	assert_eq(style.shadow_size, 0.0)
	assert_eq(style.font_size, 0)
	assert_eq(style.align_h, StyleData.AlignH.CENTER)
	assert_eq(style.align_v, StyleData.AlignV.CENTER)