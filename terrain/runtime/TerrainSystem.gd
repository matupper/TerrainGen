extends Node
class_name TerrainSystem

@export var settings: TerrainSettings

@onready var chunks_root: Node3D = $Chunks

func _generate_one_chunk() -> void:
	# Clear previous chunks
	for c in chunks_root.get_children():
		c.queue_free()
	
	var hp := HeightProvider.new(settings)
	
	var verts_per_side = settings.verts_per_side
	var spacing := settings.vertexspacing
	
	# Arrays we will fill
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	
	# Presize helps performance and avoids mistakes
	vertices.resize(verts_per_side * verts_per_side)
	normals.resize(verts_per_side * verts_per_side)
	uvs.resize(verts_per_side * verts_per_side)
	
	# Build vertices and UVs
	for z in range(verts_per_side):
		for x in range(verts_per_side):
			var idx = z * verts_per_side + x
			
			var wx := float(x) * spacing
			var wz := float(z) * spacing
			var wy := hp.get_height(wx, wz)
			
			vertices[idx] = Vector3(wx, wy, wz)
			uvs[idx] = Vector2(float(x) / float(verts_per_side - 1), float(z) / float(verts_per_side - 1))
	
	# Build indices (two triangles per quad)
	# Quad Corners:
	# a = (x, z)
	# b = (x+1, z)
	# c = (x, z+1)
	# d = (x+1, z+1)
	for z in range(verts_per_side - 1):
		for x in range(verts_per_side - 1):
			var a = z * verts_per_side + x
			var b = a + 1
			var c = a + verts_per_side
			var d = c + 1

			# Triangle 1: a, b, c
			indices.append(a)
			indices.append(b)
			indices.append(c)
			
			#triangle 2: b, d, c
			indices.append(b)
			indices.append(d)
			indices.append(c)
	
	# Compute Normals
	# Start at 0
	for i in range(normals.size()):
		normals[i] = Vector3.ZERO
		
	# For each trianglem add its face normal into each vertex normal accumulator
	for i in range(0, indices.size(), 3):
		var i0 := indices[i]
		var i1 := indices[i + 1]
		var i2 := indices[i + 2]
		
		var v0 := vertices[i0]
		var v1 := vertices[i1]
		var v2 := vertices[i2]
		
		var face_normal := (v2 - v0).cross(v1 - v0)
		
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
	
	# Draw it
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	chunks_root.add_child(mi)

func _ready() -> void:
	if settings == null:
		push_error("TerrainSystem: settings is not assigned")
		return
	
	_generate_one_chunk()
