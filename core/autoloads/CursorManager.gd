extends Node

# ==============================================================================
# DEFINICIONES Y CONSTANTES
# ==============================================================================
enum CursorType {
	DEFAULT,
	INTERACT,
	EXIT,
	TALK
}

## Configuración centralizada de los cursores.
## Mapea el Enum con su Textura y su Hotspot (Punto de clic).
const CURSOR_DATA: Dictionary = {
	CursorType.DEFAULT: {
		"texture": preload("res://assets/art/cursor/default.png"),
		"hotspot": Vector2.ZERO
	},
	CursorType.INTERACT: {
		"texture": preload("res://assets/art/cursor/hand.png"),
		"hotspot": Vector2.ZERO # Cambiar si la "punta del dedo" no es (0,0)
	},
	CursorType.EXIT: {
		"texture": preload("res://assets/art/cursor/3.png"),
		"hotspot": Vector2.ZERO
	},
	CursorType.TALK: {
		"texture": preload("res://assets/art/cursor/bottom.png"),
		"hotspot": Vector2.ZERO
	}
}

# ==============================================================================
# VARIABLES DE ESTADO
# ==============================================================================
var _current_cursor_type: CursorType = CursorType.DEFAULT

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Aseguramos que el cursor del sistema sea visible y controlado por nosotros
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reset_to_default()

# ==============================================================================
# LÓGICA PÚBLICA
# ==============================================================================

## Cambia el cursor actual al tipo especificado.
## Si ya es el actual, ignora la solicitud para ahorrar rendimiento.
func set_cursor(type: CursorType) -> void:
	if type == _current_cursor_type:
		return
	
	_current_cursor_type = type
	_apply_cursor_texture(type)

## Restaura el cursor a su estado por defecto.
func reset_to_default() -> void:
	set_cursor(CursorType.DEFAULT)
	# Aplicamos dos veces seguidas
	_apply_cursor_texture(CursorType.DEFAULT)
	await get_tree().process_frame
	_apply_cursor_texture(CursorType.DEFAULT)

# ==============================================================================
# LÓGICA PRIVADA
# ==============================================================================

func _apply_cursor_texture(type: CursorType) -> void:
	# Validación de seguridad: si el tipo no existe en el diccionario, usamos DEFAULT
	if not CURSOR_DATA.has(type):
		push_warning("CursorManager: Tipo de cursor no definido en CURSOR_DATA. Usando DEFAULT.")
		type = CursorType.DEFAULT
	
	var data: Dictionary = CURSOR_DATA[type]
	var texture: Texture2D = data["texture"]
	var hotspot: Vector2 = data["hotspot"]
	
	# Usamos DisplayServer (estándar de Godot 4)
	DisplayServer.cursor_set_custom_image(texture, DisplayServer.CURSOR_ARROW, hotspot)
