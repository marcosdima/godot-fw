extends GutTest


func test_unset_margin_resolves_to_zero() -> void:
	var margin := Margin.new()
	assert_eq(margin.get_left(), 0.0)
	assert_eq(margin.get_right(), 0.0)
	assert_eq(margin.get_top(), 0.0)
	assert_eq(margin.get_bottom(), 0.0)


func test_total_fills_every_side() -> void:
	var margin := Margin.new()
	margin.set_all(8.0)
	assert_eq(margin.get_left(), 8.0)
	assert_eq(margin.get_right(), 8.0)
	assert_eq(margin.get_top(), 8.0)
	assert_eq(margin.get_bottom(), 8.0)


func test_axis_falls_back_before_total() -> void:
	var margin := Margin.new()
	margin.set_all(8.0)
	margin.set_horizontal(4.0)
	margin.set_vertical(2.0)
	assert_eq(margin.get_left(), 4.0)
	assert_eq(margin.get_right(), 4.0)
	assert_eq(margin.get_top(), 2.0)
	assert_eq(margin.get_bottom(), 2.0)


func test_side_takes_precedence_over_axis_and_total() -> void:
	var margin := Margin.new()
	margin.set_all(8.0)
	margin.set_horizontal(4.0)
	margin.left = 1.0
	assert_eq(margin.get_left(), 1.0)
	assert_eq(margin.get_right(), 4.0)


func test_mixing_axis_resolutions() -> void:
	var margin := Margin.new()
	margin.set_horizontal(5.0)
	margin.left = 3.0
	assert_eq(margin.get_left(), 3.0)
	assert_eq(margin.get_right(), 5.0)
	assert_eq(margin.get_top(), 0.0)
	assert_eq(margin.get_bottom(), 0.0)