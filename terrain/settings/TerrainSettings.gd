extends Resource
class_name TerrainSettings

@export_group("World")
@export var world_seed: int = 12345
@export var height_scale: float = 60.0

@export_group("Mesh")
@export var verts_per_side: int = 64
@export var vertexspacing: float = 1.0

@export_group("Noise")
@export var noise_frequency: float = 0.01
@export var octaves: int = 5

@export_group("Style")
@export var flat_shading: bool = false
@export var terracing_enabled: bool = false
@export var terracing_step: float = 2.0
