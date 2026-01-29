extends Node
class_name TerrainSystem

@export var settings: TerrainSettings

@onready var chunks_root: Node3D = $Chunks

func _generate_one_chunk() -> void:
	for c in chunks_root.get_children():
		c.queue_free()
	
	var chunk := TerrainChunk.new()
	chunks_root.add_child(chunk)
	
	chunk.setup(settings, Vector2i(0, 0))
	chunk.generate()

func _generate_chunk_grid(radius: int = 1) -> void:
	# radius = 1 means coords -1..1 (3x3)
	# radius = 2 means coords -2..2 (5 x 5) and so on
	
	# Clear old chunks
	for c in chunks_root.get_children():
		c.queue_free()
	
	for cz in range(-radius, radius + 1):
		for cx in range(-radius, radius + 1):
			var chunk := TerrainChunk.new()
			chunks_root.add_child(chunk)
			
			chunk.setup(settings, Vector2i (cx, cz))
			chunk.generate()

func _ready() -> void:
	if settings == null:
		push_error("TerrainSystem: settings is not assigned")
		return
	
	_generate_chunk_grid(1)
