extends "res://scripts/player_profile_settings.gd"

func _build_settings_view() -> void:
	_clear_overlay()
	_build_shell("SETTINGS")

	var music_button := _make_button(
		"MUSIC: ON" if _music_enabled() else "MUSIC: OFF",
		Vector2(72, 135),
		Vector2(246, 54),
		Callable(self, "_toggle_music"),
		true
	)
	music_button.name = "GameplayMusicToggle"

	_make_button(
		"PROFILE & STATS",
		Vector2(72, 210),
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

# Rebuild immediately from the button's pressed signal. The settings overlay
# stays in place, so there is no underlying main-menu click to guard against.
# The old deferred rebuild could leave the old profile controls alive for the
# rest of the input frame, which made BACK TO SETTINGS appear to need 2 clicks.
func _back_to_settings_deferred() -> void:
	_build_settings_view()
