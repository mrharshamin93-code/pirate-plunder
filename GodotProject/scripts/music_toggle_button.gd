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
	var gold_dark: Color = Color("9b6b16")
	var grey: Color = Color("9aa3a8")
	var grey_dark: Color = Color("4d565b")

	# Flat-style musical note: no background badge or outer ring when enabled.
	var head_center: Vector2 = center + Vector2(-5.0, 6.0)
	draw_circle(head_center + Vector2(1.0, 1.2), 5.8, Color(gold_dark, 0.55))
	draw_circle(head_center, 5.1, gold)
	draw_line(center + Vector2(0.0, 5.0), center + Vector2(0.0, -10.5), gold_dark, 4.8, true)
	draw_line(center + Vector2(0.0, 5.0), center + Vector2(0.0, -10.5), gold, 3.0, true)
	var flag: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -10.5),
		center + Vector2(10.0, -8.0),
		center + Vector2(8.5, -3.0),
		center + Vector2(0.0, -5.5)
	])
	draw_colored_polygon(flag, gold)

	if not music_enabled:
		# Grey cigarette/no-smoking style overlay over the flat gold note.
		draw_arc(center, 14.0, 0.0, TAU, 36, grey_dark, 4.4, true)
		draw_arc(center, 14.0, 0.0, TAU, 36, grey, 2.8, true)
		draw_line(center + Vector2(-10.2, -10.2), center + Vector2(10.2, 10.2), grey_dark, 5.0, true)
		draw_line(center + Vector2(-10.2, -10.2), center + Vector2(10.2, 10.2), grey, 3.0, true)
