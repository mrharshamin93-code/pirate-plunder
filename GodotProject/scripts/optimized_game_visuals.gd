extends "res://scripts/current_game_visuals.gd"

# The original mine is built from many polygons/arcs every frame. With up to
# nine moving mines that creates a lot of CanvasItem draw calls in the editor
# and on lower-end phones. Render the same mine artwork once as an SVG texture
# and draw one texture per mine instead.
var mine_texture: Texture2D

func _ready() -> void:
	super._ready()
	mine_texture = load("res://assets/mine-sprite.svg") as Texture2D

func _draw_mine(m: Dictionary) -> void:
	var p: Vector2 = m.get("pos", Vector2.ZERO)
	if mine_texture != null:
		var draw_size := Vector2(36.0, 36.0)
		draw_texture_rect(mine_texture, Rect2(p - draw_size * 0.5, draw_size), false)
	else:
		# Safe fallback if the asset ever fails to import.
		super._draw_mine(m)
