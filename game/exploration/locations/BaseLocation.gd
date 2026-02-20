extends Node2D
class_name GameLocation

# ==============================================================================
# CONFIGURACIÓN GENERAL
# ==============================================================================
@export_group("General Settings")
## Nombre que aparecerá en la UI (ej. "Mercado Central")
@export var location_name: String = "Zona Desconocida"

## Define si es una zona segura (sin combates) o peligrosa
@export var is_safe_zone: bool = true

# ==============================================================================
# CONFIGURACIÓN DE AUDIO
# ==============================================================================
@export_group("Audio")
## Música de fondo para esta zona. Si se deja vacío, habrá silencio.
@export var background_music: AudioStream

# ==============================================================================
# EFECTOS VISUALES (PARALLAX)
# ==============================================================================
@export_group("Visual Effects")
## Activa el movimiento sutil de cámara al mover el mouse
@export var use_mouse_parallax: bool = true

## Intensidad del movimiento (Píxeles máximos de desplazamiento)
@export var parallax_strength: float = 15.0 

## Suavizado del movimiento (Valores más bajos = más "pesado/lento")
@export var parallax_smoothness: float = 5.0

# ==============================================================================
# REFERENCIAS A NODOS
# ==============================================================================
## Referencia a la cámara. Si está vacía, intentará buscar "Camera2D".
@export var camera: Camera2D

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Inicialización de componentes
	_find_camera_reference()
	_setup_audio()
	
	print("GameLocation: Entrando a '%s'" % location_name)

func _process(delta: float) -> void:
	# Solo calculamos parallax si está activo y tenemos cámara
	if use_mouse_parallax and camera:
		_handle_mouse_parallax(delta)

# ==============================================================================
# LÓGICA DE INICIALIZACIÓN
# ==============================================================================
func _setup_audio() -> void:
	# Delegamos la lógica de transición al AudioManager
	if background_music:
		AudioManager.play_music(background_music)
	else:
		# Si no hay música asignada, pedimos detener la actual (Fade Out)
		AudioManager.play_music(null)

func _find_camera_reference() -> void:
	# Si no se asignó manualmente en el inspector, buscamos el nodo hijo
	if not camera:
		camera = get_node_or_null("Camera2D")
		
	if not camera and use_mouse_parallax:
		push_warning("GameLocation: 'use_mouse_parallax' activado pero no se encontró Camera2D.")

# ==============================================================================
# LÓGICA DE EFECTOS VISUALES
# ==============================================================================
func _handle_mouse_parallax(delta: float) -> void:
	# 1. Obtener dimensiones
	var viewport_rect = get_viewport_rect()
	var viewport_size = viewport_rect.size
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 2. Calcular posición relativa del mouse (-0.5 izquierda/arriba, +0.5 derecha/abajo)
	# Usamos clamp para asegurar que no se vuelva loco si el mouse sale de la ventana
	var rel_x = (mouse_pos.x / viewport_size.x) - 0.5
	var rel_y = (mouse_pos.y / viewport_size.y) - 0.5
	
	rel_x = clampf(rel_x, -0.5, 0.5)
	rel_y = clampf(rel_y, -0.5, 0.5)
	
	# 3. Calcular el objetivo de desplazamiento
	# Multiplicamos por parallax_strength para definir la distancia máxima
	var target_offset = Vector2(rel_x, rel_y) * parallax_strength
	
	# 4. Interpolación (Lerp) corregida con Delta
	# Esto asegura que la suavidad sea igual a 60FPS o 144FPS
	camera.offset = camera.offset.lerp(target_offset, parallax_smoothness * delta)
