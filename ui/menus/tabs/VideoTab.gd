extends Control
class_name VideoTab

# ==============================================================================
# REFERENCIAS A NODOS
# ==============================================================================
@onready var _resolution_option: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/ResolutionRow/ResolutionOption
@onready var _vsync_checkbox: CheckBox = $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/VsyncRow/CheckBox
@onready var _mode_option: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/WindowModeRow/OptionButton

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	_setup_ui_elements()
	_connect_signals()
	_sync_ui_from_backend()

func _setup_ui_elements() -> void:
	# Fallback por seguridad en caso de que VideoSettings no haya cargado
	if VideoSettings.available_resolutions.is_empty() and VideoSettings.has_method("_detect_resolutions"):
		VideoSettings._detect_resolutions()

	_populate_resolutions()
	_populate_modes()

func _connect_signals() -> void:
	# Señales de la UI (Usuario interactuando)
	_resolution_option.item_selected.connect(_on_resolution_selected)
	_vsync_checkbox.toggled.connect(_on_vsync_toggled)
	_mode_option.item_selected.connect(_on_mode_selected)
	
	# Señales del Backend (Cambios externos o código)
	VideoSettings.resolution_changed.connect(_sync_ui_from_backend)
	VideoSettings.vsync_changed.connect(_sync_ui_from_backend)
	VideoSettings.window_mode_changed.connect(_sync_ui_from_backend)

# ==============================================================================
# GENERACIÓN DE OPCIONES
# ==============================================================================
func _populate_resolutions() -> void:
	_resolution_option.clear()
	var screen_size = DisplayServer.screen_get_size()
	
	for res in VideoSettings.available_resolutions:
		var label := "%d x %d" % [res.x, res.y]
		if res == screen_size: 
			label += " (Nativa)"
		_resolution_option.add_item(label)

func _populate_modes() -> void:
	_mode_option.clear()
	_mode_option.add_item("Ventana")
	_mode_option.add_item("Pantalla Completa")
	_mode_option.add_item("Sin Bordes")

# ==============================================================================
# ACCIONES DE UI (CALLBACKS)
# ==============================================================================
func _on_resolution_selected(index: int) -> void:
	VideoSettings.set_resolution_by_index(index)

func _on_vsync_toggled(toggled: bool) -> void:
	VideoSettings.set_vsync(toggled)

func _on_mode_selected(index: int) -> void:
	VideoSettings.set_window_mode_by_index(index)

# ==============================================================================
# SINCRONIZACIÓN CON EL BACKEND
# ==============================================================================
func _sync_ui_from_backend() -> void:
	# 1. Sincronizar Modo de Ventana
	# En Godot 4, llamar a select() por código NO dispara la señal item_selected, 
	# así que es seguro hacerlo directamente.
	_mode_option.select(VideoSettings.current_window_mode_index)
	
	# 2. Sincronizar Resolución
	var current_res_idx = VideoSettings.current_resolution_index
	
	# Si el índice es desconocido (-1), intentamos deducirlo visualmente
	if current_res_idx == -1:
		current_res_idx = _find_current_resolution_index()
	
	if current_res_idx != -1 and current_res_idx < _resolution_option.item_count:
		_resolution_option.select(current_res_idx)
	else:
		# Fallback: Seleccionar la última opción disponible (usualmente la nativa) si falla
		_resolution_option.select(_resolution_option.item_count - 1)
	
	# Bloqueo Visual: Solo permitimos cambiar resolución manual si estamos en modo Ventana (Índice 0)
	_resolution_option.disabled = (VideoSettings.current_window_mode_index != 0)
		
	# 3. Sincronizar VSync
	# set_pressed_no_signal cambia el estado visual sin emitir "toggled"
	_vsync_checkbox.set_pressed_no_signal(VideoSettings.vsync_enabled)

# ==============================================================================
# HELPERS
# ==============================================================================
func _find_current_resolution_index() -> int:
	var current_size = DisplayServer.window_get_size()
	var res_list = VideoSettings.available_resolutions
	
	for i in range(res_list.size()):
		if res_list[i] == current_size:
			return i
			
	return -1
