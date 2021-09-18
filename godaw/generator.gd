extends Node

var period: float = 22050.0 # Keep the number of samples to mix low, GDScript is not super fast.
var phase = 0.0

var notes = {
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

var amplitude: float = 0.0
var level: float = 0.0
var note: int = 48
var correction_factor: float = 0.5

export var attack: float = 0.5 # in seconds
export var decay: float = 0.25 # in seconds
export var sustain: float = 0.1 # sustain amplitude (out of 1.0)
export var release: float = 0.5 # in seconds
var real_attack: float = 0.0 # time to full amplitude (ms)
var real_decay: float = 0.0 # time from full amplitude to sustain amplitude (ms)
var real_release: float = 0.0 # time from sustain amplitude to silent (ms)

var playback: AudioStreamPlayback = null # Actual playback stream, assigned in _ready().
export var waveform: String = "Sine"

var state = null
var states: Array = ["Attack", "Decay", "Sustain", "Release"]
var state_time: int = 0

var wave_started = 0
var release_started = 0
var last_value = null
var max_wave = null

func _ready():
	var m: Matrix = Matrix.new(2,2)
	m.fill([
		[1,2],
		[3,4]
	])
	var n: Matrix = Matrix.new(2,2)
	n.fill([
		[5,6],
		[7,8]
	])
	var p: Matrix = Matrix.new(2,2)
	p.fill(Matrix.mult(m, n))
	p.print()

func _process(_delta):
	find_node("FrequencyLabel").text = "%s %s" % [_note(), _octave()]
	find_node("LimitLabel").text = "Limit: %s" % amplitude


func update_state():
	var time_in_state = _time() - state_time
	match state:
		"Attack":
			if time_in_state >= real_attack:
				if real_decay > 0.0:
					set_state("Decay")
				else:
					set_state("Sustain")
		"Decay":
			if time_in_state >= real_decay:
				set_state("Sustain")
		"Sustain":
			pass
		"Release":
			if time_in_state >= real_release:
				set_state(null)
				phase = 0


func _note():
	return notes.keys()[note % notes.size()]


func _octave():
	return note / notes.size()


func _frequency():
	return notes[_note()] * pow(2, _octave())


func _physics_process(_delta):
	if should_play():
		_fill_buffer()


func _time():
	return OS.get_ticks_msec()


func should_play():
	return state != null


func set_state(new_state):
	var time_in_state = _time() - state_time
	print("%s %sms -> %s" % [state,time_in_state, new_state])
	state = new_state
	state_time = _time()
	


func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		wave_started = _time()


func _fill_buffer():
	var to_fill = playback.get_frames_available()
	var wave_value
	
	while to_fill > 0:
		playback.push_frame(Vector2.ONE * _waveform_sample(phase)) # Audio frames are stereo.
		phase = fmod(phase + _frequency() / period, 1.0)
		update_state()
		to_fill -= 1


func _waveform_sample(t: float):
	t *= TAU
	var value: float
	
	match waveform:
		"Sine": 
			value = sin(t)
		"Triangle":
			value = 2.0 * abs(2.0 * (t/TAU - floor(t/TAU + 0.5))) - 1.0
		"Saw":
			value = 2.0 * (t/TAU - floor(t/TAU + 0.5))
		"Square":
			value = sign(sin(t))
	
	value = clamp(value, -1.0, 1.0)

	return value


func _amplitude():
	var value: float
	var t: int = _time() - state_time

	match state:
		"Attack":
			value = clamp(1.0 / real_attack * t, 0.0, 1.0)
		"Decay":
			value = clamp((sustain - 1.0) / real_decay * t + 1.0, sustain, 1.0)
		"Sustain":
			value = sustain if real_decay > 0.0 else lerp(level, sustain, 0.5)
		"Release":
			value = max(level - level / real_release * t, 0.0)
		
	if state in ["Attack", "Decay", "Sustain"]: level = value
	amplitude = value
	
#	if last_value != value:
#		last_value = value
	
	return value


func _on_WaveformButton_selected(string):
	waveform = string


func _on_FrequencyDown_pressed():
	if note > 0:
		note -= 1


func _on_FrequencyUp_pressed():
	if note < notes.size() * 8 - 1:
		note += 1


func _on_LimitDown_pressed():
	level -= 0.1


func _on_LimitUp_pressed():
	level += 0.1


func _on_PlayButton_button_down():
	set_state("Attack")


func _on_PlayButton_button_up():
	print("max: %s" % max_wave)
	set_state("Release")
