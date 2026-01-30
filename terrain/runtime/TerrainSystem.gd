extends Node
class_name TerrainSystem

@export var settings: TerrainSettings

@export var target: Node3D
@export var radius: int = 1 # 1 => 3x3, 2 => 5x5 etc...

@onready var chunks_root: Node3D = $Chunks

var _center_chunk: Vector2i = Vector2i(999999, 999999)
var _chunks: Dictionary = {} # key: Vector2i, value: TerarinChunk

func _get_required_coords(center: Vector2i, radius: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	coords.resize(0)
	
	for cz in range (center.y - radius, center.y + radius + 1):
		for cx in range (center.x - radius, center.x + radius + 1):
			coords.append(Vector2i(cx, cz))
	
	return coords

func _update_chunks(center: Vector2i) -> void:
	var required := _get_required_coords(center, radius)
	
	# Build a set-like dictionary for quick lookup
	var required_set: Dictionary = {}
	for c in required:
		required_set[c] = true
	
	# 1) Remove chunks that are no longer required
	var to_remove: Array[Vector2i] = []
	for key in _chunks.keys():
		if not required_set.has(key):
			to_remove.append(key)
	
	for coord in to_remove:
		var chunk: TerrainChunk = _chunks[coord]
		_chunks.erase(coord)
		chunk.queue_free()
	
	# 2) Add chunks that are missing
	for coord in required:
		if not _chunks.has(coord):
			var chunk := TerrainChunk.new()
			chunks_root.add_child(chunk)
			chunk.setup(settings, coord)
			chunk.generate()
			_chunks[coord] = chunk
	
	print("Center:", center, " Chunks loaded:", _chunks.size())


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
	_update_chunks(_center_chunk)

func _process(delta: float) -> void:
	var new_center := _world_to_chunk_coord(target.global_position)
	if new_center != _center_chunk:
		_center_chunk = new_center
		_update_chunks(_center_chunk)
