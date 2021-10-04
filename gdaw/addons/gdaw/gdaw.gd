tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("WaveformPlayer", "AudioStreamPlayer", preload("waveform_player.gd"), preload("gdaw_node.svg"))
	add_custom_type("Chord", "Node", preload("chord.gd"), preload("gdaw_node.svg"))


func _exit_tree():
	remove_custom_type("WaveformPlayer")
	remove_custom_type("Chord")
