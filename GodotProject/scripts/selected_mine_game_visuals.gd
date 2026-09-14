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

# Gentle animated surface ripples around each moving mine. These are deliberately
# low-alpha and narrow so they read as water displacement rather than an effect ring.
func _draw_mine_water_waves(m: Dictionary, p: Vector2) -> void:
	var phase: float = float(m.get("phase", 0.0))
	var arm: float = float(m.get("arm", 0.0))
	var movement_strength: float = 0.55 if arm > 0.5 else 1.0

	# Two soft expanding ripple bands, offset so the water always feels alive.
	for band in range(2):
		var cycle: float = fposmod(phase * 0.18 + float(band) * 0.5, 1.0)
		var radius: float = lerpf(18.0, 29.0, cycle)
		var fade: float = (1.0 - cycle) * movement_strength
		var wave_color := Color(0.82, 0.96, 1.0, 0.11 * fade)
		draw_arc(p, radius, 0.15, TAU - 0.35, 30, wave_color, 1.15, true)

	# Small broken highlights close to the mine keep the ripple organic and subtle.
	var shimmer: float = 0.5 + 0.5 * sin(phase * 1.35)
	var highlight_alpha: float = (0.055 + shimmer * 0.035) * movement_strength
	for segment in range(3):
		var start_angle: float = phase * 0.12 + float(segment) * TAU / 3.0
		draw_arc(
			p,
			16.5 + shimmer * 1.2,
			start_angle,
			start_angle + 0.72,
			8,
			Color(0.92, 0.985, 1.0, highlight_alpha),
			1.0,
			true
		)
