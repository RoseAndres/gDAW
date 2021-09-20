tool
extends AudioStreamPlayer

signal state_change(state)

enum Notes { C, CS, D, EB, E, F, FS, G, GS, A, BB, B }
const NOTE_FREQUENCIES: Dictionary = {
	Notes.C: 16.35,
	Notes.CS: 17.32,
	Notes.D: 18.35,
	Notes.EB: 19.45,
	Notes.E: 20.60,
	Notes.F: 21.83,
	Notes.FS: 23.12,
	Notes.G:  24.50,
	Notes.GS:  25.96,
	Notes.A: 27.50,
	Notes.BB: 29.14,
	Notes.B: 30.87
}

enum Waveforms {SINE, TRIANGLE, SQUARE, SAW}
enum State {ATTACK, DECAY, SUSTAIN, RELEASE, STOPPED = -1}

export(Waveforms) var waveform = Waveforms.SINE
export(Notes) var note = Notes.C
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

var _real_attack: float = 0.0 # time to full amplitude (ms)
var _real_decay: float = 0.0 # time from full amplitude to sustain amplitude (ms)
var _real_release: float = 0.0 # time from sustain amplitude to silent (ms)

var _attack_quad # stores the coefficients for the attack curve
var _decay_quad # stores the coefficients for the decay curve
var _release_quad # stores the coefficients for the release curve

var _state_time: int = 0

var playback: AudioStreamPlayback = null # Actual playback stream, assigned in _ready().

var _phase = 0.0
var was_playing = false
var was_play = false

var _state = State.STOPPED
var last_level: float


func _ready():
	_update_envelope()
	_create_generator()


func _create_generator():
	stream = AudioStreamGenerator.new()
	stream.mix_rate = GodawConfig.godaw_sample_rate # Setting mix rate is only possible before play().
	playback = get_stream_playback()


func _physics_process(_delta):
	if not _state == State.STOPPED:
		_fill_buffer()
		_update_state()
		volume_db = GodawConfig.godaw_min_db + ((GodawConfig.godaw_max_db - GodawConfig.godaw_min_db) * _envelope() * limit)

	if was_playing and not play:
		if not linear:
			# this quad must be calculated inline
			_release_quad = _find_quad(
				Vector2(0.0, last_level),
				Vector2(_real_release / 2.0, last_level * release_shape),
				Vector2(_real_release, 0.0)
			)
		set_state(State.RELEASE)
	elif not was_playing and play:
		start()

	was_playing = play


func is_playing():
	return play


func start():
	volume_db = GodawConfig.godaw_min_db
	_update_envelope()
	_update_quads()
	play()
	set_state(State.ATTACK)


func finish():
	play = false

func _update_envelope():
	_real_attack = attack * 1000
	_real_decay = decay * 1000
	_real_release = release * 1000


func _update_quads():
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


func set_state(new_state):
	_state = new_state
	_state_time = _time()


func current_asdr_state():
	for key in State.keys():
		if _state == State[key]: return key


func time_in_state():
	return _time() - _state_time


func _update_state():
	var t = time_in_state()
	match _state:
		State.ATTACK:
			if t >= _real_attack:
				if _real_decay > 0.0:
					set_state(State.DECAY)
				else:
					set_state(State.SUSTAIN)
		State.DECAY:
			if t >= _real_decay:
				set_state(State.SUSTAIN)
		State.SUSTAIN:
			pass
		State.RELEASE:
			if t >= _real_release:
				stop()
				set_state(State.STOPPED)
				_create_generator() # doing this to clear sound buffer
				_phase = 0


func frequency():
	return hz if use_hz else NOTE_FREQUENCIES[note] * pow(2, octave)


func _time():
	return OS.get_ticks_msec()


func _fill_buffer():
	var to_fill = playback.get_frames_available()
	while to_fill > 0:
		playback.push_frame(Vector2.ONE * _waveform_sample(_phase)) # Audio frames are stereo.
		_phase = fmod(_phase + frequency() / GodawConfig.godaw_sample_rate, 1.0)
		_update_state()
		to_fill -= 1


func _waveform_sample(t: float):
	t *= TAU
	var value: float
	
	match waveform:
		Waveforms.SINE: 
			value = sin(t)
		Waveforms.TRIANGLE:
			value = 2.0 * abs(2.0 * (t/TAU - floor(t/TAU + 0.5))) - 1.0
		Waveforms.SAW:
			value = 2.0 * (t/TAU - floor(t/TAU + 0.5))
		Waveforms.SQUARE:
			value = sign(sin(t))
	
	value = clamp(value, -1.0, 1.0)

	return value


func _envelope():
	var value: float
	var t: int = time_in_state()

	match _state:
		State.ATTACK:
			if linear: 
				value = 1.0 / _real_attack * t
			else: 
				value = _quad(_attack_quad, t)
			value = clamp(value, 0.0, 1.0)
		State.DECAY:
			if linear: 
				value = (sustain - 1.0) / _real_decay * t + 1.0
			else: 
				value = _quad(_decay_quad, t)
			value = clamp(value, sustain, 1.0)
		State.SUSTAIN:
			value = sustain if _real_decay > 0.0 else lerp(last_level, sustain, 0.5)
		State.RELEASE:
			if linear: 
				value = last_level - last_level / _real_release * t
			else: 
				value = _quad(_release_quad, t)
			value = max(value, 0.0)
		
	if _state in [State.ATTACK, State.DECAY, State.SUSTAIN]: last_level = value

	return value


func _quad(quad: Array, t: float):
	return quad[0] * pow(t, 2) + quad[1] * t + quad[2]


func _find_quad(p1: Vector2, p2: Vector2, p3: Vector2):
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
	

func _on_Player_tree_entered():
	if Engine.editor_hint:
		_ready()
