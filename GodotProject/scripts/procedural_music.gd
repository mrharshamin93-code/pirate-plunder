extends Node

# Exact Godot port of the existing React Native procedural sea shanty.
# 8 bars, D minor, 6/8, with lead fiddle, whistle response, bass,
# accordion-style chords and hand drum. No external audio asset required.

const SAMPLE_RATE: int = 16000
const EIGHTH: float = 0.275
const EIGHTHS_PER_BAR: int = 6
const BARS: int = 8
const TOTAL_EIGHTHS: int = BARS * EIGHTHS_PER_BAR
const LOOP_SAMPLES: int = int(round(TOTAL_EIGHTHS * EIGHTH * SAMPLE_RATE))
const SAVE_PATH: String = "user://music.cfg"

const MELODY: Array[Vector2i] = [
	Vector2i(62,2), Vector2i(65,1), Vector2i(69,2), Vector2i(65,1),
	Vector2i(67,2), Vector2i(65,1), Vector2i(62,3),
	Vector2i(70,2), Vector2i(69,1), Vector2i(67,2), Vector2i(62,1),
	Vector2i(67,2), Vector2i(62,1), Vector2i(65,3),
	Vector2i(74,2), Vector2i(72,1), Vector2i(70,2), Vector2i(69,1),
	Vector2i(69,2), Vector2i(73,1), Vector2i(69,3),
	Vector2i(72,2), Vector2i(70,1), Vector2i(69,2), Vector2i(65,1),
	Vector2i(64,2), Vector2i(61,1), Vector2i(62,3)
]

const COUNTER_MELODY: Array[Vector2i] = [
	Vector2i(0,6), Vector2i(74,3), Vector2i(72,3), Vector2i(0,6),
	Vector2i(70,3), Vector2i(69,3), Vector2i(0,6), Vector2i(77,2),
	Vector2i(76,1), Vector2i(73,3), Vector2i(0,6), Vector2i(69,3), Vector2i(0,3)
]

const BASS: Array[Vector2i] = [
	Vector2i(38,3), Vector2i(45,3), Vector2i(38,3), Vector2i(45,3),
	Vector2i(43,3), Vector2i(50,3), Vector2i(43,3), Vector2i(50,3),
	Vector2i(46,3), Vector2i(53,3), Vector2i(45,3), Vector2i(52,3),
	Vector2i(38,3), Vector2i(45,3), Vector2i(45,3), Vector2i(45,3)
]

const CHORDS: Array[Array] = [
	[50,53,57], [50,53,57], [50,55,58], [50,55,58],
	[53,58,62], [52,57,61], [50,53,57], [52,57,61]
]

var player: AudioStreamPlayer
var toggle_button: Button
var music_enabled: bool = true
var noise_state: int = 20250813

func _ready() -> void:
	_load_setting()
	player = AudioStreamPlayer.new()
	player.name = "BackgroundMusic"
	player.volume_db = -8.0
	add_child(player)
	player.stream = _build_stream()
	_build_toggle()
	_apply_enabled_state()

func _load_setting() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		music_enabled = bool(cfg.get_value("audio", "music_enabled", true))

func _save_setting() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.save(SAVE_PATH)

func _build_toggle() -> void:
	var game: Node = get_parent()
	var canvas: CanvasLayer = game.get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas == null:
		return
	toggle_button = Button.new()
	toggle_button.name = "MusicToggle"
	toggle_button.position = Vector2(171.0, 22.0)
	toggle_button.size = Vector2(48.0, 38.0)
	toggle_button.flat = true
	toggle_button.focus_mode = Control.FOCUS_NONE
	toggle_button.add_theme_font_size_override("font_size", 22)
	toggle_button.add_theme_color_override("font_color", Color(0.90, 0.98, 1.0, 0.92))
	toggle_button.pressed.connect(_toggle_music)
	canvas.add_child(toggle_button)
	_update_toggle_text()

func _toggle_music() -> void:
	music_enabled = not music_enabled
	_save_setting()
	_apply_enabled_state()

func _apply_enabled_state() -> void:
	if player == null:
		return
	if music_enabled:
		if not player.playing:
			player.play()
	else:
		player.stop()
	_update_toggle_text()

func _update_toggle_text() -> void:
	if toggle_button != null:
		toggle_button.text = "🔊" if music_enabled else "🔇"

func _midi_to_freq(midi: int) -> float:
	return 440.0 * pow(2.0, (float(midi) - 69.0) / 12.0)

func _triangle(phase: float) -> float:
	var x: float = phase - floor(phase)
	return 4.0 * absf(x - 0.5) - 1.0

func _square(phase: float, duty: float) -> float:
	var x: float = phase - floor(phase)
	return 1.0 if x < duty else -1.0

func _add_tone(
	out: PackedFloat32Array,
	start_sec: float,
	dur_sec: float,
	freq: float,
	gain: float,
	edge: float,
	duty: float,
	gate: float,
	vibrato: float,
	attack_sec: float,
	release_sec: float,
	decay: float
) -> void:
	var start_index: int = int(round(start_sec * SAMPLE_RATE))
	var length: int = maxi(1, int(round(dur_sec * gate * SAMPLE_RATE)))
	var attack: int = maxi(1, mini(int(attack_sec * SAMPLE_RATE), int(length * 0.4)))
	var release: int = maxi(1, mini(int(release_sec * SAMPLE_RATE), int(length * 0.6)))
	var phase: float = 0.0
	for i in range(length):
		var t: float = float(i) / SAMPLE_RATE
		var wobble: float = 1.0 + vibrato * sin(t * TAU * 5.5)
		phase += (freq * wobble) / SAMPLE_RATE
		var wave: float = _triangle(phase) * (1.0 - edge) + _square(phase, duty) * edge
		var env: float = 1.0 - decay * (float(i) / float(length))
		if i < attack:
			env *= float(i) / float(attack)
		elif i > length - release:
			env *= float(length - i) / float(release)
		var idx: int = (start_index + i) % out.size()
		out[idx] += wave * gain * env

func _next_noise() -> float:
	noise_state = int((noise_state * 1664525 + 1013904223) & 0xffffffff)
	return float(noise_state) / 2147483648.0 - 1.0

func _add_drum(out: PackedFloat32Array, start_sec: float, gain: float) -> void:
	var start_index: int = int(round(start_sec * SAMPLE_RATE))
	var length: int = int(round(0.16 * SAMPLE_RATE))
	var filtered: float = 0.0
	for i in range(length):
		var t: float = float(i) / SAMPLE_RATE
		filtered += (_next_noise() - filtered) * 0.35
		var slap: float = filtered * exp(-t * 42.0)
		var thud: float = sin(t * TAU * 84.0) * exp(-t * 16.0)
		var idx: int = (start_index + i) % out.size()
		out[idx] += (slap * 0.7 + thud) * gain

func _render_steps(out: PackedFloat32Array, steps: Array[Vector2i], voice: int) -> void:
	var position: int = 0
	for step: Vector2i in steps:
		var midi: int = step.x
		var eighths: int = step.y
		if midi > 0:
			var freq: float = _midi_to_freq(midi)
			match voice:
				0:
					_add_tone(out, position * EIGHTH, eighths * EIGHTH, freq, 0.20, 0.25, 0.35, 0.92, 0.005, 0.02, 0.07, 0.25)
				1:
					_add_tone(out, position * EIGHTH, eighths * EIGHTH, freq, 0.085, 0.06, 0.50, 0.88, 0.009, 0.035, 0.10, 0.18)
				2:
					_add_tone(out, position * EIGHTH, eighths * EIGHTH, freq, 0.26, 0.10, 0.50, 0.80, 0.0, 0.008, 0.06, 0.45)
		position += eighths

func _render_loop() -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(LOOP_SAMPLES)
	out.fill(0.0)
	noise_state = 20250813
	_render_steps(out, MELODY, 0)
	_render_steps(out, COUNTER_MELODY, 1)
	_render_steps(out, BASS, 2)
	for bar in range(BARS):
		var chord: Array = CHORDS[bar]
		var bar_start: int = bar * EIGHTHS_PER_BAR
		for offset in [0, 3]:
			for midi_value in chord:
				var midi: int = int(midi_value)
				_add_tone(out, (bar_start + int(offset)) * EIGHTH, EIGHTH, _midi_to_freq(midi), 0.055, 0.50, 0.30, 0.42, 0.0, 0.01, 0.05, 0.50)
		_add_drum(out, bar_start * EIGHTH, 0.20)
		_add_drum(out, (bar_start + 3) * EIGHTH, 0.13)
		for offset in [1, 2, 4, 5]:
			_add_drum(out, (bar_start + int(offset)) * EIGHTH, 0.045)
	return out

func _build_stream() -> AudioStreamWAV:
	var samples: PackedFloat32Array = _render_loop()
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(samples.size() * 2)
	for i in range(samples.size()):
		var clipped: float = tanh(samples[i] * 1.25)
		var value: int = clampi(int(round(clipped * 31500.0)), -32768, 32767)
		pcm[i * 2] = value & 0xff
		pcm[i * 2 + 1] = (value >> 8) & 0xff
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples.size()
	return stream
