extends "res://scripts/optimized_game_visuals.gd"

var selected_mine_texture: Texture2D
var selected_mine_index := -1

func _refresh_selected_mine_texture() -> void:
	var idx := BoatCollectibles.get_selected_mine_index()
	if idx != selected_mine_index or selected_mine_texture == null:
		selected_mine_index = idx
		selected_mine_texture = BoatCollectibles.get_selected_mine_texture()

func _draw_mine(m: Dictionary) -> void:
	_refresh_selected_mine_texture()
	var p: Vector2 = m.get("pos", Vector2.ZERO)
	_draw_mine_water_waves(m, p)
	if selected_mine_texture != null:
		var draw_size := Vector2(40.0, 40.0)
		draw_texture_rect(selected_mine_texture, Rect2(p - draw_size * 0.5, draw_size), false)
	else:
		super._draw_mine(m)

# Gentle but clearly visible animated water displacement around moving mines.
# Broken arcs keep it looking like natural waves instead of a UI ring.
func _draw_mine_water_waves(m: Dictionary, p: Vector2) -> void:
	var phase: float = float(m.get("phase", 0.0))
	var arm: float = float(m.get("arm", 0.0))
	var movement_strength: float = 0.62 if arm > 0.5 else 1.0

	# Three expanding bands with staggered timing so there is always a visible ripple.
	for band in range(3):
		var cycle: float = fposmod(phase * 0.16 + float(band) / 3.0, 1.0)
		var radius: float = lerpf(18.0, 36.0, cycle)
		var fade: float = pow(1.0 - cycle, 0.8) * movement_strength
		var alpha: float = 0.22 * fade
		for segment in range(4):
			var start_angle: float = phase * 0.055 + float(segment) * TAU / 4.0 + float(band) * 0.16
			var end_angle: float = start_angle + 0.92
			draw_arc(p, radius, start_angle, end_angle, 10, Color(0.82, 0.96, 1.0, alpha), 1.35, true)

	# A soft near-mine disturbance makes movement readable even between outer ripples.
	var shimmer: float = 0.5 + 0.5 * sin(phase * 1.45)
	for i in range(3):
		var a: float = phase * 0.10 + float(i) * TAU / 3.0
		var offset := Vector2(cos(a), sin(a)) * (14.0 + shimmer * 1.5)
		var center := p + offset
		draw_arc(center, 5.0 + shimmer, a - 1.0, a + 0.85, 7, Color(0.90, 0.985, 1.0, 0.15 * movement_strength), 1.15, true)
