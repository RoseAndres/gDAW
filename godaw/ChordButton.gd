tool
extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ChordButton_toggled(button_pressed):
	if button_pressed:
		$WaveformPlayer.start()
		$WaveformPlayer2.start()
		$WaveformPlayer3.start()
	else:
		$WaveformPlayer.finish()
		$WaveformPlayer2.finish()
		$WaveformPlayer3.finish()
