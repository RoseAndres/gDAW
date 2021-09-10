extends Button

signal selected(string)

export var waveform = "Sine"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_toggled(button_pressed):
	if button_pressed:
		emit_signal("selected", waveform)
