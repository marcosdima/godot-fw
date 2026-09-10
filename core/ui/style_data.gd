extends RefCounted
class_name StyleData


## Horizontal text alignment for elements that render text.
enum AlignH {
	LEFT,
	CENTER,
	RIGHT,
}

## Vertical text alignment for elements that render text.
enum AlignV {
	TOP,
	CENTER,
	BOTTOM,
}


## Foreground color of the element.
var color := Color.WHITE

## Foreground used for rendered text. Transparent means fall back to `color`,
## preserving the historical single-tint behavior.
var font_color := Color.TRANSPARENT

## Border color of the element. Transparent by default so no border renders.
var border_color := Color.TRANSPARENT

## Border width in pixels.
var border_width := 0.0

## Corner radius in pixels.
var border_radius := 0.0

## Color of the drop shadow behind the element. Transparent by default.
var shadow_color := Color.TRANSPARENT

## Offset size of the drop shadow in pixels.
var shadow_size := 0.0

## Font size in pixels for elements that render text. Zero means the default.
var font_size := 0

## Horizontal text alignment. Values come from AlignH.
var align_h := AlignH.CENTER

## Vertical text alignment. Values come from AlignV.
var align_v := AlignV.CENTER