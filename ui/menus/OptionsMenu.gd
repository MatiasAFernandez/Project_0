extends Control
class_name OptionsMenu

# ==============================================================================
# SEÑALES
# ==============================================================================
signal closed

# ==============================================================================
# REFERENCIAS A NODOS
# ==============================================================================
# Usamos el guion bajo (_) para indicar que estos nodos son privados a este script
@onready var _panel: PanelContainer = $Root/Panel
@onready var _dimmer: ColorRect = $Dimmer
@onready var _btn_back: Button = $Root/Panel/MarginContainer/VBoxContainer/Footer/BtnBack
@onready var _btn_reset: Button = $Root/Panel/MarginContainer/VBoxContainer/Footer/BtnReset
@onready var _reset_confirm: ConfirmationDialog = $ResetConfirmDialog

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Asegura que el menú atrape los clics y no traspasen al juego
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	
	_setup_connections()
	_setup_initial_state()

func _setup_connections() -> void:
	# Responsive design (redimensionamiento)
	get_viewport().size_changed.connect(_on_viewport_resized)

	# Botones
	_btn_back.pressed.connect(_on_back_pressed)
	_btn_reset.pressed.connect(_on_reset_pressed)
	
	# Confirmación de Reset
	if _reset_confirm:
		_reset_confirm.confirmed.connect(_on_reset_confirmed)

	# Escuchar cambios globales para activar/desactivar el botón Reset dinámicamente
	if SettingsManager.has_signal("configuration_changed"):
		SettingsManager.configuration_changed.connect(_update_reset_button_state)

func _setup_initial_state() -> void:
	# Forzar invisibilidad al inicio para evitar parpadeos visuales en el editor/juego
	if _reset_confirm:
		_reset_confirm.visible = false
		
	_update_reset_button_state()
	_center_panel()

# ==============================================================================
# CONTROL DEL MENÚ (API PÚBLICA)
# ==============================================================================
func open() -> void:
	# Al abrir, verificamos el estado del botón por si algo cambió externamente
	_update_reset_button_state()
	
	_dimmer.visible = true
	visible = true

func close() -> void:
	visible = false
	_dimmer.visible = false

# ==============================================================================
# LÓGICA DE RESET
# ==============================================================================
func _on_reset_pressed() -> void:
	if _reset_confirm:
		_reset_confirm.popup_centered()

func _on_reset_confirmed() -> void:
	# Llamamos al manager central para que restaure todo.
	# No actualizamos la UI aquí porque SettingsManager emitirá 
	# 'configuration_changed' y la UI se actualizará sola gracias a la señal.
	SettingsManager.reset_to_defaults()

func _update_reset_button_state() -> void:
	# Si la configuración es idéntica a la default, desactivamos el botón
	if _btn_reset and SettingsManager.has_method("is_configuration_default"):
		var is_default = SettingsManager.is_configuration_default()
		_btn_reset.disabled = is_default

# ==============================================================================
# LÓGICA VISUAL Y NAVEGACIÓN
# ==============================================================================
func _on_back_pressed() -> void:
	# Emitimos la señal para quien haya instanciado/abierto este menú
	closed.emit()
	close()

func _center_panel() -> void:
	if _panel:
		# Forzamos redibujado. 
		# Nota: Si el panel no se está centrando correctamente al cambiar la resolución,
		# asegúrate de que el nodo 'Root' sea un CenterContainer, o que '_panel' 
		# tenga sus 'Anchors Preset' en 'Center'.
		_panel.queue_redraw()

func _on_viewport_resized() -> void:
	_center_panel()
