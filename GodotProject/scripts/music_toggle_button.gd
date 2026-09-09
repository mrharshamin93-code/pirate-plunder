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
	# Keep all geometry on a square, integer-aligned grid so the icon does not
	# look stretched or soft on high-DPI/mobile rendering.
	var center: Vector2 = Vector2(round(size.x * 0.5), round(size.y * 0.5))
	var gold: Color = Color("f4c64d")
	var grey: Color = Color("9aa3a8")

	# Crisp flat eighth-note: one solid color, no shadow/glow layers.
	var head: Vector2 = center + Vector2(-5.0, 6.0)
	draw_circle(head, 5.0, gold)
	draw_rect(Rect2(center.x - 1.5, center.y - 10.0, 3.0, 16.0), gold)
	var flag: PackedVector2Array = PackedVector2Array([
		Vector2(center.x + 1.0, center.y - 10.0),
		Vector2(center.x + 10.0, center.y - 7.0),
		Vector2(center.x + 8.0, center.y - 3.0),
		Vector2(center.x + 1.0, center.y - 6.0)
	])
	draw_colored_polygon(flag, gold)

	if not music_enabled:
		# Flat grey prohibition overlay, matching the selected sample style.
		draw_arc(center, 13.0, 0.0, TAU, 48, grey, 2.5, false)
		draw_line(center + Vector2(-9.0, -9.0), center + Vector2(9.0, 9.0), grey, 2.8, false)
