tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("WaveformPlayer", "AudioStreamPlayer", preload("waveform_player.gd"), preload("waveform_player.svg"))


func _exit_tree():
	remove_custom_type("WaveformPlayer")
