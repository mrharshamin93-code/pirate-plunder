extends "res://scripts/current_game_visuals.gd"

# Cached mine art keeps mine rendering cheap on mobile.
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
		super._draw_mine(m)

func _draw_boat(p: Vector2, a: float) -> void:
	var idx: int = BoatCollectibles.get_selected_index()
	if idx == 0:
		super._draw_boat(p, a)
		return
	var hull_colors := [Color("9a6231"),Color("9f1f24"),Color("15191f"),Color("d9b65c"),Color("537d7b"),Color("5a2118"),Color("087e78"),Color("c58b14")]
	var sail_colors := [Color("f3e5c0"),Color("d52b2f"),Color("24262c"),Color("f7f0d8"),Color("b8d4cc"),Color("e94a1b"),Color("13a69b"),Color("f7e7b0")]
	var accent_colors := [Color("c8322f"),Color("ffd05a"),Color("bd1f2d"),Color("e3b62d"),Color("8ef4df"),Color("ff8a24"),Color("e8c44d"),Color("ffd34f")]
	var s: float = 0.54
	var hull := PackedVector2Array()
	for v in [Vector2(32,0),Vector2(20,-13),Vector2(-16,-14),Vector2(-27,-8),Vector2(-30,0),Vector2(-27,8),Vector2(-16,14),Vector2(20,13)]:
		hull.append(_rot(v,a,p,s))
	draw_colored_polygon(hull, hull_colors[idx])
	draw_polyline(PackedVector2Array([hull[0],hull[1],hull[2],hull[3],hull[4],hull[5],hull[6],hull[7],hull[0]]), Color("07151b"), 2.0, true)
	# Mast and two top-down sails make each collectible read as a pirate ship while staying the same gameplay size.
	draw_line(_rot(Vector2(-10,0),a,p,s), _rot(Vector2(20,0),a,p,s), Color("5b351c"), 2.2, true)
	var sail1 := PackedVector2Array([_rot(Vector2(11,-2),a,p,s),_rot(Vector2(7,-12),a,p,s),_rot(Vector2(-8,-10),a,p,s),_rot(Vector2(-10,-2),a,p,s)])
	var sail2 := PackedVector2Array([_rot(Vector2(11,2),a,p,s),_rot(Vector2(7,12),a,p,s),_rot(Vector2(-8,10),a,p,s),_rot(Vector2(-10,2),a,p,s)])
	draw_colored_polygon(sail1, sail_colors[idx])
	draw_colored_polygon(sail2, sail_colors[idx])
	draw_polyline(PackedVector2Array([sail1[0],sail1[1],sail1[2],sail1[3],sail1[0]]), Color("07151b"), 1.2, true)
	draw_polyline(PackedVector2Array([sail2[0],sail2[1],sail2[2],sail2[3],sail2[0]]), Color("07151b"), 1.2, true)
	draw_circle(_rot(Vector2(-18,0),a,p,s), 3.2, accent_colors[idx])
	# Distinctive rare-skin accent.
	if idx == 4:
		draw_arc(p, 18.0, 0.0, TAU, 24, Color(0.45,1.0,0.9,0.35), 1.5, true)
	elif idx == 5:
		draw_circle(_rot(Vector2(25,0),a,p,s), 2.5, Color("ffb126"))
	elif idx == 7:
		draw_arc(p, 17.0, 0.0, TAU, 24, Color(1.0,0.82,0.2,0.28), 1.5, true)
