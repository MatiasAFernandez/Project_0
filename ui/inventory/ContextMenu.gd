extends PanelContainer

signal action_selected

@onready var container: VBoxContainer = $VBoxContainer

var current_context: Dictionary = {}
# Variable para saber qué botón estamos señalando actualmente
var active_button: Button = null

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	# Solo procesamos input si el menú está visible
	if not visible:
		return

	if event is InputEventMouseButton:
		# Detectamos cuando se SUELTA el click derecho
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			_execute_selection()

func open(context: Dictionary, screen_position: Vector2) -> void:
	current_context = context
	var item = context.item
	var source = context.source
	
	global_position = screen_position
	
	for child in container.get_children():
		child.queue_free()
	active_button = null
	
	# --- GENERACIÓN DE BOTONES SEGÚN FUENTE ---
	_add_button("Investigar", _on_investigate)
	
	# CASO 1: Viene del EQUIPO (Lado izquierdo)
	if source == "equipment":
		_add_button("Desequipar", _on_unequip)
	
	# CASO 2: Viene del INVENTARIO (Lado derecho)
	elif source == "inventory":
		if item.type == ItemData.ItemType.CONSUMABLE:
			_add_button("Consumir", _on_consume)
		elif _is_equipment(item.type):
			_add_button("Equipar", _on_equip)
		
		# Solo se puede tirar desde el inventario (por seguridad)
		if not item.is_quest_item:
			var btn = _add_button("Tirar", _on_drop)
			btn.modulate = Color(1, 0.5, 0.5)

	visible = true
	
	# Ajuste de posición: movemos el menú un poco para que el mouse empiece
	# justo en el medio de la primera opción o en el centro de la lista
	await get_tree().process_frame
	reset_size()
	global_position -= size / 2 # Centrar en el mouse

func close() -> void:
	visible = false
	current_context = {}
	active_button = null

func _execute_selection() -> void:
	# Si soltamos el click y había un botón seleccionado, ejecutamos su acción
	if active_button:
		# Simulamos el click visualmente y ejecutamos el callback guardado en metadata
		active_button.pressed.emit() 
	
	# Siempre cerramos al soltar el click derecho
	close()

# --- GENERADOR DE BOTONES MEJORADO ---
func _add_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Importante: Mouse Filter en Pass o Stop para detectar entrada
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Guardamos la función a ejecutar dentro del propio botón
	# Conectamos la señal pressed al callback para poder llamarla con .emit()
	btn.pressed.connect(callback)
	
	container.add_child(btn)
	
	# CONEXIONES PARA EL TRACKING
	# Detectamos cuando el mouse entra/sale del botón MIENTRAS arrastramos
	btn.mouse_entered.connect(_on_btn_hover.bind(btn))
	btn.mouse_exited.connect(_on_btn_exit.bind(btn))
	
	return btn

# --- LÓGICA DE HOVER MANUAL ---
func _on_btn_hover(btn: Button) -> void:
	active_button = btn
	# Forzamos visualmente el estado "Hover" o "Pressed" para feedback
	btn.grab_focus() 

func _on_btn_exit(btn: Button) -> void:
	if active_button == btn:
		active_button = null
		btn.release_focus()

# --- TUS FUNCIONES DE ACCIÓN (Sin cambios) ---
# --- ACCIONES ACTUALIZADAS ---
func _on_investigate() -> void:
	# Usamos context.item
	print("Investigando: ", current_context.item.name)
	action_selected.emit()

func _on_consume() -> void:
	# El slot_ref es el InventorySlotUI o el SlotData, depende de cómo lo pases
	# Asumimos que context tiene 'slot_data' si viene de inventario
	if current_context.has("slot_data"):
		PlayerSession.consume_item(current_context.slot_data)
	action_selected.emit()

# --- ACCIONES ACTUALIZADAS ---

func _on_equip() -> void:
	# Esta función ahora solo maneja el "Equipar" desde el inventario
	if current_context.has("slot_data"):
		PlayerSession.auto_equip_from_inventory(current_context.slot_data)
	action_selected.emit()

func _on_unequip() -> void:
	# CAMBIO IMPORTANTE: Usamos el slot_name que viene del EquipmentSlotUI
	if current_context.has("slot_name"):
		PlayerSession.unequip_slot(current_context.slot_name)
	action_selected.emit()

func _on_drop() -> void:
	if current_context.has("slot_data"):
		var s = current_context.slot_data
		PlayerSession.remove_item_from_slot(s, s.quantity)
	action_selected.emit()
	
func _is_equipment(type: int) -> bool:
	return type != ItemData.ItemType.CONSUMABLE and \
		   type != ItemData.ItemType.QUEST and \
		   type != ItemData.ItemType.MISC
