extends Node

# Coin pickup audio lives as an autoload so there is exactly one playback owner.
# 500 and 1000 each have a dedicated player with the authored selected sound.
const SAMPLE_RATE: int = 44100
const DEFAULT_DURATION: float = 0.34
const RICH_500_STREAM: AudioStream = preload("res://assets/audio/coin_500_rich_sample_3.ogg")
const JACKPOT_1000_STREAM: AudioStream = preload("res://assets/audio/coin_1000_STRONG_jackpot_4.ogg")

var default_player: AudioStreamPlayer
var rich_500_player: AudioStreamPlayer
var jackpot_1000_player: AudioStreamPlayer
var default_stream: AudioStreamWAV

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	default_stream = _build_default_stream()

	default_player = AudioStreamPlayer.new()
	default_player.name = "DefaultCoinPickupSFX"
	default_player.stream = default_stream
	default_player.volume_db = -2.0
	default_player.bus = "Master"
	add_child(default_player)

	rich_500_player = AudioStreamPlayer.new()
	rich_500_player.name = "Rich500CoinSFX"
	rich_500_player.stream = RICH_500_STREAM
	rich_500_player.volume_db = 2.0
	rich_500_player.bus = "Master"
	add_child(rich_500_player)

	jackpot_1000_player = AudioStreamPlayer.new()
	jackpot_1000_player.name = "Jackpot1000CoinSFX"
	jackpot_1000_player.stream = JACKPOT_1000_STREAM
	jackpot_1000_player.volume_db = 3.0
	jackpot_1000_player.bus = "Master"
	add_child(jackpot_1000_player)

func play_coin(points: int) -> void:
	match points:
		500:
			_play_player(rich_500_player)
		1000:
			_play_player(jackpot_1000_player)
		_:
			_play_player(default_player)

func _play_player(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.stream_paused = false
	if player.playing:
		player.stop()
	player.play(0.0)

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
