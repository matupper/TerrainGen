extends RefCounted
class_name HeightProvider

var _settings: TerrainSettings
var _noise: FastNoiseLite

# Setup noise and imported settings
func _init(settings: TerrainSettings) -> void:
	_settings = settings
	_noise = FastNoiseLite.new()
	_noise.seed = _settings.world_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = _settings.noise_frequency

func get_height(x: float, z: float) -> float:
	var h := 0.0
	var amp := 1.0
	var freq := 1.0
	
	# build FBM
	for i in range (_settings.octaves):
		h += _noise.get_noise_2d(x * freq, z * freq) * amp
		amp *= 0.5
		freq *= 2
	
	# Terracing stylization
	if _settings.terracing_enabled and _settings.terracing_step > 0.0:
		h = snapped(h * _settings.height_scale, _settings.terracing_step) / _settings.height_scale
	
	return h * _settings.height_scale
