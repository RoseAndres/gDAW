tool
extends AudioStreamPlayer

signal state_change(state)

const ATTACK: String = "Attack"
const DECAY: String = "Decay"
const SUSTAIN: String = "Sustain"
const RELEASE: String = "Release"

const SINE: String = "Sine"
const TRIANGLE: String = "Triangle"
const SQUARE: String = "Square"
const SAW: String = "Saw"

const NOTES: Dictionary = {
	"C": 16.35,
	"C#": 17.32,
	"D": 18.35,
	"Eb": 19.45,
	"E": 20.60,
	"F": 21.83,
	"F#": 23.12,
	"G":  24.50,
	"G#":  25.96,
	"A": 27.50,
	"Bb": 29.14,
	"B": 30.87
}

export var waveform: String = SINE

export var max_db: float = 0.0
export var limit: float = 0.5

var min_db: float = -80.0
var last_level: float

export var ln: bool = false

export var attack: float = 0.5 # in seconds
export var decay: float = 0.5 # in seconds
export var sustain: float = 0.5 # sustain amplitude (out of 1.0)
export var release: float = 0.5 # in seconds
export var play: bool = false # for playing in editor

var real_attack: float = 0.0 # time to full amplitude (ms)
var real_decay: float = 0.0 # time from full amplitude to sustain amplitude (ms)
var real_release: float = 0.0 # time from sustain amplitude to silent (ms)

var state = null
var state_time: int = 0

var note: int = 48

var playback: AudioStreamPlayback = null # Actual playback stream, assigned in _ready().

var period: float = 22050.0 # Keep the number of samples to mix low, GDScript is not super fast.
var phase = 0.0
var was_playing = false
var was_play = false


func _ready():
	real_attack = attack * 1000
	real_release = release * 1000
	real_decay = decay * 1000
	_create_generator()


func _create_generator():
	stream = AudioStreamGenerator.new()
	stream.mix_rate = period # Setting mix rate is only possible before play().
	playback = get_stream_playback()


func _physics_process(_delta):
	if state:
		_fill_buffer()
		update_state()
		volume_db = min_db + ((max_db - min_db) * _envelope() * limit)

	if was_playing and not play:
		set_state(RELEASE)
	elif not was_playing and play:
		start()

	was_playing = play


func start():
	volume_db = min_db
	play()
	set_state(ATTACK)


func should_play():
	return state != null


func set_state(new_state):
	state = new_state
	state_time = _time()
	print(state)


func time_in_state():
	return _time() - state_time


func update_state():
	var t = time_in_state()
	match state:
		ATTACK:
			if t >= real_attack:
				if real_decay > 0.0:
					set_state("Decay")
				else:
					print("decay is smaller")
					set_state("Sustain")
		DECAY:
			if t >= real_decay:
				set_state("Sustain")
		SUSTAIN:
			pass
		RELEASE:
			if t >= real_release:
				stop()
				set_state(null)
				_create_generator() # doing this to clear sound buffer
				phase = 0
	


func _note():
	return NOTES.keys()[note % NOTES.size()]


func _octave():
# warning-ignore:integer_division
	return note / NOTES.size()


func _frequency():
	return NOTES[_note()] * pow(2, _octave())


func _time():
	return OS.get_ticks_msec()


func _fill_buffer():
	var to_fill = playback.get_frames_available()
	while to_fill > 0:
		playback.push_frame(Vector2.ONE * _waveform_sample(phase)) # Audio frames are stereo.
		phase = fmod(phase + _frequency() / period, 1.0)
		update_state()
		to_fill -= 1


func _waveform_sample(t: float):
	t *= TAU
	var value: float
	
	match waveform:
		SINE: 
			value = sin(t)
		TRIANGLE:
			value = 2.0 * abs(2.0 * (t/TAU - floor(t/TAU + 0.5))) - 1.0
		SAW:
			value = 2.0 * (t/TAU - floor(t/TAU + 0.5))
		SQUARE:
			value = sign(sin(t))
	
	value = clamp(value, -1.0, 1.0)

	return value


func _envelope():
	var value: float
	var t: int = time_in_state()

	match state:
		ATTACK:
			if ln:
				value = clamp(log(t + 1) / log(real_attack + 1), 0.0, 1.0)
			else:
				value = clamp(1.0 / real_attack * t, 0.0, 1.0)
		DECAY:
			if ln:
				value = clamp(sustain + log(decay - t - 1.0) / log(decay + 1) * (1.0 - sustain), sustain, 1.0)
			else:
				value = clamp((sustain - 1.0) / real_decay * t + 1.0, sustain, 1.0)
		SUSTAIN:
			value = sustain if real_decay > 0.0 else lerp(last_level, sustain, 0.5)
		RELEASE:
			value = max(last_level - last_level / real_release * t, 0.0)
		
	if state in [ATTACK, DECAY, SUSTAIN]: last_level = value

	return value


func _on_Player_tree_entered():
	if Engine.editor_hint:
		_ready()
