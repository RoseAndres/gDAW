tool
extends Node

# required by gDAW for WaveformPlayer nodes to function
var max_db: float = -6.0 # maximum volume
var min_db: float = -80.0 # maximum volume
var sample_rate = 32000 # Keep the number of samples to mix low, GDScript is not super fast.
