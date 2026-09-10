extends Node

const DEATH_SOUND: AudioStream = preload("res://assets/audio/death_3_retro_arcade_failure.wav")

var _player: AudioStreamPlayer
var _tracked_scene: Node = null
var _was_game_over: bool = false

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "DeathSequencePlayer"
	_player.stream = DEATH_SOUND
	_player.volume_db = -1.0
	add_child(_player)

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.has_method("_end_game"):
		_tracked_scene = scene
		_was_game_over = false
		return

	if scene != _tracked_scene:
		_tracked_scene = scene
		_was_game_over = bool(scene.get("game_over"))
		return

	var is_game_over: bool = bool(scene.get("game_over"))
	if is_game_over and not _was_game_over:
		_play_death_sound()
	_was_game_over = is_game_over

func _play_death_sound() -> void:
	# This only fires when the player's game_over state transitions to true.
	# Mine-to-mine and mine-to-whirlpool explosions remain silent.
	if _player == null:
		return
	_player.stop()
	_player.play()
