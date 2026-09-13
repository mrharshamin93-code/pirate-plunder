extends "res://scripts/boat_collectibles_v2.gd"

var exact_mine_sheet: Texture2D

func _process(_delta: float) -> void:
	# Ship unlocks are based only on personal high score for now.
	pass

func _save_collectibles() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("boats", "selected", selected)
	cfg.set_value("mines", "selected", selected_mine)
	cfg.save(SAVE)

func _is_unlocked(index: int) -> bool:
	if index <= 0:
		return true
	if index >= NAMES.size():
		return false
	return _personal_best() >= int(SCORE_UNLOCKS[index])

func get_total_coins() -> int:
	return 0

func _load_exact_mine_sheet() -> Texture2D:
	var encoded := ""
	for i in range(8):
		var path := "res://assets/mines/exact_sheet/chunk%02d.txt" % i
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return null
		encoded += file.get_as_text().strip_edges()
	var raw := Marshalls.base64_to_raw(encoded)
	var image := Image.new()
	if image.load_png_from_buffer(raw) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _mine_texture(index: int) -> Texture2D:
	if index < 0 or index >= MINE_FILES.size():
		return null
	if mine_textures[index] != null:
		return mine_textures[index]
	if exact_mine_sheet == null:
		exact_mine_sheet = _load_exact_mine_sheet()
	if exact_mine_sheet == null:
		return super._mine_texture(index)
	var atlas := AtlasTexture.new()
	atlas.atlas = exact_mine_sheet
	var col := index % 5
	var row := int(index / 5)
	atlas.region = Rect2(col * 128, row * 128, 128, 128)
	mine_textures[index] = atlas
	return atlas

func _refresh() -> void:
	super._refresh()
	if active_tab == "ships" and sub_label != null and not _is_unlocked(preview):
		sub_label.text = "LOCKED — Reach high score %s" % _comma(int(SCORE_UNLOCKS[preview]))
