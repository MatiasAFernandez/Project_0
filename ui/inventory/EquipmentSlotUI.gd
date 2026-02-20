extends TextureRect

# ==============================================================================
# CONFIGURACIÓN
# ==============================================================================
## Nombre exacto del slot en PlayerSession (ej. "MainHand", "Head")
@export var slot_name: String = "MainHand"

## Icono de fondo cuando está vacío (silueta)
@export var placeholder_icon: Texture2D

# Referencia al TextureRect hijo que muestra el ítem real
@onready var item_icon: TextureRect = $ItemIcon

# Señal para el menú contextual (Click Derecho)
signal slot_right_clicked(context: Dictionary, global_pos: Vector2)

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Conectamos la señal global de actualización de equipo
	# Usamos bind para saber si la actualización nos afecta a nosotros
	PlayerSession.equipment_updated.connect(refresh_slot)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Configuración inicial
	item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	refresh_slot()

# ==============================================================================
# LÓGICA DE VISUALIZACIÓN
# ==============================================================================
func refresh_slot() -> void:
	var item = PlayerSession.get_gear_in_slot(slot_name)
	
	# 1. CASO ESPECIAL: "Fantasma" de Arma a 2 Manos en la mano izquierda
	if slot_name == PlayerSession.SLOT_OFF_HAND and item == null:
		var main_item = PlayerSession.get_gear_in_slot(PlayerSession.SLOT_MAIN_HAND)
		if main_item and main_item.type == ItemData.ItemType.WEAPON_HEAVY:
			_set_visuals(main_item.icon, true) # true = es fantasma (transparente)
			return

	# 2. CASO NORMAL: Hay ítem o está vacío
	if item:
		_set_visuals(item.icon, false)
	else:
		_set_placeholder()

func _set_visuals(new_texture: Texture2D, is_ghost: bool) -> void:
	item_icon.texture = new_texture
	item_icon.visible = true
	
	if is_ghost:
		item_icon.modulate = Color(1, 1, 1, 0.3) # Muy transparente
		self.modulate = Color(1, 1, 1, 0.5)      # Oscurecer el fondo también
	else:
		item_icon.modulate = Color(1, 1, 1, 1.0) # Opaco
		self.modulate = Color(1, 1, 1, 1.0)

func _set_placeholder() -> void:
	# Si no hay ítem, ocultamos el icono del item
	item_icon.visible = false
	item_icon.texture = null
	
	# Y mostramos la textura del propio slot como placeholder (si existe)
	if placeholder_icon:
		texture = placeholder_icon
		self.modulate = Color(1, 1, 1, 0.5) # Un poco oscuro para que se vea vacío
	else:
		# Si no hay placeholder, dejamos el slot limpio
		self.modulate = Color(1, 1, 1, 1.0)

# ==============================================================================
# INPUT DEL USUARIO (MOUSE)
# ==============================================================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# CLICK DERECHO: Menú Contextual / Desequipar rápido
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var item = PlayerSession.get_gear_in_slot(slot_name)
			if item:
				var context = { 
					"item": item, 
					"source": "equipment", 
					"slot_name": slot_name 
				}
				slot_right_clicked.emit(context, get_global_mouse_position())
		
		# CLICK IZQUIERDO (Opcional): Si quieres desequipar con click simple
		# o iniciar drag manualmente si Godot no lo detecta bien

# --- TOOLTIPS ---

func _on_mouse_entered() -> void:
	var item = PlayerSession.get_gear_in_slot(slot_name)
	if not item: return
	
	# Buscamos el inventario para pedirle que muestre el tooltip
	# Nota: Es seguro usar "InventoryUI" como grupo si añadiste el nodo principal a ese grupo
	var ui = get_tree().get_first_node_in_group("InventoryUI")
	if ui and ui.has_method("show_equipment_tooltip"):
		ui.show_equipment_tooltip(item)

func _on_mouse_exited() -> void:
	var ui = get_tree().get_first_node_in_group("InventoryUI")
	if ui and ui.has_method("hide_all_tooltips"):
		ui.hide_all_tooltips()

# ==============================================================================
# DRAG & DROP (ARRASTRAR Y SOLTAR)
# ==============================================================================

func _get_drag_data(_at_position: Vector2) -> Variant:
	var item = PlayerSession.get_gear_in_slot(slot_name)
	if not item: return null
	
	# Datos que llevamos al arrastrar
	var data = {
		"item": item,
		"source": "equipment",
		"origin_slot": slot_name
	}
	
	# Preview Visual (Lo que se ve pegado al mouse)
	var preview = TextureRect.new()
	preview.texture = item.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	preview.modulate.a = 0.8
	
	var c = Control.new()
	c.add_child(preview)
	preview.position = -preview.size / 2
	set_drag_preview(c)
	
	return data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# 1. Validar formato de datos
	if typeof(data) != TYPE_DICTIONARY or not data.has("item"):
		return false
	
	var incoming_item: ItemData = data.item
	
	# 2. Delegar la decisión al Gestor de Equipamiento
	return PlayerSession.can_equip_in_slot(incoming_item, slot_name)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# 1. Validación de seguridad absoluta
	if typeof(data) != TYPE_DICTIONARY or not data.has("source"):
		return
		
	# 2. Procesamiento según el origen del Drag & Drop
	match data.source:
		"inventory":
			# Caso A: Arrastrar desde Inventario -> Equipar
			if data.has("origin_slot_data") and data.origin_slot_data != null:
				PlayerSession.equip_item_to_slot(data.origin_slot_data, slot_name)
				
		"equipment":
			# Caso B: Arrastrar desde otro slot de equipo -> Intercambiar (Swap)
			if data.has("origin_slot"):
				var from_slot = data.origin_slot
				# Evitamos que el jugador intercambie un ítem consigo mismo
				if from_slot != slot_name:
					PlayerSession.swap_slots(from_slot, slot_name)
		_:
			# Si en el futuro arrastras desde una tienda o un cofre, lo manejarás aquí
			push_warning("EquipmentSlotUI: Origen de drag desconocido ('%s')" % data.source)
