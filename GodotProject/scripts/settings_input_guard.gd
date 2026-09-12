extends Node

var guarding: bool = false
var guarded_menu: Control = null

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	var settings := get_node_or_null("/root/PlayerProfileSettings")
	if settings == null:
		return
	var overlay_value: Variant = settings.get("overlay")
	var overlay := overlay_value as Control
	var is_open: bool = overlay != null and is_instance_valid(overlay) and overlay.visible

	if is_open:
		if not guarding:
			guarding = true
			# The autoload's raw _input handler was swallowing the same mouse/touch
			# events that the settings Buttons need. Once the overlay is open, let
			# Godot's normal Control GUI routing own those events instead.
			settings.set_process_input(false)
			var menu_value: Variant = settings.get("menu_root")
			guarded_menu = menu_value as Control
			if guarded_menu != null and is_instance_valid(guarded_menu):
				# main_menu.gd also listens to raw _input for Set Sail, so block that
				# path while Settings/Profile is covering the menu.
				guarded_menu.set("starting_game", true)
		return

	if guarding:
		guarding = false
		settings.set_process_input(true)
		if guarded_menu != null and is_instance_valid(guarded_menu):
			guarded_menu.set("starting_game", false)
		guarded_menu = null
