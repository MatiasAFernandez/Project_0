extends Node

# ==============================================================================
# CONFIGURACIÓN Y CONSTANTES
# ==============================================================================
const ANIM_FADE_OUT: String = "fade_to_black"
const ANIM_FADE_IN: String = "fade_from_black"

## Velocidad de transición (1.0 = normal, 2.0 = rápido)
var transition_speed: float = 2.0

# ==============================================================================
# REFERENCIAS UI
# ==============================================================================
@onready var _curtain: ColorRect = $Curtain
@onready var _anim_player: AnimationPlayer = $AnimationPlayer

# ==============================================================================
# VARIABLES DE ESTADO
# ==============================================================================
var _is_transitioning: bool = false

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Este nodo debe funcionar siempre, incluso si el juego está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Aseguramos estado inicial limpio
	_reset_curtain()

# ==============================================================================
# LÓGICA DE DEBUG (#TODO)
# ==============================================================================
# TODO: ESTE BLOQUE ES SOLO PARA PRUEBAS DE INVENTARIO - ELIMINAR EN PRODUCCIÓN
func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return

	# Mapeo de Acciones a Recursos (Items)
	if event.is_action_pressed("ui_accept"):
		_debug_add_item("res://tests/items/PocionSalud.tres", 50)
	elif event.is_action_pressed("add_sword"):
		_debug_add_item("res://tests/items/Espada.tres", 1)
	elif event.is_action_pressed("add_backpack"):
		_debug_add_item("res://tests/items/Mochila.tres", 1)
	elif event.is_action_pressed("add_mastersword"):
		_debug_add_item("res://tests/items/EspadaMaestra.tres", 1)
	elif event.is_action_pressed("add_shield"):
		_debug_add_item("res://tests/items/Shield.tres", 1)
	elif event.is_action_pressed("add_daga"):
		_debug_add_item("res://tests/items/Daga.tres", 1)
	elif event.is_action_pressed("add_daga2"):
		_debug_add_item("res://tests/items/Daga2.tres", 1)
	elif event.is_action_pressed("add_belt"):
		_debug_add_item("res://tests/items/Belt.tres", 1)

# Helper para reducir la repetición del código de prueba
func _debug_add_item(path: String, amount: int) -> void:
	if ResourceLoader.exists(path):
		var item = load(path)
		PlayerSession.add_item(item, amount)
		print("DEBUG: Item añadido. Slots ocupados: ", PlayerSession.inventory.size())
	else:
		push_error("DEBUG ERROR: No se encontró el item en: " + path)

# ==============================================================================
# LÓGICA DE NAVEGACIÓN
# ==============================================================================

## Gestiona la transición suave entre escenas usando un fundido a negro.
func change_scene(scene_path: String) -> void:
	# Evitamos llamar a la transición si ya está ocurriendo una
	if _is_transitioning:
		return
	
	# Validación básica de ruta
	if not ResourceLoader.exists(scene_path):
		push_error("NavigationManager: La escena no existe en la ruta: " + scene_path)
		return
	
	_is_transitioning = true
	
	# 1. Bloquear input y mostrar telón
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	_curtain.visible = true
	
	# 2. Fade Out (Pantalla se va a negro)
	_anim_player.play(ANIM_FADE_OUT, -1, transition_speed)
	await _anim_player.animation_finished
	
	# 3. Lógica "Detrás del telón"
	# Reseteamos el cursor para que no quede el icono de "Interactuar" en la nueva escena
	CursorManager.reset_to_default()
	
	# Cambiamos la escena
	get_tree().change_scene_to_file(scene_path)
	
	# Esperamos un frame para asegurar que Godot procesó la destrucción/carga
	await get_tree().process_frame
	
	# Pequeña pausa técnica opcional para suavizar tirones de carga
	await get_tree().create_timer(0.05).timeout
	
	# 4. Fade In (Vuelve la imagen)
	_anim_player.play(ANIM_FADE_IN, -1, transition_speed)
	await _anim_player.animation_finished
	
	# 5. Limpieza final
	_reset_curtain()
	_is_transitioning = false

## Permite a otros scripts saber si estamos en transición sin modificar la variable.
func is_transitioning() -> bool:
	return _is_transitioning

# ==============================================================================
# MÉTODOS PRIVADOS
# ==============================================================================

func _reset_curtain() -> void:
	_curtain.visible = false
	_curtain.modulate.a = 0
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
