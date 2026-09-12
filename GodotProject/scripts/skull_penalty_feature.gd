extends Node2D

# Persistent coin-sized skull penalty hazards. Each skull behaves independently and
# remains in play until the boat hits it or a whirlpool pulls it into the core.
const SKULL_RADIUS := 17.0
const SKULL_GRACE := 1.0
const SKULL_PENALTY := 500
# The 500-point coin has weight 3 out of 100. Skull spawn chance is twice that rate.
const SKULL_SPAWN_CHANCE := 0.06
const POPUP_LIFE := 0.90
const BURST_LIFE := 0.55

var skulls: Array[Dictionary] = []
var last_coins_collected := 0
var popups: Array[Dictionary] = []
var bursts: Array[Dictionary] = []
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
		skulls.clear()
		popups.clear()
		bursts.clear()
		last_coins_collected = 0
		queue_redraw()
		return
	if bool(g.game_over):
		queue_redraw()
		return

	var collected: int = int(g.coins_collected)
	if collected < last_coins_collected:
		skulls.clear()
		popups.clear()
		bursts.clear()
	if collected > last_coins_collected:
		for _i in range(collected - last_coins_collected):
			if randf() < SKULL_SPAWN_CHANCE:
				_spawn_skull(g)
	last_coins_collected = collected

	# Update each skull independently. They persist indefinitely unless collected or swallowed.
	for i in range(skulls.size() - 1, -1, -1):
		var skull: Dictionary = skulls[i]
		skull["age"] = float(skull.get("age", 0.0)) + delta
		var p: Vector2 = skull.get("pos", Vector2.ZERO) as Vector2

		# Whirlpool interaction mirrors the game's pull concept: skulls begin moving from
		# across the field, accelerate strongly near the whirlpool, and disappear in its core.
		if bool(g.whirlpool.get("active", false)):
			var wpos: Vector2 = g.whirlpool.get("pos", Vector2.ZERO) as Vector2
			var offset: Vector2 = wpos - p
			var dist: float = maxf(0.01, offset.length())
			if dist < float(g.WHIRLPOOL_CORE) + SKULL_RADIUS * 0.35:
				skulls.remove_at(i)
				continue
			var field_range: float = maxf(1.0, get_viewport_rect().size.length())
			var proximity: float = clampf(1.0 - dist / field_range, 0.04, 1.0)
			var pull_speed: float = 14.0 + 180.0 * proximity * proximity
			p += offset / dist * pull_speed * delta
			skull["pos"] = p

		if float(skull.get("age", 0.0)) >= SKULL_GRACE:
			if g.boat_pos.distance_to(p) < float(g.BOAT_RADIUS) + SKULL_RADIUS:
				_hit_skull(g, p)
				skulls.remove_at(i)

	for i in range(popups.size() - 1, -1, -1):
		popups[i]["life"] = float(popups[i].get("life", 0.0)) - delta
		if float(popups[i].get("life", 0.0)) <= 0.0:
			popups.remove_at(i)
	for i in range(bursts.size() - 1, -1, -1):
		bursts[i]["life"] = float(bursts[i].get("life", 0.0)) - delta
		if float(bursts[i].get("life", 0.0)) <= 0.0:
			bursts.remove_at(i)
	queue_redraw()

func _spawn_skull(g: Node) -> void:
	var size := get_viewport_rect().size
	var p := Vector2(
		randf_range(float(g.FIELD_INSET_SIDE) + 28.0, size.x - float(g.FIELD_INSET_SIDE) - 28.0),
		randf_range(float(g.FIELD_INSET_TOP) + 28.0, size.y - float(g.FIELD_INSET_BOTTOM) - 28.0)
	)
	skulls.append({"pos": p, "age": 0.0})

func _hit_skull(g: Node, p: Vector2) -> void:
	g.score = maxi(0, int(g.score) - SKULL_PENALTY)
	if g.has_method("_refresh_hud"):
		g.call("_refresh_hud")
	popups.append({"pos": p, "life": POPUP_LIFE})
	bursts.append({"pos": p, "life": BURST_LIFE})
	damage_player.stop()
	damage_player.play()

func _draw() -> void:
	for skull in skulls:
		_draw_skull(skull.get("pos", Vector2.ZERO))
	for burst in bursts:
		_draw_bad_burst(burst)
	for popup in popups:
		_draw_penalty_popup(popup)

func _draw_skull(p: Vector2) -> void:
	# Coin-sized white skull with subtle depth: drop shadow, shaded rim and upper-left highlight.
	var outline := Color("222831")
	var deep_shadow := Color(0.08, 0.10, 0.13, 0.38)
	var rim_shadow := Color("aeb5bc")
	var white := Color("f4f5f2")
	var highlight := Color("ffffff")
	var socket := Color("333941")
	var nose_shadow := Color("8e969e")

	draw_circle(p + Vector2(2.4, 1.6), 14.3, deep_shadow)
	draw_rect(Rect2(p + Vector2(-5.5, 9.0), Vector2(14.0, 6.0)), deep_shadow, true)
	draw_circle(p + Vector2(0, -2), 14.0, outline)
	draw_circle(p + Vector2(0.8, -1.0), 12.0, rim_shadow)
	draw_circle(p + Vector2(-0.8, -2.8), 11.2, white)
	draw_circle(p + Vector2(-4.2, -6.0), 6.0, highlight)
	draw_rect(Rect2(p + Vector2(-8, 7), Vector2(16, 7)), outline, true)
	draw_rect(Rect2(p + Vector2(-6.5, 7.7), Vector2(13, 5.2)), rim_shadow, true)
	draw_rect(Rect2(p + Vector2(-6.0, 7.2), Vector2(11.5, 4.1)), white, true)
	draw_circle(p + Vector2(-4.6, -1.6), 3.5, socket)
	draw_circle(p + Vector2(5.2, -1.6), 3.5, socket)
	draw_circle(p + Vector2(-5.4, -2.4), 1.0, Color(0.10, 0.12, 0.14, 0.9))
	draw_circle(p + Vector2(4.4, -2.4), 1.0, Color(0.10, 0.12, 0.14, 0.9))
	var nose := PackedVector2Array([p + Vector2(0, 1), p + Vector2(-2.3, 5), p + Vector2(2.3, 5)])
	draw_colored_polygon(nose, nose_shadow)
	for x in [-4.0, 0.0, 4.0]:
		draw_line(p + Vector2(x, 8), p + Vector2(x, 12), outline, 1.0, true)
	draw_arc(p + Vector2(-1.5, 0.0), 8.5, PI * 1.03, PI * 1.55, 8, Color(1, 1, 1, 0.72), 1.1, true)

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
