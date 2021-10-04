tool
extends Button


func _on_Button_toggled(button_pressed):
	if button_pressed:
		$Chord.start()
	else:
		$Chord.finish()
