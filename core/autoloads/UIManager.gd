extends CanvasLayer

# ==============================================================================
# REFERENCIAS A UI
# ==============================================================================
# Asegúrate de que los nombres de los nodos en la escena coincidan con estos
@onready var _pause_menu: Control = $PauseMenu
@onready var _inventory_ui: Control = $InventoryUI
@onready var _hud: Control = $GameHUD # Referencia al HUD (Vida, Mana, etc.)

# ==============================================================================
# VARIABLES DE ESTADO
# ==============================================================================
## Indica si hay alguna interfaz abierta que bloquee el juego (Inventario, Diálogos, etc.)
var is_ui_blocking: bool = false

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# El UIManager siempre debe procesar input, incluso cuando el juego está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_initialize_ui_state()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Tecla ESC
		_handle_cancel_input()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("toggle_inventory"): # Tecla I / Tab
		_handle_inventory_input()

# ==============================================================================
# MANEJO DE INPUTS (LÓGICA)
# ==============================================================================

## Gestiona la tecla ESC (Cancelar/Atrás)
func _handle_cancel_input() -> void:
	# 1. Prioridad: Si el inventario (u otro menú de juego) está abierto, lo cerramos primero.
	if _inventory_ui.visible:
		toggle_inventory()
		return

	# 2. Si no hay menús abiertos, alternamos la Pausa.
	toggle_pause()

## Gestiona la tecla de Inventario
func _handle_inventory_input() -> void:
	# No permitimos abrir el inventario si el juego está en Pausa real
	if _pause_menu.visible:
		return
	
	toggle_inventory()

# ==============================================================================
# MÉTODOS PÚBLICOS DE CONTROL
# ==============================================================================

## Alterna el estado de pausa del juego.
func toggle_pause() -> void:
	if _pause_menu.visible:
		_unpause_game()
	else:
		_pause_game()

## Alterna la visibilidad del inventario.
func toggle_inventory() -> void:
	if _inventory_ui.visible:
		_close_inventory()
	else:
		_open_inventory()

# ==============================================================================
# MÉTODOS PRIVADOS (ESTADO INTERNO)
# ==============================================================================

func _initialize_ui_state() -> void:
	# Estado inicial: Todo cerrado, HUD visible
	_pause_menu.visible = false
	_inventory_ui.visible = false
	_update_hud_visibility(true)
	is_ui_blocking = false

# --- LÓGICA DE PAUSA ---

func _pause_game() -> void:
	# Asumimos que PauseMenu tiene una función 'pause()' que maneja get_tree().paused
	if _pause_menu.has_method("pause"):
		_pause_menu.pause()
	else:
		# Fallback por si PauseMenu no tiene el script esperado
		_pause_menu.visible = true
		get_tree().paused = true
	
	is_ui_blocking = true
	_update_hud_visibility(false)

func _unpause_game() -> void:
	if _pause_menu.has_method("resume"):
		_pause_menu.resume()
	else:
		_pause_menu.visible = false
		get_tree().paused = false
		
	is_ui_blocking = false
	_update_hud_visibility(true)

# --- LÓGICA DE INVENTARIO ---

func _open_inventory() -> void:
	if _inventory_ui.has_method("open_inventory"):
		_inventory_ui.open_inventory()
	else:
		_inventory_ui.visible = true
		
	is_ui_blocking = true
	# Opcional: ¿Quieres ocultar el HUD al abrir el inventario? 
	# Si sí, descomenta la siguiente línea:
	# _update_hud_visibility(false)

func _close_inventory() -> void:
	if _inventory_ui.has_method("close_inventory"):
		_inventory_ui.close_inventory()
	else:
		_inventory_ui.visible = false
		
	is_ui_blocking = false
	# Restauramos el HUD si lo ocultamos
	# _update_hud_visibility(true)

# --- HELPERS ---

func _update_hud_visibility(should_be_visible: bool) -> void:
	if _hud:
		_hud.visible = should_be_visible
