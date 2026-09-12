extends Node2D

# Coin-sized skull penalty obstacle.
# It is intentionally independent of whirlpool physics, so whirlpools never move or consume it.
const SKULL_RADIUS := 17.0
const SKULL_LIFE := 30.0
const SKULL_GRACE := 1.0
const SKULL_PENALTY := 500
# The 500-point coin has weight 3 out of 100. The skull should appear twice as often,
# so use a 6% spawn chance per collected coin.
const SKULL_SPAWN_CHANCE := 0.06
const POPUP_LIFE := 0.90
const BURST_LIFE := 0.55

var skull: Dictionary = {"active": false}
var last_coins_collected := 0
var popup: Dictionary = {}
var burst: Dictionary = {}
var damage_player: AudioStreamPlayer
var damage_stream: AudioStreamWAV

func _ready() -> void:
	z_index = 6
	damage_stream = _make_damage_sound()
	damage_player = AudioStreamPlayer.new()
	damage_player.stream = damage_stream
	damage_player.volume_db = -1.0
	add_child(damage_player)

func _process(delta: float) -> void:
	var g = get_tree().current_scene
	if g == null or not ("game_started" in g) or not bool(g.game_started):
		skull = {"active": false}
		popup.clear()
		burst.clear()
		last_coins_collected = 0
		queue_redraw()
		return
	if bool(g.game_over):
		queue_redraw()
		return

	var collected: int = int(g.coins_collected)
	if collected < last_coins_collected:
		skull = {"active": false}
		popup.clear()
		burst.clear()
	if collected > last_coins_collected:
		for _i in range(collected - last_coins_collected):
			if not bool(skull.get("active", false)) and randf() < SKULL_SPAWN_CHANCE:
				_spawn_skull(g)
	last_coins_collected = collected

	if bool(skull.get("active", false)):
		skull["age"] = float(skull.get("age", 0.0)) + delta
		skull["life"] = float(skull.get("life", SKULL_LIFE)) - delta
		if float(skull.life) <= 0.0:
			skull["active"] = false
		elif float(skull.age) >= SKULL_GRACE:
			var p: Vector2 = skull.get("pos", Vector2.ZERO)
			if g.boat_pos.distance_to(p) < float(g.BOAT_RADIUS) + SKULL_RADIUS:
				_hit_skull(g, p)

	if not popup.is_empty():
		popup["life"] = float(popup.get("life", 0.0)) - delta
		if float(popup.life) <= 0.0:
			popup.clear()
	if not burst.is_empty():
		burst["life"] = float(burst.get("life", 0.0)) - delta
		if float(burst.life) <= 0.0:
			burst.clear()
	queue_redraw()

func _spawn_skull(g: Node) -> void:
	var size := get_viewport_rect().size
	var p := Vector2(
		randf_range(float(g.FIELD_INSET_SIDE) + 28.0, size.x - float(g.FIELD_INSET_SIDE) - 28.0),
		randf_range(float(g.FIELD_INSET_TOP) + 28.0, size.y - float(g.FIELD_INSET_BOTTOM) - 28.0)
	)
	skull = {"active": true, "pos": p, "age": 0.0, "life": SKULL_LIFE}

func _hit_skull(g: Node, p: Vector2) -> void:
	skull["active"] = false
	g.score = maxi(0, int(g.score) - SKULL_PENALTY)
	if g.has_method("_refresh_hud"):
		g.call("_refresh_hud")
	popup = {"pos": p, "life": POPUP_LIFE}
	burst = {"pos": p, "life": BURST_LIFE}
	damage_player.stop()
	damage_player.play()

func _draw() -> void:
	if bool(skull.get("active", false)):
		_draw_skull(skull.get("pos", Vector2.ZERO))
	if not burst.is_empty():
		_draw_bad_burst(burst)
	if not popup.is_empty():
		_draw_penalty_popup(popup)

func _draw_skull(p: Vector2) -> void:
	# Approximately the same 34px footprint as a gameplay coin, with no crossed bones.
	# White skull with a dark outline for readability against the ocean.
	var outline := Color("2b3138")
	var white := Color("f7f7f2")
	var highlight := Color("ffffff")
	var shadow := Color("c9ced3")
	draw_circle(p + Vector2(0, -2), 14.0, outline)
	draw_circle(p + Vector2(0, -2), 12.0, white)
	draw_circle(p + Vector2(-3, -5), 8.0, highlight)
	# Jaw
	draw_rect(Rect2(p + Vector2(-8, 7), Vector2(16, 7)), outline, true)
	draw_rect(Rect2(p + Vector2(-6, 7), Vector2(12, 5)), white, true)
	# Eye sockets and nose
	draw_circle(p + Vector2(-5, -2), 3.4, outline)
	draw_circle(p + Vector2(5, -2), 3.4, outline)
	var nose := PackedVector2Array([p + Vector2(0, 1), p + Vector2(-2.2, 5), p + Vector2(2.2, 5)])
	draw_colored_polygon(nose, shadow)
	# Teeth divisions
	for x in [-4.0, 0.0, 4.0]:
		draw_line(p + Vector2(x, 8), p + Vector2(x, 12), outline, 1.0, true)

func _draw_bad_burst(b: Dictionary) -> void:
	var life: float = float(b.get("life", 0.0))
	var t := 1.0 - clampf(life / BURST_LIFE, 0.0, 1.0)
	var fade := 1.0 - t
	var p: Vector2 = b.get("pos", Vector2.ZERO)
	for i in range(12):
		var a := float(i) / 12.0 * TAU
		var inner := 8.0 + t * 5.0
		var outer := 18.0 + t * 31.0
		var c := Color(0.95, 0.08 if i % 2 == 0 else 0.20, 0.05, fade)
		draw_line(p + Vector2.from_angle(a) * inner, p + Vector2.from_angle(a) * outer, c, 2.2, true)
	for i in range(10):
		var a := float(i) / 10.0 * TAU + 0.22
		draw_circle(p + Vector2.from_angle(a) * (10.0 + 28.0 * t), 2.2 * fade + 0.4, Color(0.55, 0.02, 0.02, fade))

func _draw_penalty_popup(v: Dictionary) -> void:
	var life: float = float(v.get("life", 0.0))
	var t := 1.0 - clampf(life / POPUP_LIFE, 0.0, 1.0)
	var p: Vector2 = v.get("pos", Vector2.ZERO) + Vector2(0, -22.0 - 22.0 * t)
	var alpha := clampf(life / 0.28, 0.0, 1.0)
	var font := ThemeDB.fallback_font
	var text := "-500"
	var fs := 25
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, p + Vector2(-width * 0.5 + 1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.15, 0.0, 0.0, alpha))
	draw_string(font, p + Vector2(-width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.08, 0.05, alpha))

func _make_damage_sound() -> AudioStreamWAV:
	# Original heavy retro damage cue (the approved Sound C direction), generated in-engine.
	var rate := 44100
	var duration := 0.48
	var frames := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for n in range(frames):
		var t := float(n) / float(rate)
		var x := t / duration
		var start_f := 660.0
		var end_f := 105.0
		var f := start_f * pow(end_f / start_f, x)
		var phase := TAU * f * t
		var env := minf(1.0, t / 0.0025) * exp(-4.5 * x)
		var square := 1.0 if sin(phase) >= 0.0 else -1.0
		var tone := (0.48 * square + 0.30 * sin(phase) + 0.12 * sin(2.0 * phase)) * env
		var snap := rng.randf_range(-1.0, 1.0) * exp(-65.0 * t) * 0.30
		var low := 0.24 * sin(TAU * 95.0 * t) * exp(-8.0 * t)
		var sample := clampf((tone + snap + low) * 0.72, -1.0, 1.0)
		bytes.encode_s16(n * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream
