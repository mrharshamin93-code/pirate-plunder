extends Node

# Premium treasure pickup SFX. Common coins keep the generated in-engine sound;
# 500 and 1000 point coins use richer authored jackpot sounds.
const SAMPLE_RATE: int = 44100
const DURATION: float = 0.34
const COIN_500_STREAM: AudioStream = preload("res://assets/audio/coin_500_rich_sample_3.ogg")
const COIN_1000_STREAM: AudioStream = preload("res://assets/audio/coin_1000_STRONG_jackpot_4.ogg")

var pickup_player: AudioStreamPlayer
var default_stream: AudioStreamWAV
var last_coin_count: int = 0
var last_score: int = 0
var tracked_game: Node = null

func _ready() -> void:
	default_stream = _build_premium_treasure_stream()
	pickup_player = AudioStreamPlayer.new()
	pickup_player.name = "CoinPickupSFX"
	pickup_player.volume_db = -2.0
	pickup_player.stream = default_stream
	add_child(pickup_player)
	set_process(true)

func _process(_delta: float) -> void:
	if tracked_game == null or not is_instance_valid(tracked_game):
		tracked_game = get_tree().current_scene
		if tracked_game != null:
			last_coin_count = int(tracked_game.get("coins_collected"))
			last_score = int(tracked_game.get("score"))
		return

	var game_started: bool = bool(tracked_game.get("game_started"))
	var current_count: int = int(tracked_game.get("coins_collected"))
	var current_score: int = int(tracked_game.get("score"))

	if game_started and current_count > last_coin_count:
		var collected_points: int = maxi(0, current_score - last_score)
		_play_pickup(collected_points)

	last_coin_count = current_count
	last_score = current_score

func _play_pickup(points: int) -> void:
	if pickup_player.playing:
		pickup_player.stop()

	match points:
		500:
			pickup_player.stream = COIN_500_STREAM
			pickup_player.volume_db = 0.0
		1000:
			pickup_player.stream = COIN_1000_STREAM
			pickup_player.volume_db = 1.0
		_:
			pickup_player.stream = default_stream
			pickup_player.volume_db = -2.0

	pickup_player.play()

func _envelope(t: float, duration: float, decay: float) -> float:
	if t < 0.0:
		return 0.0
	var attack: float = minf(1.0, t / 0.004)
	return attack * exp(-decay * t / duration)

func _sample_at(t: float) -> float:
	var value: float = 0.34 * _envelope(t, DURATION, 6.0) * (sin(TAU * 840.0 * t) + 0.30 * sin(TAU * 1680.0 * t))
	if t > 0.06:
		var t2: float = t - 0.06
		value += 0.22 * _envelope(t2, DURATION, 8.0) * sin(TAU * 1260.0 * t2)
	if t > 0.12:
		var t3: float = t - 0.12
		value += 0.15 * _envelope(t3, DURATION, 10.0) * sin(TAU * 2100.0 * t3)
	return clampf(value, -1.0, 1.0)

func _build_premium_treasure_stream() -> AudioStreamWAV:
	var sample_count: int = int(round(DURATION * SAMPLE_RATE))
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(sample_count * 2)
	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var sample: float = _sample_at(t)
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
