tool
extends Node

# required by GoDAW for WaveformPlayer nodes to function
var godaw_max_db: float = -6.0 # maximum volume
var godaw_min_db: float = -80.0 # maximum volume
var godaw_sample_rate = 32000 # Keep the number of samples to mix low, GDScript is not super fast.
