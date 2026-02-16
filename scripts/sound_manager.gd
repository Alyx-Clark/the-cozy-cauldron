extends Node

# Programmatic sound effects using AudioStreamWAV.
# All sounds generated in _ready() — no external audio files needed.

const SAMPLE_RATE := 22050
const MIX_RATE := 22050

var _players: Dictionary = {}

func _ready() -> void:
	_create_sound("place", _gen_sweep(300.0, 500.0, 0.08))
	_create_sound("remove", _gen_sweep(400.0, 200.0, 0.08))
	_create_sound("brew_complete", _gen_sine_decay(800.0, 0.15))
	_create_sound("sell", _gen_coin_clink())
	_create_sound("unlock", _gen_arpeggio([600.0, 800.0, 1000.0], 0.1))
	_create_sound("dispense", _gen_noise_burst(0.05))
	_create_sound("bottle", _gen_sine_decay(1000.0, 0.1))
	_create_sound("order_complete", _gen_arpeggio([500.0, 700.0, 900.0], 0.13))
	_create_sound("click", _gen_noise_burst(0.03))

## Play a named sound effect.
func play(sound_name: String) -> void:
	if _players.has(sound_name):
		var player: AudioStreamPlayer = _players[sound_name]
		player.play()

func _create_sound(sound_name: String, data: PackedByteArray) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -8.0
	add_child(player)
	_players[sound_name] = player

## Frequency sweep (rising or falling).
func _gen_sweep(freq_start: float, freq_end: float, duration: float) -> PackedByteArray:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase := 0.0
	for i in range(samples):
		var t := float(i) / float(samples)
		var freq := lerpf(freq_start, freq_end, t)
		var envelope := 1.0 - t  # Linear fade out
		var value := sin(phase * TAU) * envelope * 0.5
		phase += freq / SAMPLE_RATE
		var sample := int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data

## Single sine tone with decay.
func _gen_sine_decay(freq: float, duration: float) -> PackedByteArray:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(samples)
		var envelope := (1.0 - t) * (1.0 - t)  # Quadratic decay
		var value := sin(float(i) / SAMPLE_RATE * freq * TAU) * envelope * 0.4
		var sample := int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data

## Two quick high-pitched hits (coin clink).
func _gen_coin_clink() -> PackedByteArray:
	var duration := 0.1
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(samples)
		var hit1_env := maxf(0.0, 1.0 - t * 6.0)  # First hit: fast decay
		var hit2_start := 0.4
		var hit2_env := maxf(0.0, 1.0 - (t - hit2_start) * 8.0) if t > hit2_start else 0.0
		var value := sin(float(i) / SAMPLE_RATE * 1200.0 * TAU) * hit1_env * 0.35
		value += sin(float(i) / SAMPLE_RATE * 1400.0 * TAU) * hit2_env * 0.3
		var sample := int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data

## Ascending arpeggio (3 tones).
func _gen_arpeggio(freqs: Array, tone_duration: float) -> PackedByteArray:
	var total_duration := tone_duration * freqs.size()
	var samples := int(SAMPLE_RATE * total_duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var tone_samples := int(SAMPLE_RATE * tone_duration)
	for i in range(samples):
		@warning_ignore("integer_division")
		var tone_idx := mini(i / tone_samples, freqs.size() - 1)
		var tone_t := float(i - tone_idx * tone_samples) / float(tone_samples)
		var freq: float = freqs[tone_idx]
		var envelope := (1.0 - tone_t) * (1.0 - tone_t) * 0.8
		var value := sin(float(i) / SAMPLE_RATE * freq * TAU) * envelope * 0.35
		var sample := int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data

## Short noise burst.
func _gen_noise_burst(duration: float) -> PackedByteArray:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(samples)
		var envelope := (1.0 - t) * (1.0 - t)
		var value := (randf() * 2.0 - 1.0) * envelope * 0.3
		var sample := int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	return data
