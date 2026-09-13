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
	if selected_mine_texture != null:
		var draw_size := Vector2(40.0, 40.0)
		draw_texture_rect(selected_mine_texture, Rect2(p - draw_size * 0.5, draw_size), false)
	else:
		super._draw_mine(m)
