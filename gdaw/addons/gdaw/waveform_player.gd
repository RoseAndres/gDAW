tool
extends AudioStreamPlayer

signal state_changed(from, to, time_in_state)

enum Note { C, CS, D, EB, E, F, FS, G, GS, A, BB, B }
const NOTE_FREQUENCIES: Dictionary = {
	Note.C: 16.35,
	Note.CS: 17.32,
	Note.D: 18.35,
	Note.EB: 19.45,
	Note.E: 20.60,
	Note.F: 21.83,
	Note.FS: 23.12,
	Note.G: 24.50,
	Note.GS: 25.96,
	Note.A: 27.50,
	Note.BB: 29.14,
	Note.B: 30.87
}

enum Waveform {SINE, TRIANGLE, SQUARE, SAW, WHITE_NOISE, BROWN_NOISE}
enum State {STOPPED, ATTACK, DECAY, SUSTAIN, RELEASE}

export(Waveform) var waveform = Waveform.SINE
export(Note) var note = Note.C
export(int, 0, 10) var octave = 4

export(bool) var use_hz = false
export(float, 0, 40000, 0.01) var hz = 220.0

export(float, 0, 1, 0.01) var limit = 0.6

export var linear: bool = false

export(float, 0, 10, 0.01) var attack = 1 # in seconds
export(float, 0, 10, 0.01) var decay = 1 # in seconds
export(float, 0, 1, 0.01) var sustain = 1 # sustain amplitude (out of 1.0)
export(float, 0, 10, 0.01) var release = 1 # in seconds

export(float, 0, 1, 0.05) var attack_shape = 0.5
export(float, 0, 1, 0.05) var decay_shape = 0.5
export(float, 0, 1, 0.05) var release_shape = 0.5

export var play: bool = false # for playing in editor

var was_playing: bool = false

var last_level: float
var last_value: float = sin(randf() * TAU)

var playback: AudioStreamPlayback = null # Actual playback stream, assigned in _ready().


func start() -> void:
	play = true


func finish() -> void:
	play = false


func is_playing() ->  bool:
	return _state != State.STOPPED


func set_state(state_key: String) -> void:
	var new_state: int = _state_from_key(state_key)
	emit_signal("state_changed", get_state(), state_key, time_in_state())
	_state = new_state
	_state_time = _time()


func set_audio_bus(audio_bus: String) -> void:
	set_bus(audio_bus)


func get_state() -> String:
	return State.keys()[_state]


func get_class_name() -> String:
	return "WaveformPlayer"


func time_in_state() -> int:
	return _time() - _state_time


func frequency() -> float:
	return hz if use_hz else NOTE_FREQUENCIES[note] * pow(2, octave)


# private
var _real_attack: float = 0.0 # time to full amplitude (ms)
var _real_decay: float = 0.0 # time from full amplitude to sustain amplitude (ms)
var _real_release: float = 0.0 # time from sustain amplitude to silent (ms)

var _attack_quad: Array # stores the coefficients for the attack curve
var _decay_quad: Array # stores the coefficients for the decay curve
var _release_quad: Array # stores the coefficients for the release curve

var _state_time: int = 0

var _phase: float = 0.0

var _state: int = State.STOPPED


func _ready() -> void:
	_update_envelope()
	_create_generator()


func _start_emitting() -> void:
	volume_db = GDawConfig.min_db
	_update_envelope()
	_update_quads()
	play()
	set_state("ATTACK")


func _create_generator() -> void:
	stream = AudioStreamGenerator.new()
	stream.mix_rate = GDawConfig.sample_rate # Setting mix rate is only possible before play().
	playback = get_stream_playback()


func _state_from_key(state_key: String) -> int:
	return State.keys().find(state_key)


func _physics_process(_delta) -> void:
	if not _state == State.STOPPED:
		_fill_buffer()
		_update_state()
		volume_db = GDawConfig.min_db + ((GDawConfig.max_db - GDawConfig.min_db) * _envelope() * limit)

	if was_playing and not play:
		if not linear:
			# this quad must be calculated inline
			_release_quad = _find_quad(
				Vector2(0.0, last_level),
				Vector2(_real_release / 2.0, last_level * release_shape),
				Vector2(_real_release, 0.0)
			)
		set_state("RELEASE")
	elif not was_playing and play:
		_start_emitting()
	
	was_playing = play


func _update_envelope() -> void:
	_real_attack = attack * 1000
	_real_decay = decay * 1000
	_real_release = release * 1000


func _update_quads() -> void:
	# calc + cache quads if not linear
	# release quad must be calculated as needed, since it is driven by the last
	# limit used
	if not linear:
		_attack_quad = _find_quad(
			Vector2(0.0, 0.0),
			Vector2(_real_attack / 2.0, attack_shape),
			Vector2(_real_attack, 1.0)
		)
		_decay_quad = _find_quad(
			Vector2(0.0, 1.0),
			Vector2(_real_decay / 2.0, decay_shape),
			Vector2(_real_decay, sustain)
		)


func _update_state() -> void:
	var t = time_in_state()
	match _state:
		State.ATTACK:
			if t >= _real_attack:
				if _real_decay > 0.0:
					set_state("DECAY")
				else:
					set_state("SUSTAIN")
		State.DECAY:
			if t >= _real_decay:
				set_state("SUSTAIN")
		State.SUSTAIN:
			pass
		State.RELEASE:
			if t >= _real_release:
				stop()
				set_state("STOPPED")
				_create_generator() # doing this to clear sound buffer
				_phase = 0


func _time() -> int:
	return OS.get_ticks_msec()


func _fill_buffer() -> void:
	var to_fill = playback.get_frames_available()
	while to_fill > 0:
		playback.push_frame(Vector2.ONE * _waveform_sample(_phase)) # Audio frames are stereo.
		_phase = fmod(_phase + frequency() / GDawConfig.sample_rate, 1.0)
		_update_state()
		to_fill -= 1


func _waveform_sample(t: float) -> float:
	t *= TAU
	var value: float
	
	match waveform:
		Waveform.SINE: 
			value = sin(t)
		Waveform.TRIANGLE:
			value = 2.0 * abs(2.0 * (t/TAU - floor(t/TAU + 0.5))) - 1.0
		Waveform.SAW:
			value = 2.0 * (t/TAU - floor(t/TAU + 0.5))
		Waveform.SQUARE:
			value = sign(sin(t))
		Waveform.WHITE_NOISE:
			value = sin(randf())
		Waveform.BROWN_NOISE:
			value = last_value + randf() * 0.2 - 0.1
			last_value = clamp(value, -1.0, 1.0)

	value = clamp(value, -1.0, 1.0)

	return value


func _envelope() -> float:
	var value: float
	var t: int = time_in_state()

	match _state:
		State.ATTACK:
			if linear: 
				value = 1.0 / _real_attack * t
			else: 
				value = _calc_quad(_attack_quad, t)
			value = clamp(value, 0.0, 1.0)
		State.DECAY:
			if linear: 
				value = (sustain - 1.0) / _real_decay * t + 1.0
			else: 
				value = _calc_quad(_decay_quad, t)
			value = clamp(value, sustain, 1.0)
		State.SUSTAIN:
			value = sustain if _real_decay > 0.0 else lerp(last_level, sustain, 0.5)
		State.RELEASE:
			if linear: 
				value = last_level - last_level / _real_release * t
			else: 
				value = _calc_quad(_release_quad, t)
			value = max(value, 0.0)
		
	if _state in [State.ATTACK, State.DECAY, State.SUSTAIN]: last_level = value

	return value


func _calc_quad(quad: Array, t: float) -> float:
	return quad[0] * pow(t, 2) + quad[1] * t + quad[2]


func _find_quad(p1: Vector2, p2: Vector2, p3: Vector2) -> Array:
	var a: Matrix = Matrix.new(3, 3)
	a.fill([
		[pow(p1.x, 2), p1.x, 1],
		[pow(p2.x, 2), p2.x, 1],
		[pow(p3.x, 2), p3.x, 1]
	])
	
	var a_inv: Matrix = Matrix.new(3, 3)
	a_inv.fill(a.inverse())
	
	var y: Matrix = Matrix.new(3, 1)
	var y_values = [
		[p1.y],
		[p2.y],
		[p3.y]
	]
	y.fill(y_values)
	
	var c: Matrix = Matrix.new(3, 1)
	c.fill(Matrix.mult(a_inv, y))
	
	return [c.p[0][0], c.p[1][0], c.p[2][0]]
