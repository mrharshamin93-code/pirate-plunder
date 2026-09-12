extends "res://scripts/player_profile_settings.gd"

func _build_settings_view() -> void:
	_clear_overlay()
	var outer := _build_shell("SETTINGS")

	var section := Label.new()
	section.text = "GAMEPLAY MUSIC"
	section.position = Vector2(28, 120)
	section.size = Vector2(294, 32)
	section.add_theme_font_size_override("font_size", 18)
	section.add_theme_color_override("font_color", Color("fff1c4"))
	outer.add_child(section)

	var desc := Label.new()
	desc.text = "Turn the sea-shanty music on or off during gameplay."
	desc.position = Vector2(28, 154)
	desc.size = Vector2(294, 52)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color("d9f4fb"))
	outer.add_child(desc)

	var music_button := _make_button(
		"MUSIC: ON" if _music_enabled() else "MUSIC: OFF",
		Vector2(72, 230),
		Vector2(246, 54),
		Callable(self, "_toggle_music"),
		true
	)
	music_button.name = "GameplayMusicToggle"

	# Keep this button close to the music control and remove the separate
	# PLAYER heading so no text sits behind or overlaps the button.
	_make_button(
		"PROFILE & STATS",
		Vector2(72, 320),
		Vector2(246, 54),
		Callable(self, "_open_profile_deferred"),
		false
	)

	_make_button(
		"BACK",
		Vector2(72, 650),
		Vector2(246, 50),
		Callable(self, "_close_overlay"),
		false
	)
