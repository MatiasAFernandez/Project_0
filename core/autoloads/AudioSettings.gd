extends Node

# ==============================================================================
# SEÑALES
# ==============================================================================
signal volume_changed(bus_name: String, value: float)

# ==============================================================================
# CONSTANTES DE BUSES
# ==============================================================================
const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"

# Mapa rápido para iteraciones
const BUS_LIST = [BUS_MASTER, BUS_MUSIC, BUS_SFX]

# ==============================================================================
# ESTADO ACTUAL (Valores 0.0 a 1.0)
# ==============================================================================
var volumes: Dictionary = {
	BUS_MASTER: 1.0,
	BUS_MUSIC: 1.0,
	BUS_SFX: 1.0
}

# Índices de los buses (Cache para rendimiento)
var _bus_indices: Dictionary = {}

func _ready() -> void:
	# Cacheamos los índices al inicio para no buscarlos en cada frame
	for bus in BUS_LIST:
		_bus_indices[bus] = AudioServer.get_bus_index(bus)

	# Cargamos configuración inicial (Si existe en SettingsManager)
	_load_initial_state()

# ==============================================================================
# SETTERS PÚBLICOS
# ==============================================================================

func set_master_volume(value: float) -> void:
	_set_volume(BUS_MASTER, value)

func set_music_volume(value: float) -> void:
	_set_volume(BUS_MUSIC, value)

func set_sfx_volume(value: float) -> void:
	_set_volume(BUS_SFX, value)

# ==============================================================================
# LÓGICA INTERNA
# ==============================================================================

func _set_volume(bus_name: String, value: float) -> void:
	# 1. Clampeamos valor por seguridad (0.0 a 1.0)
	var safe_value = clampf(value, 0.0, 1.0)
	
	# 2. Actualizamos estado interno
	volumes[bus_name] = safe_value
	
	# 3. Aplicamos al AudioServer de Godot
	var bus_idx = _bus_indices.get(bus_name, 0)
	
	# Truco Pro: Si el volumen es muy bajo, lo muteamos totalmente para ahorrar CPU
	var db_value = linear_to_db(safe_value)
	AudioServer.set_bus_volume_db(bus_idx, db_value)
	AudioServer.set_bus_mute(bus_idx, safe_value < 0.01)
	
	# 4. Guardamos en SettingsManager (asumiendo estructura: audio -> master/music/sfx)
	SettingsManager.config.set_value("audio", bus_name.to_lower(), safe_value)
	SettingsManager.save_settings() # Opcional: Guardar inmediatamente o diferido
	
	# 5. Notificamos cambios
	volume_changed.emit(bus_name, safe_value)
	SettingsManager.notify_changes()

func _load_initial_state() -> void:
	# Recuperamos valores guardados o usamos 1.0 por defecto
	if SettingsManager.config.has_section("audio"):
		set_master_volume(SettingsManager.config.get_value("audio", "master", 1.0))
		set_music_volume(SettingsManager.config.get_value("audio", "music", 1.0))
		set_sfx_volume(SettingsManager.config.get_value("audio", "sfx", 1.0))
	else:
		# Primera vez: Todo al máximo
		set_master_volume(1.0)
		set_music_volume(1.0)
		set_sfx_volume(1.0)

func get_volume(bus_name: String) -> float:
	return volumes.get(bus_name, 1.0)
