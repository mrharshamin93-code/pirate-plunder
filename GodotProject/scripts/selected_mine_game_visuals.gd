extends "res://scripts/optimized_game_visuals.gd"

var selected_mine_texture: Texture2D
var selected_mine_index := -1

# Short-lived world-space wake points for each mine. These stay where they were
# created, so the water effect forms a small path instead of following the mine.
const MINE_WAKE_LIFE := 0.95
const MINE_WAKE_SPACING := 6.0
const MINE_WAKE_MAX_POINTS := 10
var mine_wakes: Array = []
var mine_last_positions: Array[Vector2] = []

func _refresh_selected_mine_texture() -> void:
	var idx := BoatCollectibles.get_selected_mine_index()
	if idx != selected_mine_index or selected_mine_texture == null:
		selected_mine_index = idx
		selected_mine_texture = BoatCollectibles.get_selected_mine_texture()

func _process(delta: float) -> void:
	super._process(delta)
	_update_mine_wakes(delta)

func _update_mine_wakes(delta: float) -> void:
	var g = get_parent()
	var mine_count: int = g.mines.size()

	while mine_wakes.size() < mine_count:
		mine_wakes.append([])
		mine_last_positions.append(Vector2.ZERO)

	for i in range(mine_count):
		var mine: Dictionary = g.mines[i]
		var trail: Array = mine_wakes[i]

		for mark in trail:
			mark["life"] = float(mark.get("life", 0.0)) - delta
		for j in range(trail.size() - 1, -1, -1):
			if float(trail[j].get("life", 0.0)) <= 0.0:
				trail.remove_at(j)

		if not bool(mine.get("active", false)):
			mine_last_positions[i] = Vector2.ZERO
			continue

		var p: Vector2 = mine.get("pos", Vector2.ZERO)
		var previous: Vector2 = mine_last_positions[i]
		if previous == Vector2.ZERO:
			mine_last_positions[i] = p
			continue

		if p.distance_to(previous) >= MINE_WAKE_SPACING:
			var travel: Vector2 = p - previous
			trail.append({
				"pos": previous,
				"dir": travel.normalized(),
				"life": MINE_WAKE_LIFE
			})
			while trail.size() > MINE_WAKE_MAX_POINTS:
				trail.pop_front()
			mine_last_positions[i] = p

	queue_redraw()

func _draw_mine(m: Dictionary) -> void:
	_refresh_selected_mine_texture()
	var p: Vector2 = m.get("pos", Vector2.ZERO)
	var mine_index: int = _find_mine_index(m)
	if mine_index >= 0:
		_draw_mine_wake_path(mine_index)
	if selected_mine_texture != null:
		var draw_size := Vector2(40.0, 40.0)
		draw_texture_rect(selected_mine_texture, Rect2(p - draw_size * 0.5, draw_size), false)
	else:
		super._draw_mine(m)

func _find_mine_index(m: Dictionary) -> int:
	var g = get_parent()
	for i in range(g.mines.size()):
		if g.mines[i] == m:
			return i
	return -1

func _draw_mine_wake_path(index: int) -> void:
	if index < 0 or index >= mine_wakes.size():
		return
	var trail: Array = mine_wakes[index]
	for mark in trail:
		var life_ratio: float = clampf(float(mark.get("life", 0.0)) / MINE_WAKE_LIFE, 0.0, 1.0)
		var p: Vector2 = mark.get("pos", Vector2.ZERO)
		var dir: Vector2 = mark.get("dir", Vector2.RIGHT)
		if dir.length_squared() < 0.001:
			dir = Vector2.RIGHT
		var side := Vector2(-dir.y, dir.x)
		var age: float = 1.0 - life_ratio

		# Longer, slightly stronger wake shoulders. They remain world-space marks,
		# so the result is a visible trail behind the moving mine, not a halo.
		var spread: float = 5.5 + age * 5.0
		var length: float = 13.0 + age * 7.0
		var alpha: float = 0.30 * life_ratio
		for side_sign in [-1.0, 1.0]:
			var center: Vector2 = p + side * spread * side_sign
			var a0: Vector2 = center - dir * length * 0.52
			var a1: Vector2 = center + dir * length * 0.48
			draw_line(a0, a1, Color(0.86, 0.97, 1.0, alpha), 1.35, true)

		if age < 0.78:
			var foam_alpha: float = 0.19 * life_ratio
			draw_line(
				p - dir * 3.0,
				p + dir * 5.0,
				Color(0.94, 0.99, 1.0, foam_alpha),
				1.0,
				true
			)
