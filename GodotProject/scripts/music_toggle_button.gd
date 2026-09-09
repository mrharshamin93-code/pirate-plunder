extends Button

var music_enabled: bool = true

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var gold: Color = Color("f4c64d")
	var dark: Color = Color("0a1a20")
	var red: Color = Color("d84a3a")

	# Musical note, drawn directly so it stays clean and monochrome.
	var head_center: Vector2 = center + Vector2(-4.0, 6.0)
	draw_circle(head_center + Vector2(1.2, 1.4), 6.1, dark)
	draw_circle(head_center, 5.2, gold)
	draw_line(center + Vector2(0.0, 5.0), center + Vector2(0.0, -10.0), dark, 5.0, true)
	draw_line(center + Vector2(0.0, 5.0), center + Vector2(0.0, -10.0), gold, 3.1, true)
	var flag: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -10.0),
		center + Vector2(10.0, -7.0),
		center + Vector2(8.0, -2.0),
		center + Vector2(0.0, -5.0)
	])
	draw_colored_polygon(flag, gold)
	draw_polyline(PackedVector2Array([flag[0], flag[1], flag[2], flag[3], flag[0]]), dark, 1.6, true)

	if not music_enabled:
		# No-smoking style overlay: red prohibition ring + diagonal slash over the note.
		draw_arc(center, 14.0, 0.0, TAU, 32, dark, 4.6, true)
		draw_arc(center, 14.0, 0.0, TAU, 32, red, 2.8, true)
		draw_line(center + Vector2(-10.0, -10.0), center + Vector2(10.0, 10.0), dark, 5.2, true)
		draw_line(center + Vector2(-10.0, -10.0), center + Vector2(10.0, 10.0), red, 3.0, true)
