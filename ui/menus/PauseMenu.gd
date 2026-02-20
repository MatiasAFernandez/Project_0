extends Control
class_name PauseMenu

# ==============================================================================
# REFERENCIAS A NODOS
# ==============================================================================
# Contenedor principal de botones
@onready var _main_buttons: VBoxContainer = $MenuHolder/Center/Panel/VBoxContainer

# Botones
@onready var _btn_resume: Button = $MenuHolder/Center/Panel/VBoxContainer/BtnResume
@onready var _btn_main_menu: Button = $MenuHolder/Center/Panel/VBoxContainer/BtnMainMenu
@onready var _btn_save: Button = $MenuHolder/Center/Panel/VBoxContainer/BtnSave
@onready var _btn_load: Button = $MenuHolder/Center/Panel/VBoxContainer/BtnLoad
@onready var _btn_options: Button = $MenuHolder/Center/Panel/VBoxContainer/BtnOptions
@onready var _btn_exit: Button = $MenuHolder/Center/Panel/VBoxContainer/BtnExit

# Sub-menús y Diálogos
@onready var _options_menu: Control = $OptionsMenu
@onready var _exit_confirmation: ConfirmationDialog = $ExitConfirmation

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# El menú de pausa DEBE procesar siempre, de lo contrario no se podría despausar
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	_setup_connections()

func _setup_connections() -> void:
	# Conectar botones principales
	if _btn_resume: _btn_resume.pressed.connect(_on_resume_pressed)
	if _btn_main_menu: _btn_main_menu.pressed.connect(_on_mainmenu_pressed)
	if _btn_save: _btn_save.pressed.connect(_on_save_pressed)
	if _btn_load: _btn_load.pressed.connect(_on_load_pressed)
	if _btn_options: _btn_options.pressed.connect(_on_options_pressed)
	if _btn_exit: _btn_exit.pressed.connect(_on_exit_pressed)

	# Conectar sub-menús y diálogos
	if _exit_confirmation:
		_exit_confirmation.confirmed.connect(_on_exit_confirmed)
		_exit_confirmation.canceled.connect(_on_exit_canceled)
	
	if _options_menu and _options_menu.has_signal("closed"):
		_options_menu.closed.connect(_on_options_closed)

# ==============================================================================
# API PÚBLICA (Llamada desde UIManager)
# ==============================================================================
func pause() -> void:
	get_tree().paused = true
	
	# Asegurarnos de que el menú arranque en su estado inicial (Botones visibles)
	_reset_menu_state()
	
	visible = true

func resume() -> void:
	get_tree().paused = false
	visible = false
	
	# Por seguridad, cerramos sub-menús si quedaron abiertos
	if _options_menu and _options_menu.visible:
		_options_menu.close()

func _reset_menu_state() -> void:
	# Muestra los botones principales y oculta las opciones
	if _main_buttons:
		_main_buttons.visible = true
	if _options_menu:
		_options_menu.visible = false

# ==============================================================================
# ACCIONES DE BOTONES (CALLBACKS)
# ==============================================================================
#region Button Actions

func _on_resume_pressed() -> void:
	resume()

func _on_mainmenu_pressed() -> void:
	# TODO: Lógica para volver a la pantalla de título
	# Ejemplo: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	print("PauseMenu: Volviendo al menú principal (Pendiente)")

func _on_save_pressed() -> void:
	# TODO: Llamar a tu SaveManager
	print("PauseMenu: Guardar partida (Pendiente)")

func _on_load_pressed() -> void:
	# TODO: Mostrar UI de guardados o cargar rápido
	print("PauseMenu: Cargar partida (Pendiente)")

#endregion

# ==============================================================================
# MANEJO DE SUB-MENÚS (OPCIONES Y SALIDA)
# ==============================================================================
#region Sub-Menus

func _on_options_pressed() -> void:
	# Ocultamos los botones principales y abrimos el menú de opciones
	if _main_buttons:
		_main_buttons.visible = false
		
	if _options_menu:
		if _options_menu.has_method("open"):
			_options_menu.open()
		else:
			_options_menu.visible = true

func _on_options_closed() -> void:
	# Restauramos los botones principales cuando se cierra opciones
	if _options_menu and _options_menu.has_method("close"):
		_options_menu.close()
	
	if _main_buttons:
		_main_buttons.visible = true

func _on_exit_pressed() -> void:
	if _exit_confirmation:
		_exit_confirmation.popup_centered()

func _on_exit_confirmed() -> void:
	print("PauseMenu: Saliendo del juego...")
	# TODO: Guardar partida automáticamente antes de salir si es necesario
	get_tree().quit()

func _on_exit_canceled() -> void:
	if _exit_confirmation:
		_exit_confirmation.hide()

#endregion
