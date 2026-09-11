extends "res://scripts/main_menu.gd"

# Mobile-safe menu layout. Keep the original menu art and behavior, but make
# text sizing/placement responsive so labels never run past the phone edges.
func _layout_ui() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return

	var sx: float = w / 390.0
	var sy: float = h / 844.0
	var ui_scale: float = minf(sx, sy)
	var y_scale: float = minf(1.0, sy)

	# Remove desktop-width forced line breaks and let Godot wrap to the actual
	# phone width. This prevents the right-hand side of sentences being clipped.
	var story: Label = get_node_or_null("Story") as Label
	if story:
		story.text = "You are Captain Marlow, rowing through the wreckage of Blackwake Harbor. Salvage the treasure and stay clear of the homing mines fired from the Dreadwake."
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		story.clip_text = false
		story.add_theme_font_size_override("font_size", maxi(12, int(round(14.0 * ui_scale))))

	var instructions: Label = get_node_or_null("Instructions") as Label
	if instructions:
		instructions.text = "Push the thumbstick to point her where you want to go — she holds her line and answers the helm quickly. Every coin you take sends another mine after you."
		instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instructions.clip_text = false
		instructions.add_theme_font_size_override("font_size", maxi(11, int(round(13.0 * ui_scale))))

	var title: Label = get_node_or_null("GameTitle") as Label
	if title:
		title.clip_text = false
		title.add_theme_font_size_override("font_size", maxi(30, int(round(42.0 * ui_scale))))

	var coin_title: Label = get_node_or_null("CoinTitle") as Label
	if coin_title:
		coin_title.add_theme_font_size_override("font_size", maxi(11, int(round(13.0 * ui_scale))))

	var best_title: Label = get_node_or_null("BestTitle") as Label
	if best_title:
		best_title.add_theme_font_size_override("font_size", maxi(11, int(round(13.0 * ui_scale))))

	var best_score: Label = get_node_or_null("BestScore") as Label
	if best_score:
		best_score.add_theme_font_size_override("font_size", maxi(25, int(round(31.0 * ui_scale))))

	for i in range(COIN_VALUES.size()):
		var value_label: Label = get_node_or_null("CoinValue%d" % i) as Label
		if value_label:
			value_label.add_theme_font_size_override("font_size", maxi(10, int(round(12.0 * ui_scale))))

	# Scale the vertical layout on shorter Android viewports while preserving the
	# original 390x844 composition on full-height devices.
	_set_rect("GameTitle", Vector2(12.0 * sx, 258.0 * y_scale), Vector2(w - 24.0 * sx, 58.0 * y_scale))
	_set_rect("Story", Vector2(16.0 * sx, 316.0 * y_scale), Vector2(w - 32.0 * sx, 98.0 * y_scale))
	_set_rect("CoinTitle", Vector2(20.0 * sx, 438.0 * y_scale), Vector2(w - 40.0 * sx, 24.0 * y_scale))

	var coin_left: float = 18.0 * sx
	var coin_width: float = w - 36.0 * sx
	var slot: float = coin_width / 7.0
	for i in range(COIN_VALUES.size()):
		_set_rect("CoinValue%d" % i, Vector2(coin_left + slot * float(i), 512.0 * y_scale), Vector2(slot, 22.0 * y_scale))

	_set_rect("Instructions", Vector2(14.0 * sx, 554.0 * y_scale), Vector2(w - 28.0 * sx, 102.0 * y_scale))
	_set_rect("BestTitle", Vector2(80.0 * sx, 674.0 * y_scale), Vector2(w - 160.0 * sx, 26.0 * y_scale))
	_set_rect("BestScore", Vector2(80.0 * sx, 704.0 * y_scale), Vector2(w - 160.0 * sx, 50.0 * y_scale))

	if play_button:
		play_button.add_theme_font_size_override("font_size", maxi(17, int(round(20.0 * ui_scale))))
		play_button.position = Vector2(28.0 * sx, minf(h - 70.0, 780.0 * y_scale))
		play_button.size = Vector2(w - 56.0 * sx, minf(58.0, 58.0 * y_scale))
