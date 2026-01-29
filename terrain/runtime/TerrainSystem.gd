extends Node
class_name TerrainSystem

@export var settings: TerrainSettings

@onready var chunks_root: Node3D = $Chunks

func _generate_one_chunk() -> void:
	for c in chunks_root.get_children():
		c.queue_free()
	
	var chunk := TerrainChunk.new()
	chunks_root.add_child(chunk)
	
	chunk.setup(settings, Vector2i(1, 0))
	chunk.generate()

func _ready() -> void:
	if settings == null:
		push_error("TerrainSystem: settings is not assigned")
		return
	
	_generate_one_chunk()
