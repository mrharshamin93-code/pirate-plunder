extends Node2D

signal explosion_requested(position: Vector2, scale: float)

const BOAT_RADIUS: float = 8.0
const TURN_RATE: float = 9.0
const TURN_AT_SPEED: float = 0.28
const THRUST: float = 620.0
const DRAG: float = 3.6
const LATERAL_GRIP: float = 11.0
const MAX_SPEED: float = 190.0
const COIN_RADIUS: float = 13.0
const COIN_MIN_DISTANCE: float = 90.0
const MINE_RADIUS: float = 8.0
const MINE_SPIKE_RADIUS: float = 15.5
const MAX_MINES: int = 9

const MINE_FAR_SPEED: float = 22.0
const MINE_NEAR_SPEED: float = 120.0
const MINE_FAR_RANGE: float = 400.0
const MINE_NEAR_RANGE: float = 40.0
const MINE_WANDER: float = 0.42
const MINE_ARM_TIME: float = 1.0

const WHIRLPOOL_CHANCE: float = 0.13
const WHIRLPOOL_CORE: float = 12.0
const WHIRLPOOL_PULL: float = 500.0
const WHIRLPOOL_MINE_PULL: float = 0.34
const WHIRLPOOL_MINE_MAX_SPEED: float = 105.0
const WHIRLPOOL_LIFE: float = 6.5
const WHIRLPOOL_MIN_DISTANCE: float = 110.0

const FIELD_INSET_TOP: float = 106.0
const FIELD_INSET_BOTTOM: float = 158.0
const FIELD_INSET_SIDE: float = 8.0
const WAKE_LIFE: float = 0.72
const WAKE_MIN_SPEED: float = 22.0
const WAKE_INTERVAL: float = 0.055

const COIN_POINTS: Array[int] = [10, 25, 50, 100, 250, 500, 1000]
const COIN_WEIGHTS: Array[int] = [38, 26, 17, 10, 5, 3, 1]

@onready var joystick: Control = $CanvasLayer/Joystick
@onready var score_label: Label = $CanvasLayer/HUD/Score
@onready var coin_label: Label = $CanvasLayer/HUD/CoinCount
@onready var mine_label: Label = $CanvasLayer/HUD/MineCount
@onready var sunk_panel: Control = $CanvasLayer/SunkPanel
@onready var sunk_score: Label = $CanvasLayer/SunkPanel/Score
@onready var play_again: Button = $CanvasLayer/SunkPanel/PlayAgain

var boat_pos: Vector2 = Vector2.ZERO
var boat_vel: Vector2 = Vector2.ZERO
var boat_angle: float = -PI / 2.0
var input_vector: Vector2 = Vector2.ZERO
var score: int = 0
var coins_collected: int = 0
var active_mine_count: int = 0
var coin: Dictionary = {}
var mines: Array[Dictionary] = []
var wakes: Array[Dictionary] = []
var whirlpool: Dictionary = {}
var wake_timer: float = 0.0
var game_over: bool = false
var game_started: bool = false

func _ready() -> void:
	randomize()
	joystick.connect("changed", Callable(self, "_on_joystick_changed"))
	if not play_again.pressed.is_connected(_start_game):
		play_again.pressed.connect(_start_game)
	_prepare_idle_state()

func _prepare_idle_state() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	boat_pos = viewport_size * 0.5
	boat_vel = Vector2.ZERO
	boat_angle = -PI / 2.0
	input_vector = Vector2.ZERO
	score = 0
	coins_collected = 0
	active_mine_count = 0
	mines.clear()
	wakes.clear()
	coin = {"active": false, "pos": Vector2.ZERO, "tier": 0, "phase": 0.0}
	whirlpool = {"active": false, "pos": Vector2.ZERO, "life": 0.0, "spin": 0.0}
	wake_timer = 0.0
	game_over = false
	game_started = false
	sunk_panel.visible = false
	_refresh_hud()

func _start_game() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	boat_pos = viewport_size * 0.5
	boat_vel = Vector2.ZERO
	boat_angle = -PI / 2.0
	input_vector = Vector2.ZERO
	score = 0
	coins_collected = 0
	active_mine_count = 0
	mines.clear()
	wakes.clear()
	coin = {"active": false, "pos": Vector2.ZERO, "tier": 0, "phase": 0.0}
	whirlpool = {"active": false, "pos": Vector2.ZERO, "life": 0.0, "spin": 0.0}
	wake_timer = 0.0
	game_over = false
	game_started = true
	sunk_panel.visible = false
	_place_coin()
	_refresh_hud()

func _on_joystick_changed(value: Vector2) -> void:
	if game_started and not game_over:
		input_vector = value

func _physics_process(delta: float) -> void:
	if not game_started:
		return
	var dt: float = minf(delta, 0.05)
	if game_over:
		_update_wakes(dt)
		return
	_update_boat(dt)
	_update_coin(dt)
	_update_mines(dt)
	_update_whirlpool(dt)
	_update_wakes(dt)
	_check_collisions()

func _update_boat(dt: float) -> void:
	var speed: float = boat_vel.length()
	var speed_frac: float = minf(1.0, speed / MAX_SPEED)
	var magnitude: float = input_vector.length()
	if magnitude > 0.0:
		var target: float = atan2(input_vector.y, input_vector.x)
		var diff: float = wrapf(target - boat_angle, -PI, PI)
		var rate: float = TURN_RATE * (1.0 - TURN_AT_SPEED * speed_frac) * dt
		if absf(diff) <= rate:
			boat_angle += diff
		else:
			boat_angle += signf(diff) * rate
		boat_vel += Vector2(cos(boat_angle), sin(boat_angle)) * THRUST * magnitude * dt

	var forward: Vector2 = Vector2(cos(boat_angle), sin(boat_angle))
	var along: float = boat_vel.dot(forward)
	var side: Vector2 = boat_vel - forward * along
	boat_vel = forward * along * exp(-DRAG * dt) + side * exp(-LATERAL_GRIP * dt)

	if bool(whirlpool.get("active", false)):
		var wpos: Vector2 = whirlpool.get("pos", Vector2.ZERO) as Vector2
		var offset: Vector2 = wpos - boat_pos
		var dist: float = maxf(0.01, offset.length())
		if dist < WHIRLPOOL_CORE:
			_end_game()
			return
		var viewport_size: Vector2 = get_viewport_rect().size
		var full_field_range: float = maxf(1.0, viewport_size.length())
		var proximity: float = clampf(1.0 - dist / full_field_range, 0.08, 1.0)
		var strength: float = 0.22 + 2.35 * proximity * proximity * proximity
		var pull: float = strength * WHIRLPOOL_PULL * dt
		var inward: Vector2 = offset / dist
		var tangent: Vector2 = Vector2(-inward.y, inward.x)
		boat_vel += inward * pull + tangent * pull * (0.16 + 0.22 * proximity)

	boat_vel = boat_vel.limit_length(MAX_SPEED)
	boat_pos += boat_vel * dt
	var size: Vector2 = get_viewport_rect().size
	boat_pos.x = clampf(boat_pos.x, FIELD_INSET_SIDE + BOAT_RADIUS, size.x - FIELD_INSET_SIDE - BOAT_RADIUS)
	boat_pos.y = clampf(boat_pos.y, FIELD_INSET_TOP + BOAT_RADIUS, size.y - FIELD_INSET_BOTTOM - BOAT_RADIUS)

	wake_timer -= dt
	if boat_vel.length() >= WAKE_MIN_SPEED and wake_timer <= 0.0:
		wake_timer = WAKE_INTERVAL
		var stern: Vector2 = boat_pos - forward * 18.0
		wakes.append({"pos": stern, "angle": boat_angle, "life": WAKE_LIFE})
		if wakes.size() > 24:
			wakes.pop_front()

func _update_coin(dt: float) -> void:
	coin["phase"] = float(coin.get("phase", 0.0)) + dt * 4.0

func _update_mines(dt: float) -> void:
	var field_size: Vector2 = get_viewport_rect().size
	var full_field_range: float = maxf(1.0, field_size.length())
	var min_x: float = FIELD_INSET_SIDE + MINE_SPIKE_RADIUS
	var max_x: float = field_size.x - FIELD_INSET_SIDE - MINE_SPIKE_RADIUS
	var min_y: float = FIELD_INSET_TOP + MINE_SPIKE_RADIUS
	var max_y: float = field_size.y - FIELD_INSET_BOTTOM - MINE_SPIKE_RADIUS
	for mine in mines:
		if not bool(mine.get("active", false)):
			continue
		mine["arm"] = float(mine.get("arm", 0.0)) - dt
		if float(mine.get("arm", 0.0)) > 0.0:
			continue
		var mine_pos: Vector2 = mine.get("pos", Vector2.ZERO) as Vector2
		var delta_vec: Vector2 = boat_pos - mine_pos
		var dist: float = maxf(0.01, delta_vec.length())
		var dir: Vector2 = delta_vec / dist
		var proximity: float = clampf(inverse_lerp(MINE_FAR_RANGE, MINE_NEAR_RANGE, dist), 0.0, 1.0)
		var close_boost: float = proximity * proximity
		var speed: float = lerpf(MINE_FAR_SPEED, MINE_NEAR_SPEED, close_boost)
		var phase: float = float(mine.get("phase", 0.0)) + dt * 2.4
		mine["phase"] = phase
		var tangent: Vector2 = Vector2(-dir.y, dir.x)
		var wander_strength: float = MINE_WANDER * (1.0 - 0.55 * proximity)
		var velocity: Vector2 = dir * speed + tangent * sin(phase) * speed * wander_strength

		if bool(whirlpool.get("active", false)):
			var wpos: Vector2 = whirlpool.get("pos", Vector2.ZERO) as Vector2
			var woff: Vector2 = wpos - mine_pos
			var wd: float = maxf(0.01, woff.length())
			if wd < WHIRLPOOL_CORE:
				mine["active"] = false
				active_mine_count = maxi(0, active_mine_count - 1)
				explosion_requested.emit(wpos, 1.0)
				_refresh_hud()
				continue
			var wp_proximity: float = clampf(1.0 - wd / full_field_range, 0.06, 1.0)
			var wp_strength: float = 0.10 + 1.15 * wp_proximity * wp_proximity
			var desired_pull: float = maxf(12.0, wp_strength * WHIRLPOOL_PULL * WHIRLPOOL_MINE_PULL)
			var wp_pull: float = minf(desired_pull, WHIRLPOOL_MINE_MAX_SPEED)
			var wp_dir: Vector2 = woff / wd
			velocity *= 1.0 - 0.52 * wp_proximity
			velocity += wp_dir * wp_pull

		var next_pos: Vector2 = mine_pos + velocity * dt
		var hit_x: bool = next_pos.x < min_x or next_pos.x > max_x
		var hit_y: bool = next_pos.y < min_y or next_pos.y > max_y
		next_pos.x = clampf(next_pos.x, min_x, max_x)
		next_pos.y = clampf(next_pos.y, min_y, max_y)
		if hit_x:
			mine["phase"] = float(mine.get("phase", 0.0)) + PI * 0.45
		if hit_y:
			mine["phase"] = float(mine.get("phase", 0.0)) - PI * 0.45
		mine["pos"] = next_pos

func _update_whirlpool(dt: float) -> void:
	if not bool(whirlpool.get("active", false)):
		return
	var life: float = float(whirlpool.get("life", 0.0)) - dt
	var spin: float = float(whirlpool.get("spin", 0.0)) + dt * 2.4
	whirlpool["life"] = life
	whirlpool["spin"] = spin
	if life <= 0.0:
		whirlpool["active"] = false

func _update_wakes(dt: float) -> void:
	for wake in wakes:
		wake["life"] = float(wake.get("life", 0.0)) - dt
	for i in range(wakes.size() - 1, -1, -1):
		if float(wakes[i].get("life", 0.0)) <= 0.0:
			wakes.remove_at(i)

func _check_collisions() -> void:
	if bool(coin.get("active", false)):
		var coin_pos: Vector2 = coin.get("pos", Vector2.ZERO) as Vector2
		if boat_pos.distance_to(coin_pos) < BOAT_RADIUS + COIN_RADIUS:
			_collect_coin()

	for mine in mines:
		if not bool(mine.get("active", false)):
			continue
		if float(mine.get("arm", 0.0)) > 0.0:
			continue
		var mine_pos: Vector2 = mine.get("pos", Vector2.ZERO) as Vector2
		if boat_pos.distance_to(mine_pos) < BOAT_RADIUS + MINE_RADIUS:
			mine["active"] = false
			active_mine_count = maxi(0, active_mine_count - 1)
			explosion_requested.emit(mine_pos, 1.25)
			_refresh_hud()
			_end_game(0.42)
			return

	for i in range(mines.size()):
		var a: Dictionary = mines[i]
		if not bool(a.get("active", false)):
			continue
		for j in range(i + 1, mines.size()):
			var b: Dictionary = mines[j]
			if not bool(b.get("active", false)):
				continue
			var apos: Vector2 = a.get("pos", Vector2.ZERO) as Vector2
			var bpos: Vector2 = b.get("pos", Vector2.ZERO) as Vector2
			if apos.distance_to(bpos) < MINE_SPIKE_RADIUS * 2.0:
				a["active"] = false
				b["active"] = false
				active_mine_count = maxi(0, active_mine_count - 2)
				explosion_requested.emit((apos + bpos) * 0.5, 1.0)
				_refresh_hud()

func _collect_coin() -> void:
	var tier: int = int(coin.get("tier", 0))
	score += COIN_POINTS[tier]
	coins_collected += 1
	coin["active"] = false
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
		if not bool(mine.get("active", false)):
			mine["active"] = true
			mine["pos"] = _spawn_point(46.0)
			mine["arm"] = MINE_ARM_TIME
			mine["phase"] = randf() * TAU
			active_mine_count += 1
			return
	mines.append({"active": true, "pos": _spawn_point(46.0), "arm": MINE_ARM_TIME, "phase": randf() * TAU})
	active_mine_count += 1

func _spawn_whirlpool() -> void:
	whirlpool = {"active": true, "pos": _spawn_point(WHIRLPOOL_MIN_DISTANCE), "life": WHIRLPOOL_LIFE, "spin": 0.0}

func _spawn_point(min_distance: float) -> Vector2:
	var size: Vector2 = get_viewport_rect().size
	var p: Vector2 = Vector2.ZERO
	for _i in range(24):
		p = Vector2(
			randf_range(FIELD_INSET_SIDE + 28.0, size.x - FIELD_INSET_SIDE - 28.0),
			randf_range(FIELD_INSET_TOP + 28.0, size.y - FIELD_INSET_BOTTOM - 28.0)
		)
		if p.distance_to(boat_pos) >= min_distance:
			break
	return p

func _pick_coin_tier() -> int:
	var total: int = 0
	for weight in COIN_WEIGHTS:
		total += weight
	var roll: int = randi_range(0, total - 1)
	var cumulative: int = 0
	for i in range(COIN_WEIGHTS.size()):
		cumulative += COIN_WEIGHTS[i]
		if roll < cumulative:
			return i
	return 0

func _end_game(panel_delay: float = 0.0) -> void:
	if game_over:
		return
	game_over = true
	input_vector = Vector2.ZERO
	sunk_score.text = "Score: %s" % _comma(score)
	if panel_delay > 0.0:
		await get_tree().create_timer(panel_delay).timeout
	if game_over:
		sunk_panel.visible = true

func _refresh_hud() -> void:
	score_label.text = _comma(score)
	coin_label.text = str(coins_collected)
	mine_label.text = "%d/%d" % [active_mine_count, MAX_MINES]

func _comma(value: int) -> String:
	var s: String = str(value)
	var out: String = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out