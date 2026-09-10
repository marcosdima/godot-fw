extends RefCounted
class_name AgentSettings


## Resolutions offered by the settings screen, in display order.
const RESOLUTIONS: Array[String] = ["1280×720", "1920×1080", "2560×1440"]


## Master volume in percent, from 0 to 100.
var volume := 60

## Whether the game runs fullscreen.
var fullscreen := false

## Index into RESOLUTIONS of the active resolution.
var resolution := 0


## Adds the given delta to the volume, clamped to the 0..100 range.
func step_volume(delta: int) -> void:
	volume = clampi(volume + delta, 0, 100)


## Flips the fullscreen flag.
func toggle_fullscreen() -> void:
	fullscreen = not fullscreen


## Advances the active resolution, wrapping around the offered list.
func cycle_resolution() -> void:
	resolution = (resolution + 1) % RESOLUTIONS.size()


## Returns the text of the active resolution.
func get_resolution_text() -> String:
	return RESOLUTIONS[resolution]