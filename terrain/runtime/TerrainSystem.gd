extends Node
class_name TerrainSystem

@export var settings: TerrainSettings

@export var target: Node3D
@export var radius: int = 1 # 1 => 3x3, 2 => 5x5 etc...

@export var generate_per_frame: int = 1

@onready var chunks_root: Node3D = $Chunks

var _center_chunk: Vector2i = Vector2i(999999, 999999)
var _chunks: Dictionary = {} 		# key: Vector2i, value: TerarinChunk
var _pending: Array[Vector2i] = []	# coords waiting to be generated
var _pending_set: Dictionary = {}	# coords -> true (prevents duplicates)
var _required_set: Dictionary = {}	# coord -> true (latest required coords)

var _desired_lod: Dictionary = {} # coord -> int

func _get_lod_for_coord(coord: Vector2i) -> int:
	var chunk_world_size := float(settings.verts_per_side - 1) * settings.vertexspacing
	
	# Chunk center in world spcae
	var cx = (float(coord.x) + 0.5) * chunk_world_size
	var cz = (float(coord.y) + 0.5) * chunk_world_size
	
	var tpos := target.global_position
	var dist := Vector2(tpos.x - cx, tpos.z - cz).length()
	
	var lod := 0
	for i in range(settings.lod_distances.size()):
		if dist >= settings.lod_distances[i]:
			lod = i
	return clampi(lod, 0, settings.lod_count - 1)

func _get_required_coords(center: Vector2i, radius: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	coords.resize(0)
	
	for cz in range (center.y - radius, center.y + radius + 1):
		for cx in range (center.x - radius, center.x + radius + 1):
			coords.append(Vector2i(cx, cz))
	
	return coords

func _sort_pending_by_distance(center: Vector2i) -> void:
	_pending.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da = abs(a.x - center.x) + abs(a.y - center.y)  # Manhattan distance
		var db = abs(b.x - center.x) + abs(b.y - center.y)
		return da < db
	)

func _update_chunks(center: Vector2i) -> void:
	var required := _get_required_coords(center, radius)
	
	# Build the latest required set
	_required_set.clear()
	_desired_lod.clear()
	for coord in required:
		_required_set[coord] = true
		_desired_lod[coord] = _get_lod_for_coord(coord)
	
	# 1) Remove chunks that are no longer required
	var to_remove: Array[Vector2i] = []
	for key in _chunks.keys():
		if not _required_set.has(key):
			to_remove.append(key)
	
	for coord in to_remove:
		var chunk: TerrainChunk = _chunks[coord]
		_chunks.erase(coord)
		chunk.queue_free()
	
	# 2) Enqueue chunks that are missing (not generating here)
	for coord in required:
		if _chunks.has(coord):
			continue
		if _pending_set.has(coord):
			continue
		
		_pending.append(coord)
		_pending_set[coord] = true
	
	_sort_pending_by_distance(center)
	print("Center:", center, " Chunks loaded:", _chunks.size())


func _world_to_chunk_coord(world_pos: Vector3) -> Vector2i:
	var chunk_world_size = float(settings.verts_per_side - 1) * settings.vertexspacing
	return Vector2i(
		floori(world_pos.x / chunk_world_size),
		floori(world_pos.z / chunk_world_size)
	)

func _generate_chunk_grid(center: Vector2i, radius: int) -> void:	
	for cz in range(center.y - radius, center.y + radius + 1):
		for cx in range(center.x - radius, center.x + radius + 1):
			var chunk := TerrainChunk.new()
			var coord = Vector2i(cx, cz)
			var lod: int = _desired_lod.get(coord, 0)
			
			chunks_root.add_child(chunk)
			chunk.setup(settings, coord, lod)	
			chunk.generate()

func _generate_pending_budgeted() -> void:
	var generated := 0
	
	while generated < generate_per_frame and _pending.size() > 0:
		var coord = _pending.pop_front()
		_pending_set.erase(coord)
		
		# If no longer reequired, skip it
		if not _required_set.has(coord):
			continue
		
		# If it already got created, skip it
		if _chunks.has(coord):
			continue
		
		var chunk := TerrainChunk.new()
		var lod: int = _desired_lod.get(coord, 0)

		
		chunks_root.add_child(chunk)
		chunk.setup(settings, coord, lod)
		chunk.generate()
		
		_chunks[coord] = chunk
		generated += 1

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
	if target == null or settings == null:
		return

	var new_center := _world_to_chunk_coord(target.global_position)
	if new_center != _center_chunk:
		_center_chunk = new_center
		_update_chunks(_center_chunk)
	
	_generate_pending_budgeted()
