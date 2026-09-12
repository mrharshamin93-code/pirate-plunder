extends "res://scripts/boat_collectibles_v2.gd"

func _process(_delta: float) -> void:
	# Ship unlocks are based only on personal high score for now.
	pass

func _save_collectibles() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("boats", "selected", selected)
	cfg.save(SAVE)

func _is_unlocked(index: int) -> bool:
	if index <= 0:
		return true
	if index >= NAMES.size():
		return false
	return _personal_best() >= int(SCORE_UNLOCKS[index])

func get_total_coins() -> int:
	return 0

func _refresh() -> void:
	super._refresh()
	if sub_label != null and not _is_unlocked(preview):
		sub_label.text = "LOCKED — Reach high score %s" % _comma(int(SCORE_UNLOCKS[preview]))
