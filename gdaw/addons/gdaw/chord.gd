tool
extends Node

export (String) var audio_bus = "Master"


func start() -> void:
	_update_audio_buses()
	_send("start")


func finish() -> void:
	_send("finish")
	

func get_class_name():
	return "Chord"


func _update_audio_buses():
	_send("set_audio_bus", audio_bus)


func _send(msg: String, args = null) -> void:
	for child in get_children():
		if child.has_method("get_class_name") and child.get_class_name() == "WaveformPlayer":
			if args:
				child.call(msg, args)
			else:
				child.call(msg)
