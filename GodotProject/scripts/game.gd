extends Node2D

const BOAT_RADIUS := 8.0
const TURN_RATE := 9.0
const TURN_AT_SPEED := 0.28
const THRUST := 620.0
const DRAG := 3.6
const LATERAL_GRIP := 11.0
const MAX_SPEED := 190.0
const COIN_RADIUS := 13.0
const COIN_MIN_DISTANCE := 90.0
const MINE_RADIUS := 8.0
const MINE_SPIKE_RADIUS := 11.0
const MAX_MINES := 9
const MINE_FAR_SPEED := 22.0
const MINE_NEAR_SPEED := 100.0
const MINE_FAR_RANGE := 400.0
const MINE_NEAR_RANGE := 40.0
const MINE_WANDER := 0.42
const MINE_ARM_TIME := 0.55
const WHIRLPOOL_CHANCE := 0.13
const WHIRLPOOL_RANGE := 140.0
const WHIRLPOOL_CORE := 12.0
const WHIRLPOOL_PULL := 260.0
const WHIRLPOOL_MINE_PULL := 2.6
const WHIRLPOOL_LIFE := 6.5
const WHIRLPOOL_MIN_DISTANCE := 110.0
const FIELD_INSET_TOP := 106.0
const FIELD_INSET_BOTTOM := 158.0
const FIELD_INSET_SIDE := 8.0
const WAKE_LIFE := 0.72
const WAKE_MIN_SPEED := 22.0
const WAKE_INTERVAL := 0.055

const COIN_POINTS := [10, 25, 50, 100, 250, 500, 1000]
const COIN_WEIGHTS := [38, 26, 17, 10, 5, 3, 1]
const COIN_COLORS := [
	Color("d5a535"), Color("dcae3c"), Color("e4b945"),
	Color("edc550"), Color("f2cf5b"), Color("f6d96b"), Color("ffe07a")
]

@onready var joystick: SemiDynamicJoystick = $CanvasLayer/Joystick
@onready var score_label: Label = $CanvasLayer/HUD/Score
@onready var coin_label: Label = $CanvasLayer/HUD/CoinCount
@onready var mine_label: Label = $CanvasLayer/HUD/MineCount
@onready var sunk_panel: Control = $CanvasLayer/SunkPanel
@onready var sunk_score: Label = $CanvasLayer/SunkPanel/Score

var boat_pos := Vector2.ZERO
var boat_vel := Vector2.ZERO
var boat_angle := -PI / 2.0
var input_vector := Vector2.ZERO
var score := 0
var coins_collected := 0
var active_mine_count := 0
var coin := {"active": false, "pos": Vector2.ZERO, "tier": 0, "phase": 0.0}
var mines: Array[Dictionary] = []
var wakes: Array[Dictionary] = []
var whirlpool := {"active": false, "pos": Vector2.ZERO, "life": 0.0, "spin": 0.0}
var wake_timer := 0.0
var game_over := false

func _ready() -> void:
	joystick.changed.connect(_on_joystick_changed)
	$CanvasLayer/SunkPanel/PlayAgain.pressed.connect(_start_game)
	_start_game()

func _start_game() -> void:
	var viewport_size := get_viewport_rect().size
	boat_pos = viewport_size * 0.5
	boat_vel = Vector2.ZERO
	boat_angle = -PI / 2.0
	input_vector = Vector2.ZERO
	score = 0
	coins_collected = 0
	active_mine_count = 0
	mines.clear()
	wakes.clear()
	whirlpool = {"active": false, "pos": Vector2.ZERO, "life": 0.0, "spin": 0.0}
	wake_timer = 0.0
	game_over = false
	sunk_panel.visible = false
	_place_coin()
	_refresh_hud()
	queue_redraw()

func _on_joystick_changed(value: Vector2) -> void:
	input_vector = value

func _physics_process(delta: float) -> void:
	if game_over:
		_update_wakes(delta)
		queue_redraw()
		return

	var dt := minf(delta, 0.05)
	_update_boat(dt)
	_update_coin(dt)
	_update_mines(dt)
	_update_whirlpool(dt)
	_update_wakes(dt)
	_check_collisions()
	queue_redraw()

func _update_boat(dt: float) -> void:
	var speed := boat_vel.length()
	var speed_frac := minf(1.0, speed / MAX_SPEED)
	var magnitude := input_vector.length()
	if magnitude > 0.0:
		var target := atan2(input_vector.y, input_vector.x)
		var diff := wrapf(target - boat_angle, -PI, PI)
		var rate := TURN_RATE * (1.0 - TURN_AT_SPEED * speed_frac) * dt
		boat_angle += diff if absf(diff) <= rate else signf(diff) * rate
		boat_vel += Vector2(cos(boat_angle), sin(boat_angle)) * THRUST * magnitude * dt

	var forward := Vector2(cos(boat_angle), sin(boat_angle))
	var along := boat_vel.dot(forward)
	var side := boat_vel - forward * along
	boat_vel = forward * along * exp(-DRAG * dt) + side * exp(-LATERAL_GRIP * dt)

	if whirlpool.active:
		var offset: Vector2 = whirlpool.pos - boat_pos
		var dist := maxf(0.01, offset.length())
		if dist < WHIRLPOOL_CORE:
			_end_game()
			return
		elif dist < WHIRLPOOL_RANGE:
			var pull := (1.0 - dist / WHIRLPOOL_RANGE) * WHIRLPOOL_PULL * dt
			var inward := offset / dist
			var tangent := Vector2(-inward.y, inward.x)
			boat_vel += inward * pull + tangent * pull * 0.45

	boat_vel = boat_vel.limit_length(MAX_SPEED)
	boat_pos += boat_vel * dt
	var size := get_viewport_rect().size
	boat_pos.x = clampf(boat_pos.x, FIELD_INSET_SIDE + BOAT_RADIUS, size.x - FIELD_INSET_SIDE - BOAT_RADIUS)
	boat_pos.y = clampf(boat_pos.y, FIELD_INSET_TOP + BOAT_RADIUS, size.y - FIELD_INSET_BOTTOM - BOAT_RADIUS)

	wake_timer -= dt
	if boat_vel.length() >= WAKE_MIN_SPEED and wake_timer <= 0.0:
		wake_timer = WAKE_INTERVAL
		var stern := boat_pos - forward * 18.0
		wakes.append({"pos": stern, "angle": boat_angle, "life": WAKE_LIFE})
		if wakes.size() > 24:
			wakes.pop_front()

func _update_coin(dt: float) -> void:
	coin.phase += dt * 4.0

func _update_mines(dt: float) -> void:
	for mine in mines:
		if not mine.active:
			continue
		mine.arm -= dt
		var delta_vec: Vector2 = boat_pos - mine.pos
		var dist := maxf(0.01, delta_vec.length())
		var dir := delta_vec / dist
		var t := clampf(inverse_lerp(MINE_FAR_RANGE, MINE_NEAR_RANGE, dist), 0.0, 1.0)
		var speed := lerpf(MINE_FAR_SPEED, MINE_NEAR_SPEED, t)
		mine.phase += dt * 2.4
		var tangent := Vector2(-dir.y, dir.x)
		var velocity := dir * speed + tangent * sin(mine.phase) * speed * MINE_WANDER

		if whirlpool.active:
			var woff: Vector2 = whirlpool.pos - mine.pos
			var wd := maxf(0.01, woff.length())
			if wd < WHIRLPOOL_CORE:
				mine.active = false
				active_mine_count = maxi(0, active_mine_count - 1)
				continue
			elif wd < WHIRLPOOL_RANGE:
				var pull := (1.0 - wd / WHIRLPOOL_RANGE) * WHIRLPOOL_PULL * WHIRLPOOL_MINE_PULL
				velocity += woff.normalized() * pull
		mine.pos += velocity * dt

func _update_whirlpool(dt: float) -> void:
	if not whirlpool.active:
		return
	whirlpool.life -= dt
	whirlpool.spin += dt * 2.4
	if whirlpool.life <= 0.0:
		whirlpool.active = false

func _update_wakes(dt: float) -> void:
	for wake in wakes:
		wake.life -= dt
	for i in range(wakes.size() - 1, -1, -1):
		if wakes[i].life <= 0.0:
			wakes.remove_at(i)

func _check_collisions() -> void:
	if coin.active and boat_pos.distance_to(coin.pos) < BOAT_RADIUS + COIN_RADIUS:
		_collect_coin()

	for mine in mines:
		if mine.active and mine.arm <= 0.0 and boat_pos.distance_to(mine.pos) < BOAT_RADIUS + MINE_RADIUS:
			_end_game()
			return

	for i in range(mines.size()):
		var a := mines[i]
		if not a.active or a.arm > 0.0:
			continue
		for j in range(i + 1, mines.size()):
			var b := mines[j]
			if not b.active or b.arm > 0.0:
				continue
			if a.pos.distance_to(b.pos) < MINE_SPIKE_RADIUS * 2.0:
				a.active = false
				b.active = false
				active_mine_count = maxi(0, active_mine_count - 2)

func _collect_coin() -> void:
	var tier: int = coin.tier
	score += COIN_POINTS[tier]
	coins_collected += 1
	coin.active = false
	_spawn_mine()
	if randf() < WHIRLPOOL_CHANCE:
		_spawn_whirlpool()
	_place_coin()
	_refresh_hud()

func _place_coin() -> void:
	coin = {"active": true, "pos": _spawn_point(COIN_MIN_DISTANCE), "tier": _pick_coin_tier(), "phase": 0.0}

func _spawn_mine() -> void:
	if active_mine_count >= MAX_MINES:
		return
	for mine in mines:
		if not mine.active:
			mine.active = true
			mine.pos = _spawn_point(46.0)
			mine.arm = MINE_ARM_TIME
			mine.phase = randf() * TAU
			active_mine_count += 1
			return
	mines.append({"active": true, "pos": _spawn_point(46.0), "arm": MINE_ARM_TIME, "phase": randf() * TAU})
	active_mine_count += 1

func _spawn_whirlpool() -> void:
	whirlpool = {"active": true, "pos": _spawn_point(WHIRLPOOL_MIN_DISTANCE), "life": WHIRLPOOL_LIFE, "spin": 0.0}

func _spawn_point(min_distance: float) -> Vector2:
	var size := get_viewport_rect().size
	var p := Vector2.ZERO
	for _i in range(24):
		p = Vector2(
			randf_range(FIELD_INSET_SIDE + 28.0, size.x - FIELD_INSET_SIDE - 28.0),
			randf_range(FIELD_INSET_TOP + 28.0, size.y - FIELD_INSET_BOTTOM - 28.0)
		)
		if p.distance_to(boat_pos) >= min_distance:
			break
	return p

func _pick_coin_tier() -> int:
	var total := 0
	for weight in COIN_WEIGHTS:
		total += weight
	var roll := randi_range(0, total - 1)
	var cumulative := 0
	for i in range(COIN_WEIGHTS.size()):
		cumulative += COIN_WEIGHTS[i]
		if roll < cumulative:
			return i
	return 0

func _end_game() -> void:
	if game_over:
		return
	game_over = true
	sunk_score.text = "Score: %s" % _comma(score)
	sunk_panel.visible = true

func _refresh_hud() -> void:
	score_label.text = _comma(score)
	coin_label.text = str(coins_collected)
	mine_label.text = "%d/%d" % [active_mine_count, MAX_MINES]

func _comma(value: int) -> String:
	var s := str(value)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _draw() -> void:
	_draw_ocean()
	for wake in wakes:
		_draw_wake(wake)
	if whirlpool.active:
		_draw_whirlpool()
	if coin.active:
		_draw_coin()
	for mine in mines:
		if mine.active:
			_draw_mine(mine)
	if not game_over:
		_draw_boat()

func _draw_ocean() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("125a6e"))
	for y in range(80, int(size.y), 90):
		for x in range(25, int(size.x), 110):
			var pts := PackedVector2Array([Vector2(x, y), Vector2(x + 18, y - 3), Vector2(x + 36, y)])
			draw_polyline(pts, Color(0.31, 0.71, 0.80, 0.18), 2.0)

func _draw_boat() -> void:
	var forward := Vector2(cos(boat_angle), sin(boat_angle))
	var side := Vector2(-forward.y, forward.x)
	var nose := boat_pos + forward * 18.0
	var rear := boat_pos - forward * 16.0
	var poly := PackedVector2Array([nose, rear + side * 10.0, rear - side * 10.0])
	draw_colored_polygon(poly, Color("9a6231"))
	draw_polyline(PackedVector2Array([nose, rear + side * 10.0, rear - side * 10.0, nose]), Color("0a1a20"), 2.0)
	draw_circle(boat_pos - forward * 3.0, 5.5, Color("57a94a"))
	draw_circle(boat_pos - forward * 5.0 - side * 2.0, 5.7, Color("c8322f"))

func _draw_coin() -> void:
	var pulse := 1.0 + sin(coin.phase) * 0.06
	var r := COIN_RADIUS * pulse
	draw_circle(coin.pos, r, COIN_COLORS[coin.tier])
	draw_circle(coin.pos, r * 0.72, Color(1.0, 0.86, 0.35, 0.30))
	draw_arc(coin.pos, r, 0.0, TAU, 30, Color("6b3f1c"), 2.0)

func _draw_mine(mine: Dictionary) -> void:
	var p: Vector2 = mine.pos
	for i in range(10):
		var a := float(i) / 10.0 * TAU
		var dir := Vector2(cos(a), sin(a))
		draw_line(p + dir * 7.0, p + dir * 12.0, Color("25292e"), 3.0)
	draw_circle(p, 8.0, Color("25292e"))
	draw_circle(p + Vector2(0, -3), 2.0, Color("ffd24a"))

func _draw_wake(wake: Dictionary) -> void:
	var alpha := clampf(wake.life / WAKE_LIFE, 0.0, 1.0) * 0.65
	var dir := Vector2(cos(wake.angle), sin(wake.angle))
	var side := Vector2(-dir.y, dir.x)
	var p: Vector2 = wake.pos
	draw_line(p - side * 7.0, p + side * 7.0, Color(0.85, 0.96, 0.98, alpha), 2.0)

func _draw_whirlpool() -> void:
	var p: Vector2 = whirlpool.pos
	var life_alpha := clampf(minf(WHIRLPOOL_LIFE - whirlpool.life, whirlpool.life) / 0.5, 0.0, 1.0)
	for i in range(7):
		var radius := 18.0 + i * 8.0
		var start := whirlpool.spin + i * 0.7
		draw_arc(p, radius, start, start + PI * 1.35, 32, Color(0.75, 0.95, 1.0, (0.34 - i * 0.025) * life_alpha), 3.0)
	draw_circle(p, 8.0, Color(0.01, 0.03, 0.04, 0.95 * life_alpha))
