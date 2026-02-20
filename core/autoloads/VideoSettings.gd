extends Node

# ==============================================================================
# SEÑALES
# ==============================================================================
signal resolution_changed
signal vsync_changed
signal window_mode_changed

# ==============================================================================
# CONSTANTES Y CONFIGURACIÓN
# ==============================================================================
## Mapeo de índices a modos de ventana de Godot
const WINDOW_MODE_MAP: Array[DisplayServer.WindowMode] = [
	DisplayServer.WINDOW_MODE_WINDOWED,             # 0
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, # 1 (Mejor rendimiento)
	DisplayServer.WINDOW_MODE_FULLSCREEN            # 2 (Borderless / Windowed Fullscreen)
]

## Lista base de resoluciones comunes para sugerir.
## Se completará dinámicamente con la resolución nativa del monitor.
const BASE_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

# ==============================================================================
# VARIABLES DE ESTADO
# ==============================================================================
var available_resolutions: Array[Vector2i] = []

# Estado actual
var current_resolution_index: int = -1
var current_window_mode_index: int = 0
var vsync_enabled: bool = false

# Estado del hardware
var native_resolution_index: int = -1

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# 1. Detectar hardware y capacidades
	_detect_resolutions()
	_detect_native_resolution()
	
	# 2. Sincronizar variables con el estado actual del motor
	_sync_state_from_engine()

	# 3. Primer arranque: Si no hay config, aplicar defaults inteligentes
	_check_first_run()

# ==============================================================================
# REGIÓN: SETTERS PÚBLICOS (APLICACIÓN DE CONFIGURACIÓN)
# ==============================================================================
#region Setters

## Cambia el modo de ventana (Ventana, Pantalla Completa, Borderless).
## Maneja la lógica compleja de redimensionado al volver a modo ventana.
func set_window_mode_by_index(index: int) -> void:
	if index < 0 or index >= WINDOW_MODE_MAP.size(): return
	
	var new_mode = WINDOW_MODE_MAP[index]
	
	# 1. Aplicamos el modo al motor
	DisplayServer.window_set_mode(new_mode)
	
	# 2. Guardamos el estado
	current_window_mode_index = index
	SettingsManager.config.set_value("video", "window_mode_index", index)
	
	# 3. Lógica diferida para Modo Ventana
	if new_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		# TRUCO: Esperamos 2 frames para que el Sistema Operativo libere el control 
		# de pantalla completa. Si intentamos redimensionar inmediatamente, el SO lo ignora.
		await get_tree().process_frame
		await get_tree().process_frame
		
		_handle_windowed_mode_resize()
	
	# 4. Guardar y Notificar
	SettingsManager.save_settings()
	window_mode_changed.emit()
	SettingsManager.notify_changes()


## Cambia la resolución del juego.
## Si el juego está en pantalla completa, fuerza el cambio a modo ventana.
func set_resolution_by_index(index: int) -> void:
	if index < 0 or index >= available_resolutions.size(): return
	
	var new_res = available_resolutions[index]
	
	# Regla de UX: Si cambias resolución manual, asumimos que quieres modo ventana
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		current_window_mode_index = 0
		window_mode_changed.emit()
	
	# Aplicar tamaño y centrar
	_apply_size_refresh(new_res)
	
	# Actualizar estado
	current_resolution_index = index
	SettingsManager.config.set_value("video", "resolution_index", index)
	SettingsManager.save_settings()
	
	resolution_changed.emit()
	SettingsManager.notify_changes()


func set_vsync(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	vsync_enabled = enabled
	SettingsManager.config.set_value("video", "vsync", enabled)
	SettingsManager.save_settings()
	
	vsync_changed.emit()
	SettingsManager.notify_changes()

#endregion

# ==============================================================================
# REGIÓN: LÓGICA DE DEFAULTS
# ==============================================================================
#region Defaults

func apply_default_settings(defaults: Dictionary) -> void:
	# 1. Modo de Pantalla
	if defaults.has("window_mode_index"):
		set_window_mode_by_index(defaults.window_mode_index)
	
	# 2. Resolución (Siempre intentamos usar la Nativa)
	if native_resolution_index != -1:
		set_resolution_by_index(native_resolution_index)
	
	# 3. VSync
	if defaults.has("vsync"):
		set_vsync(defaults.vsync)

func is_default(defaults: Dictionary) -> bool:
	# Comparamos contra la resolución nativa, no contra un número fijo
	var res_match = (current_resolution_index == native_resolution_index)
	var mode_match = (current_window_mode_index == defaults.window_mode_index)
	var vsync_match = (vsync_enabled == defaults.vsync)
	
	return res_match and mode_match and vsync_match

#endregion

# ==============================================================================
# REGIÓN: MÉTODOS PRIVADOS Y HELPERS
# ==============================================================================
#region Internal Helpers

func _detect_resolutions() -> void:
	available_resolutions.clear()
	var screen_size = DisplayServer.screen_get_size()
	
	for res in BASE_RESOLUTIONS:
		if res.x <= screen_size.x and res.y <= screen_size.y:
			available_resolutions.append(res)
	
	# Aseguramos que la nativa exacta esté en la lista
	if not available_resolutions.has(screen_size):
		available_resolutions.append(screen_size)
	
	available_resolutions.sort()

func _detect_native_resolution() -> void:
	var screen_size = DisplayServer.screen_get_size()
	native_resolution_index = _get_resolution_index(screen_size)
	
	# Fallback: Si falló la detección exacta, usamos la más alta disponible
	if native_resolution_index == -1 and not available_resolutions.is_empty():
		native_resolution_index = available_resolutions.size() - 1

func _sync_state_from_engine() -> void:
	# Modo
	var mode = DisplayServer.window_get_mode()
	current_window_mode_index = WINDOW_MODE_MAP.find(mode)
	if current_window_mode_index == -1: 
		current_window_mode_index = 0 # Fallback a ventana
	
	# VSync
	var current_vsync_mode = DisplayServer.window_get_vsync_mode()
	vsync_enabled = (current_vsync_mode != DisplayServer.VSYNC_DISABLED)
	
	# Resolución
	var current_res = DisplayServer.window_get_size()
	current_resolution_index = _get_resolution_index(current_res)

func _check_first_run() -> void:
	if not SettingsManager.config.has_section("video"):
		print("VideoSettings: Detectado primer arranque. Aplicando configuración nativa.")
		
		#TODO
		# Forzamos los valores por defecto sin pasar por la UI
		# (Nota: Usamos los valores de SettingsManager.DEFAULTS si queremos consistencia)
		# Por ahora, usamos lo más seguro: Ventana + Nativa + Vsync
		set_window_mode_by_index(0)
		set_resolution_by_index(native_resolution_index)
		set_vsync(true)

## Lógica inteligente al pasar de Fullscreen a Ventana
func _handle_windowed_mode_resize() -> void:
	# Si estábamos usando la resolución máxima (nativa) en Fullscreen,
	# al pasar a ventana bajamos un escalón para que la ventana no ocupe todo.
	if current_resolution_index == native_resolution_index:
		var target_index = max(0, native_resolution_index - 1)
		
		if target_index != current_resolution_index:
			set_resolution_by_index(target_index)
		else:
			# Si ya estábamos en la mínima, solo refrescamos
			_apply_size_refresh(available_resolutions[current_resolution_index])
	else:
		# Si ya teníamos una resolución menor, solo restauramos el tamaño
		if current_resolution_index != -1:
			_apply_size_refresh(available_resolutions[current_resolution_index])

func _apply_size_refresh(size: Vector2i) -> void:
	DisplayServer.window_set_size(size)
	_center_window(size)

func _center_window(size: Vector2i) -> void:
	var screen_pos = DisplayServer.screen_get_position()
	var screen_size = DisplayServer.screen_get_size()
	# Clampeo básico para evitar que la ventana se vaya fuera en monitores raros
	var centered_pos = screen_pos + (screen_size - size) / 2
	DisplayServer.window_set_position(centered_pos)

func _get_resolution_index(size: Vector2i) -> int:
	return available_resolutions.find(size)

#endregion
