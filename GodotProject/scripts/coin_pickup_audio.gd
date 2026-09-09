extends Node

# Coin pickup SFX are generated in-engine so they work in Godot exports.
# We detect the exact score increase in the physics tick; this avoids frame-order
# issues that could cause rare 500/1000 pickups to miss the special sound.
const SAMPLE_RATE: int = 44100
const DEFAULT_DURATION: float = 0.34
const RICH_500_DURATION: float = 0.95
const JACKPOT_1000_DURATION: float = 1.85

var pickup_player: AudioStreamPlayer
var default_stream: AudioStreamWAV
var rich_500_stream: AudioStreamWAV
var jackpot_1000_stream: AudioStreamWAV
var last_score: int = 0
var tracked_game: Node = null

func _ready() -> void:
	default_stream = _build_stream(0)
	rich_500_stream = _build_stream(500)
	jackpot_1000_stream = _build_stream(1000)

	pickup_player = AudioStreamPlayer.new()
	pickup_player.name = "CoinPickupSFX"
	pickup_player.volume_db = -2.0
	pickup_player.stream = default_stream
	add_child(pickup_player)

	tracked_game = get_parent()
	if tracked_game != null:
		last_score = int(tracked_game.get("score"))
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if tracked_game == null or not is_instance_valid(tracked_game):
		tracked_game = get_parent()
		if tracked_game != null:
			last_score = int(tracked_game.get("score"))
		return

	var current_score: int = int(tracked_game.get("score"))
	var game_started: bool = bool(tracked_game.get("game_started"))

	# A new game resets score to zero. Resync without playing anything.
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
		pickup_player.stream = rich_500_stream
		pickup_player.volume_db = 3.0
	elif points == 1000:
		pickup_player.stream = jackpot_1000_stream
		pickup_player.volume_db = 5.0
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

func _rich_500_sample(t: float) -> float:
	var value: float = 0.0
	value += _tone(t, 220.0, 0.34, 0.00, 5.0)
	value += _tone(t, 440.0, 0.34, 0.00, 5.8)
	value += _tone(t, 660.0, 0.28, 0.025, 6.2)
	value += _tone(t, 880.0, 0.24, 0.060, 6.8)
	value += _tone(t, 1320.0, 0.20, 0.100, 8.0)
	value += _tone(t, 1760.0, 0.16, 0.145, 9.0)
	value += _tone(t, 1046.5, 0.17, 0.20, 7.5)
	value += _tone(t, 1318.5, 0.16, 0.27, 8.0)
	value += _tone(t, 1568.0, 0.14, 0.34, 8.5)
	return value

func _jackpot_1000_sample(t: float) -> float:
	var value: float = 0.0
	value += _tone(t, 110.0, 0.46, 0.00, 2.8)
	value += _tone(t, 220.0, 0.34, 0.00, 3.5)
	value += _tone(t, 440.0, 0.35, 0.015, 4.0)
	value += _tone(t, 660.0, 0.31, 0.030, 4.1)
	value += _tone(t, 880.0, 0.28, 0.045, 4.3)
	value += _tone(t, 1320.0, 0.25, 0.060, 4.6)
	value += _tone(t, 1760.0, 0.21, 0.080, 4.8)
	value += _tone(t, 1046.5, 0.22, 0.26, 5.2)
	value += _tone(t, 1318.5, 0.22, 0.34, 5.2)
	value += _tone(t, 1568.0, 0.21, 0.42, 5.4)
	value += _tone(t, 2093.0, 0.20, 0.50, 5.7)
	value += _tone(t, 2637.0, 0.18, 0.59, 6.0)
	value += _tone(t, 3136.0, 0.16, 0.68, 6.2)
	value += _tone(t, 4186.0, 0.14, 0.78, 6.7)
	value += _tone(t, 261.6, 0.18, 0.20, 2.4)
	value += _tone(t, 523.25, 0.18, 0.20, 2.6)
	value += _tone(t, 784.0, 0.16, 0.20, 2.8)
	return value

func _build_stream(points: int) -> AudioStreamWAV:
	var duration: float = DEFAULT_DURATION
	if points == 500:
		duration = RICH_500_DURATION
	elif points == 1000:
		duration = JACKPOT_1000_DURATION

	var sample_count: int = int(round(duration * SAMPLE_RATE))
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(sample_count * 2)

	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var sample: float = 0.0
		if points == 500:
			sample = _rich_500_sample(t)
		elif points == 1000:
			sample = _jackpot_1000_sample(t)
		else:
			sample = _default_sample(t)

		sample = tanh(sample * 1.35)
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
