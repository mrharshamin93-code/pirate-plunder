extends "res://scripts/optimized_game_visuals.gd"

const MINE_FILES := ["standard","rusty","camo","danger","ice","gold","skull","electric","lava","void"]

func _ready() -> void:
	super._ready()
	_apply_selected_mine_texture()

func _apply_selected_mine_texture() -> void:
	var index := 0
	if BoatCollectibles != null:
		index = clampi(int(BoatCollectibles.selected_mine), 0, MINE_FILES.size() - 1)
	var selected_path := "res://assets/mines/%s.svg" % MINE_FILES[index]
	var selected_texture := load(selected_path) as Texture2D
	if selected_texture != null:
		mine_texture = selected_texture
