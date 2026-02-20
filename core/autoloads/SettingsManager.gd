extends Node

# ==============================================================================
# SEÑALES
# ==============================================================================
## Se emite cuando cualquier configuración cambia (para actualizar UI, botones, etc.)
signal configuration_changed

# ==============================================================================
# CONSTANTES Y CONFIGURACIÓN
# ==============================================================================
const SETTINGS_PATH := "user://settings.cfg"

## Diccionario maestro de valores por defecto.
## Centraliza la configuración "de fábrica" del juego.
const DEFAULTS: Dictionary = {
	"video": {
		# Nota: El índice de resolución suele ser ignorado por VideoSettings
		# en favor de la resolución nativa, pero lo dejamos definido por estructura.
		"resolution_index": 0,
		
		# 0 = Ventana, 1 = Pantalla Completa, 2 = Sin Bordes
		"window_mode_index": 1,
		
		"vsync": true
	},
	"audio": {
		# Ejemplo de estructura futura
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0
	},
	"gameplay": {
		"language": "es"
	}
}

# ==============================================================================
# VARIABLES DE ESTADO
# ==============================================================================
## Objeto principal que manipula el archivo .cfg
var config := ConfigFile.new()

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Al iniciar el juego, intentamos cargar el archivo de disco.
	# Los módulos (VideoSettings, etc.) leerán de 'config' en sus propios _ready()
	# gracias al orden de Autoloads.
	load_settings()

# ==============================================================================
# GESTIÓN DE ARCHIVOS (PERSISTENCIA)
# ==============================================================================

## Carga la configuración desde el disco.
## Si falla, aplica los valores por defecto automáticamente.
func load_settings() -> void:
	var err = config.load(SETTINGS_PATH)
	
	if err != OK:
		print("SettingsManager: No se encontró configuración previa o error de carga. Aplicando Defaults.")
		# Si no hay archivo, forzamos un reset para crear la estructura base
		reset_to_defaults()
	else:
		print("SettingsManager: Configuración cargada correctamente.")
	
	notify_changes()

## Guarda la configuración actual en el disco.
func save_settings() -> void:
	# config.save devuelve un código de error, es buena práctica chequearlo
	var err = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("SettingsManager: Error al guardar settings. Código: " + str(err))
	
	notify_changes()

# ==============================================================================
# LÓGICA DE NEGOCIO (DEFAULTS & CHECKS)
# ==============================================================================

## Restaura TODAS las configuraciones a sus valores originales.
func reset_to_defaults() -> void:
	print("SettingsManager: Restaurando valores de fábrica...")
	
	# 1. Resetear Video (Delega la lógica al módulo especializado)
	VideoSettings.apply_default_settings(DEFAULTS.video)
	
	# 2. Resetear Audio (Pendiente de implementación)
	# AudioSettings.apply_default_settings(DEFAULTS.audio)
	
	# 3. Guardar los cambios inmediatamente para persistir el reset
	save_settings()

## Verifica si la configuración actual es idéntica a la de fábrica.
## Útil para deshabilitar el botón "Restaurar" si no hay cambios.
func is_configuration_default() -> bool:
	# Verificación de Video
	if not VideoSettings.is_default(DEFAULTS.video):
		return false
	
	# Verificación de Audio (Ejemplo futuro)
	# if not AudioSettings.is_default(DEFAULTS.audio):
	# 	return false
	
	# Si pasó todas las pruebas, entonces todo es default
	return true

## Emite la señal de cambio global.
func notify_changes() -> void:
	configuration_changed.emit()
