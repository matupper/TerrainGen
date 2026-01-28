extends Node

@export var settings: TerrainSettings

func _ready() -> void:
	var hp := HeightProvider.new(settings)
	print("h(0,0) =", hp.get_height(0.0, 0.0))
	print("h(10,10) =", hp.get_height(10.0, 10.0))
	print("h(100,50) =", hp.get_height(100.0, 50.0))
