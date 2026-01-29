extends Node
class_name TerrainSystem

@export var settings: TerrainSettings

@export var target: Node3D
@export var radius: int = 1 # 1 => 3x3, 2 => 5x5 etc...

@onready var chunks_root: Node3D = $Chunks

var _center_chunk: Vector2i = Vector2i(999999, 999999)

func _world_to_chunk_coord(world_pos: Vector3) -> Vector2i:
	var chunk_world_size = float(settings.verts_per_side - 1) * settings.vertexspacing
	return Vector2i(
		floori(world_pos.x / chunk_world_size),
		floori(world_pos.z / chunk_world_size)
	)

func _generate_one_chunk() -> void:
	for c in chunks_root.get_children():
		c.queue_free()
	
	var chunk := TerrainChunk.new()
	chunks_root.add_child(chunk)
	
	chunk.setup(settings, Vector2i(0, 0))
	chunk.generate()

func _generate_chunk_grid(center: Vector2i, radius: int) -> void:
	# Clear old chunks
	for c in chunks_root.get_children():
		c.queue_free()
	
	for cz in range(center.y - radius, center.y + radius + 1):
		for cx in range(center.x - radius, center.x + radius + 1):
			var chunk := TerrainChunk.new()
			chunks_root.add_child(chunk)
			chunk.setup(settings, Vector2i (cx, cz))
			chunk.generate()

func _ready() -> void:
	if settings == null:
		push_error("TerrainSystem: settings is not assigned.")
		return
	if target == null:
		push_error("TerrainSystem: target is not assinged.")
		return
	
	_center_chunk = _world_to_chunk_coord(target.global_position)
	_generate_chunk_grid(_center_chunk, radius)

func _process(delta: float) -> void:
	var new_center := _world_to_chunk_coord(target.global_position)
	if new_center != _center_chunk:
		_center_chunk = new_center
		_generate_chunk_grid(_center_chunk, radius)
