extends RefCounted
class_name UIHud


## Identifiers of the HUD elements.
enum HudId {
	ROOT,
	VITALITY_BAR,
	VITALITY_TRAY,
	VITALITY_FILL,
	VITALITY_TEXT,
	SOULS,
	ALERT,
}

## Authored size of the vitality bar and its fill.
const VITALITY_BAR_SIZE := Vector2(240.0, 20.0)

## Authored top-left corner of the bar.
const VITALITY_BAR_POSITION := Vector2(16.0, 16.0)

## Vertical stacking order applied to the root so the overlay draws above screens.
const OVERLAY_Z_INDEX := 100


## Builds the HUD element tree: a full-view FREE root that never traps input,
## a top-left vitality bar (a tray with a fill rectangle that the game resizes
## as a fraction of the bar), the numeric vitality readout, a souls counter and
## an alert line. The tree is pure geometry and data: the game owns, writes and
## drives it; the host only materializes it over every screen.
static func build() -> UIElement:
	var root := UIContainer.new(HudId.ROOT, "hud_root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.FREE
	root.style.color = Color.TRANSPARENT
	root.z_index = OVERLAY_Z_INDEX

	var tray := _rect(
		HudId.VITALITY_TRAY,
		"vitality_tray",
		Vector2.ZERO,
		VITALITY_BAR_SIZE,
		Color(0.09, 0.11, 0.15),
		Color(0.38, 0.46, 0.60),
	)
	var fill := _rect(
		HudId.VITALITY_FILL,
		"vitality_fill",
		Vector2.ZERO,
		VITALITY_BAR_SIZE,
		Color(0.22, 0.68, 0.36),
	)

	var bar := UIContainer.new(HudId.VITALITY_BAR, "vitality_bar")
	bar.orientation = UIContainer.Orientation.FREE
	bar.position = VITALITY_BAR_POSITION
	bar.size = VITALITY_BAR_SIZE
	bar.add(tray)
	bar.add(fill)
	root.add(bar)

	var vitality := UIText.new(HudId.VITALITY_TEXT, "vitality_text")
	vitality.position = Vector2(VITALITY_BAR_POSITION.x, VITALITY_BAR_POSITION.y + VITALITY_BAR_SIZE.y + 6.0)
	vitality.size = Vector2(VITALITY_BAR_SIZE.x, 22.0)
	vitality.style.font_size = 18
	vitality.style.font_color = Color(0.92, 0.95, 1.0)
	vitality.style.align_h = StyleData.AlignH.LEFT
	vitality.style.align_v = StyleData.AlignV.TOP
	root.add(vitality)

	var souls := UIText.new(HudId.SOULS, "souls")
	souls.position = Vector2(VITALITY_BAR_POSITION.x, VITALITY_BAR_POSITION.y + VITALITY_BAR_SIZE.y + 30.0)
	souls.size = Vector2(VITALITY_BAR_SIZE.x, 22.0)
	souls.style.font_size = 18
	souls.style.font_color = Color(0.92, 0.95, 1.0)
	souls.style.align_h = StyleData.AlignH.LEFT
	souls.style.align_v = StyleData.AlignV.TOP
	root.add(souls)

	var alert := UIText.new(HudId.ALERT, "alert")
	alert.position = Vector2(VITALITY_BAR_POSITION.x, VITALITY_BAR_POSITION.y + VITALITY_BAR_SIZE.y + 54.0)
	alert.size = Vector2(VITALITY_BAR_SIZE.x, 22.0)
	alert.style.font_size = 16
	alert.style.font_color = Color(1.0, 0.62, 0.32)
	alert.style.align_h = StyleData.AlignH.LEFT
	alert.style.align_v = StyleData.AlignV.TOP
	root.add(alert)

	return root


## Returns the HUD element with the given identifier, or null.
static func find_id(element: UIElement, id: int) -> UIElement:
	if element.id == id:
		return element
	for child in element.get_children():
		var found := find_id(child, id)
		if found != null:
			return found
	return null


## Creates an inert rectangle: a button with no text and no action, so it is
## never focusable or activatable but still renders its surface. border_build
## adds a thin outline when supplied and different from transparent.
static func _rect(id: int, name: String, position: Vector2, size: Vector2, color: Color, border: Color = Color.TRANSPARENT) -> UIButton:
	var rect := UIButton.new(id, name)
	rect.position = position
	rect.size = size
	rect.style.color = color
	if not border.is_equal_approx(Color.TRANSPARENT):
		rect.style.border_color = border
		rect.style.border_width = 1.0
	return rect