extends Node3D
class_name TerrainChunk

var settings: TerrainSettings
var chunk_coord: Vector2i = Vector2i.ZERO
var lod: int = 0

var _mesh_instance: MeshInstance3D

func _lod_step() -> int:
	return 1 << lod

func _ready() -> void:
	# Create the MeshInstance once
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)

func _build_smooth_mesh(
	hp: HeightProvider,
	origin_x: float,
	origin_z: float,
	verts_per_side: int,
	spacing: float
) -> ArrayMesh:	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	
	var step := _lod_step()
	var grid_verts := int((verts_per_side - 1) / step) + 1
	
	# Presize helps performance and avoids mistakes
	vertices.resize(grid_verts * grid_verts)
	normals.resize(grid_verts * grid_verts)
	uvs.resize(grid_verts * grid_verts)
	
	# Build vertices and UVs
	for z in range(grid_verts):
		for x in range(grid_verts):
			var idx = z * grid_verts + x
			
			var lx := float(x * step) * spacing
			var lz := float(z * step) * spacing
			
			var wx := origin_x + lx
			var wz := origin_z + lz
			var wy := hp.get_height(wx, wz)
			
			# Store vertices in LOCAL space so moving the chunk node moves the mesh cleanly
			vertices[idx] = Vector3(lx, wy, lz)
			
			uvs[idx] = Vector2(
				float(x) / float(grid_verts - 1),
				float(z) / float(grid_verts - 1)
			)
	
	# Indices
	for z in range(grid_verts - 1):
		for x in range(grid_verts - 1):
			var a = z * grid_verts + x
			var b = a + 1
			var c = a + grid_verts
			var d = c + 1

			# Triangle 1: a, b, c
			indices.append(a)
			indices.append(b)
			indices.append(c)
			
			#triangle 2: b, d, c
			indices.append(b)
			indices.append(d)
			indices.append(c)
	
	# Normals
	for i in range(0, indices.size(), 3):
		var i0 := indices[i]
		var i1 := indices[i + 1]
		var i2 := indices[i + 2]
		
		var v0 := vertices[i0]
		var v1 := vertices[i1]
		var v2 := vertices[i2]
		
		# Cross so normals are up
		var face_normal := (v2 - v0).cross(v1 - v0).normalized()
		
		normals[i0] += face_normal
		normals[i1] += face_normal
		normals[i2] += face_normal
	
	# Normalize
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	
	# Build ArrayMesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _build_flat_mesh(
	hp: HeightProvider,
	origin_x: float,
	origin_z: float,
	verts_per_side: int,
	spacing: float
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	
	var step := _lod_step()
	var grid_verts := int((verts_per_side - 1) / step) + 1
	
	# Push 6 vertices per quad (2 Tris)
	# This avoids indices and guarantees flat shading
	for z in range(grid_verts - 1):
		for x in range(grid_verts - 1):
			#Local corners (x,z) in chunk space
			var lx0 := float(x * step) * spacing
			var lz0 := float(z * step) * spacing
			var lx1 := float((x + 1) * step) * spacing
			var lz1 := float((z + 1) * step) * spacing
			
			# World corners for sampling
			var wx0 := origin_x + lx0
			var wz0 := origin_z + lz0
			var wx1 := origin_x + lx1
			var wz1 := origin_z + lz1
			
			# Heights (sample in world space)
			var ya := hp.get_height(wx0, wz0)
			var yb := hp.get_height(wx1, wz0)
			var yc := hp.get_height(wx0, wz1)
			var yd := hp.get_height(wx1, wz1)
			
			# Local positions
			var a := Vector3(lx0, ya, lz0)
			var b := Vector3(lx1, yb, lz0)
			var c := Vector3(lx0, yc, lz1)
			var d := Vector3(lx1, yd, lz1)
			
			# UVs (simple 0..1 across hunk is good enough for now)
			var u0 := float(x) / float(grid_verts - 1)
			var v0 := float(z) / float(grid_verts - 1)
			var u1 := float(x + 1) / float(grid_verts - 1)
			var v1 := float(z + 1) / float(grid_verts - 1)
			
			var uv_a := Vector2(u0, v0)
			var uv_b := Vector2(u1, v0)
			var uv_c := Vector2(u0, v1)
			var uv_d := Vector2(u1, v1)
			
			# Triangle 1: a, b, c
			var n1 := (c - a).cross(b - a). normalized()
			vertices.append(a)
			vertices.append(b)
			vertices.append(c)
			normals.append(n1)
			normals.append(n1)
			normals.append(n1)
			uvs.append(uv_a)
			uvs.append(uv_b)
			uvs.append(uv_c)
			
			# Triangle 2: b, d, c
			var n2 := (c - b).cross(d - b).normalized()
			vertices.append(b)
			vertices.append(d)
			vertices.append(c)
			normals.append(n2)
			normals.append(n2)
			normals.append(n2)
			uvs.append(uv_b)
			uvs.append(uv_d)
			uvs.append(uv_c)
			
	# Build ArrayMesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func setup(p_settings: TerrainSettings, p_chunk_coord: Vector2i, p_lod: int) -> void:
	settings = p_settings
	chunk_coord = p_chunk_coord
	lod = p_lod

func generate() -> void:
	if settings == null:
		push_error("TerrainChunk: settings not assigned. Call setup() first")
		return
	
	# Check for MeshInstance
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		add_child(_mesh_instance)
	
	var hp := HeightProvider.new(settings)
	
	var verts_per_side := settings.verts_per_side
	var spacing := settings.vertex_spacing
	var chunk_world_size := float(verts_per_side - 1) * spacing
	
	# Chunk origin in world space
	var origin_x := float(chunk_coord.x) * chunk_world_size
	var origin_z := float(chunk_coord.y) * chunk_world_size
	
	# Build Mesh
	var mesh: ArrayMesh
	if settings.flat_shading:
		mesh = _build_flat_mesh(hp, origin_x, origin_z, verts_per_side, spacing)
	else:
		mesh = _build_smooth_mesh(hp, origin_x, origin_z, verts_per_side, spacing)
	
	_mesh_instance.mesh = mesh
	# Position the chunk node in world space
	position = Vector3(origin_x, 0.0, origin_z)
