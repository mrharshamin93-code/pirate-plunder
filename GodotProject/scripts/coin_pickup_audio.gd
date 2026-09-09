extends Node

# Common coin pickup SFX are generated in-engine.
# 500 and 1000 use the authored sounds the user selected and previewed.
const SAMPLE_RATE: int = 44100
const DEFAULT_DURATION: float = 0.34
const RICH_500_STREAM: AudioStream = preload("res://assets/audio/coin_500_rich_sample_3.ogg")
const JACKPOT_1000_STREAM: AudioStream = preload("res://assets/audio/coin_1000_STRONG_jackpot_4.ogg")

var pickup_player: AudioStreamPlayer
var default_stream: AudioStreamWAV
var last_score: int = 0
var tracked_game: Node = null

func _ready() -> void:
	default_stream = _build_default_stream()

	pickup_player = AudioStreamPlayer.new()
	pickup_player.name = "CoinPickupSFX"
	pickup_player.volume_db = -2.0
	pickup_player.stream = default_stream
	add_child(pickup_player)

	tracked_game = get_parent()
	last_score = _read_score()
	set_physics_process(true)

func _read_score() -> int:
	if tracked_game == null or not is_instance_valid(tracked_game):
		return 0
	var score_value: Variant = tracked_game.get("score")
	if score_value == null:
		return 0
	if score_value is int:
		return score_value as int
	if score_value is float:
		return int(score_value as float)
	return 0

func _physics_process(_delta: float) -> void:
	if tracked_game == null or not is_instance_valid(tracked_game):
		tracked_game = get_parent()
		last_score = _read_score()
		return

	var current_score: int = _read_score()
	var started_value: Variant = tracked_game.get("game_started")
	var game_started: bool = started_value is bool and (started_value as bool)

	if current_score < last_score:
		last_score = current_score
		return

	var gained: int = current_score - last_score
	if game_started and gained > 0:
		_play_pickup(gained)

	last_score = current_score

func _play_pickup(points: int) -> void:
	if pickup_player.playing:
		pickup_player.stop()

	if points == 500:
		pickup_player.stream = RICH_500_STREAM
		pickup_player.volume_db = 0.0
	elif points == 1000:
		pickup_player.stream = JACKPOT_1000_STREAM
		pickup_player.volume_db = 0.0
	else:
		pickup_player.stream = default_stream
		pickup_player.volume_db = -2.0

	pickup_player.play()

func _envelope(t: float, attack: float, decay: float) -> float:
	if t < 0.0:
		return 0.0
	var a: float = minf(1.0, t / maxf(0.001, attack))
	return a * exp(-decay * t)

func _tone(t: float, freq: float, amp: float, start: float, decay: float) -> float:
	var local_t: float = t - start
	if local_t < 0.0:
		return 0.0
	return amp * _envelope(local_t, 0.003, decay) * sin(TAU * freq * local_t)

func _default_sample(t: float) -> float:
	var value: float = 0.34 * _envelope(t, 0.004, 18.0) * (sin(TAU * 840.0 * t) + 0.30 * sin(TAU * 1680.0 * t))
	value += _tone(t, 1260.0, 0.22, 0.06, 22.0)
	value += _tone(t, 2100.0, 0.15, 0.12, 25.0)
	return value

func _build_default_stream() -> AudioStreamWAV:
	var sample_count: int = int(round(DEFAULT_DURATION * SAMPLE_RATE))
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(sample_count * 2)

	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var sample: float = tanh(_default_sample(t) * 1.35)
		var value: int = clampi(int(round(sample * 30000.0)), -32768, 32767)
		pcm[i * 2] = value & 0xff
		pcm[i * 2 + 1] = (value >> 8) & 0xff

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream
