extends Area2D

# ==============================================================================
# CONFIGURACIÓN DEL ÁREA
# ==============================================================================
## La escena a la que viajaremos al hacer clic.
@export_file("*.tscn") var target_scene: String

## Tipo de cursor que se mostrará al pasar el mouse por encima.
@export var cursor_type: CursorManager.CursorType = CursorManager.CursorType.INTERACT

## Sonido opcional al hacer clic. Si se deja vacío, no suena nada.
@export var interaction_sound: AudioStream

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Conectamos las señales de mouse dinámicamente
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

# ==============================================================================
# EVENTOS DE INPUT (CLIC)
# ==============================================================================
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Filtramos solo el clic izquierdo presionado
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_interaction()

func _handle_interaction() -> void:
	# 1. Bloqueo de seguridad: Si ya estamos viajando, ignorar clics
	if NavigationManager.is_transitioning():
		return

	# 2. Feedback Auditivo
	if interaction_sound:
		AudioManager.play_sfx(interaction_sound)
	
	# 3. Navegación
	if target_scene:
		print("ClickableArea: Viajando a -> ", target_scene)
		NavigationManager.change_scene(target_scene)
	else:
		push_warning("ClickableArea: Se hizo clic pero no hay 'target_scene' asignada.")

# ==============================================================================
# EVENTOS DE MOUSE (HOVER)
# ==============================================================================
func _on_mouse_entered() -> void:
	# Evitamos cambiar el cursor si el juego está en plena transición (pantalla negra)
	if NavigationManager.is_transitioning():
		return
	
	CursorManager.set_cursor(cursor_type)

func _on_mouse_exited() -> void:
	# Al salir, siempre restauramos, excepto si estamos en transición (el manager se encarga ahí)
	if NavigationManager.is_transitioning():
		return
		
	CursorManager.reset_to_default()
