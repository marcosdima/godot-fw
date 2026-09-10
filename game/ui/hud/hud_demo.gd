extends Node
class_name HudDemo


## Identifier of the vitality attribute this demo manages.
const VITALITY_ID := 1

## Health ceiling of the demo target; the bar fills from this value.
const VITALITY_MAX := 20.0

## Duration of the damage flash on the bar in seconds.
const FLASH_DURATION := 0.15

## Opacity target of the damage flash playback.
const FLASH_ALPHA := 0.25

## Seconds between two automatic beats of the live scene.
var beat_seconds := 1.0


## The world in which the demo target lives.
var _world: World = null

## The demo entity whose state the HUD renders.
var _entity: Entity = null

## The HUD element tree built and written by this demo.
var _hud: UIElement = null

## The host this demo is attached to, or null.
var _host: UIHost = null

## The vitality fill captured after building the tree.
var _bar_fill: UIButton = null

## True while the last beat damaged the target, waiting for sync to dispatch the flash.
var _damaged := false

## True while a damage flash playback is registered on the host.
var _flashing := false

## Elapsed seconds since the last processed beat.
var _time_left := 0.0

## Souls collected so far.
var _souls := 0

## Beats advanced since the demo started.
var _beat := 0


## Builds the demo fixture: a world, a target entity with a vitality attribute
## and the HUD element tree. Nothing here touches Godot nodes.
func _init() -> void:
	_world = World.new()
	_entity = _world.spawn("HudTarget")
	var vitality := Attribute.new(VITALITY_ID, "Vitality", VITALITY_MAX, 0.0)
	_entity.modules.status.get_status().add_attribute(vitality)
	_hud = UIHud.build()
	_bar_fill = UIHud.find_id(_hud, UIHud.HudId.VITALITY_FILL) as UIButton


## Attaches the HUD to a parent UIHost. The host materializes the overlay; the
## demo stays the owner and writer of the tree.
func _ready() -> void:
	var host := get_parent()
	if host is UIHost:
		_host = host as UIHost
		_host.set_hud(_hud)
	sync()


## Advances the HUD once per beat when the scene is run live. Tests drive step()
## manually with set_process(false).
func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left > 0.0:
		return
	step()
	_time_left = beat_seconds


## Advances the demo by one deterministic beat: damage or heal the vitality,
## count a soul and refresh the HUD. Cycle: -4, +5, -12, +3.
func step() -> void:
	_beat += 1
	_souls += 1
	match (_beat - 1) % 4:
		0:
			_modify_vitality(-4.0)
			_alert("Hit!")
		1:
			_modify_vitality(5.0)
			_alert("Healed")
		2:
			_modify_vitality(-12.0)
			_alert("Big hit!")
		_:
			_modify_vitality(3.0)
			_alert("Healed")
	sync()


## Pushes the vitality value through the status module and clamps it to the
## 0..VITALITY_MAX range. A negative delta marks this beat as damage.
func _modify_vitality(delta: float) -> void:
	var attribute := _entity.modules.status.get_status().get_attribute(VITALITY_ID)
	if attribute == null:
		return
	attribute.current_value = clampf(attribute.current_value + delta, attribute.min_value, VITALITY_MAX)
	if delta < 0.0:
		_damaged = true


## Writes the alert line of the HUD.
func _alert(message: String) -> void:
	var alert := UIHud.find_id(_hud, UIHud.HudId.ALERT) as UIText
	if alert != null:
		alert.text = message


## Maps the current entity state into the HUD element tree and dispatches a
## damage flash when the last beat damaged the target. Writing the bar fill
## width and the texts is effective-only: unchanged values emit nothing.
func sync() -> void:
	if _hud == null:
		return
	var attribute := _entity.modules.status.get_status().get_attribute(VITALITY_ID)
	var vitality := attribute.current_value if attribute != null else 0.0
	var fraction := clampf(vitality / VITALITY_MAX, 0.0, 1.0)
	var vitality_text := UIHud.find_id(_hud, UIHud.HudId.VITALITY_TEXT) as UIText
	vitality_text.text = "%d/%d" % [int(round(vitality)), int(VITALITY_MAX)]
	_bar_fill.size = Vector2(UIHud.VITALITY_BAR_SIZE.x * fraction, UIHud.VITALITY_BAR_SIZE.y)
	var souls := UIHud.find_id(_hud, UIHud.HudId.SOULS) as UIText
	souls.text = "Souls: %d" % _souls
	if _damaged:
		_damaged = false
		_flash_damage()


## Runs a one-shot opacity dip on the vitality fill through the animation
## system. The model modulate stays at 1.0 during playback; the finished and
## stopped handlers clear the color back to opaque after the frame's tick.
func _flash_damage() -> void:
	if _flashing or _host == null:
		return
	var adapter := _host.get_hud_adapter()
	if adapter == null:
		return
	var fade := UIAnimationDefinition.new()
	fade.duration = FLASH_DURATION
	fade.easing = UIAnimationDefinition.Easing.EASE_OUT
	fade.add_track(&"modulate", FLASH_ALPHA)
	var playback := UIAnimationPlayback.new(_bar_fill, fade)
	playback.finished.connect(_on_flash_finished)
	playback.stopped.connect(_on_flash_finished)
	adapter.add_playback(playback)
	_flashing = true


## Marks the flash over and schedules the opaque restore after the current
## frame's playback tick applied the final dimmed frame.
func _on_flash_finished() -> void:
	_flashing = false
	restore_after_flash.call_deferred()


## Forces the surfaced fill back to opaque. The model modulate never left 1.0,
## so the restore is a view-side poke: the playback's last frame applied the
## dimmed color and nothing else will resync it.
func restore_after_flash() -> void:
	if _host == null:
		return
	var adapter := _host.get_hud_adapter()
	if adapter == null:
		return
	var control := adapter.get_control(_bar_fill)
	if control != null:
		control.modulate = Color.WHITE


## Returns the HUD element tree this demo drives.
func get_hud() -> UIElement:
	return _hud


## Returns the current vitality of the demo target.
func get_vitality() -> float:
	var attribute := _entity.modules.status.get_status().get_attribute(VITALITY_ID)
	return attribute.current_value if attribute != null else 0.0


## Returns the number of souls collected so far.
func get_souls() -> int:
	return _souls