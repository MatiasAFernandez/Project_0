extends Button
class_name InventorySlotUI

# ==============================================================================
# SEÑALES
# ==============================================================================
## Se emite al hacer clic derecho para abrir el menú contextual
signal slot_right_clicked(context: Dictionary, global_pos: Vector2)

# ==============================================================================
# REFERENCIAS UI
# ==============================================================================
# Ajusta las rutas si tu estructura de nodos es diferente
@onready var icon_node: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var quantity_label: Label = $HBoxContainer/QuantityLabel

# ==============================================================================
# DATOS
# ==============================================================================
var _slot_data: SlotData

# ==============================================================================
# CICLO DE VIDA Y CONFIGURACIÓN
# ==============================================================================
func _ready() -> void:
	# Aseguramos que el botón capture clicks derechos e izquierdos
	button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
	
	# Opcional: Configuración visual del botón
	focus_mode = Control.FOCUS_NONE # Evita que se quede marcado al hacer clic

## Asigna los datos y actualiza la visualización
func set_slot_data(new_slot_data: SlotData) -> void:
	_slot_data = new_slot_data
	
	if not _slot_data or not _slot_data.item_data:
		_clear_slot()
		return
		
	var item = _slot_data.item_data
	
	# 1. Icono
	icon_node.texture = item.icon
	
	# 2. Nombre y Rareza (Color)
	name_label.text = item.name
	# Obtenemos el color hexadecimal del diccionario de ItemData y lo convertimos a Color
	var hex_color = ItemData.RARITY_COLORS.get(item.rarity, "ffffff")
	name_label.modulate = Color(hex_color)
	
	# 3. Cantidad
	if _slot_data.quantity > 1:
		quantity_label.text = "x%d" % _slot_data.quantity
		quantity_label.visible = true
	else:
		quantity_label.text = ""
		quantity_label.visible = false

func _clear_slot() -> void:
	icon_node.texture = null
	name_label.text = ""
	quantity_label.text = ""

# ==============================================================================
# INPUT DEL USUARIO (CLICK DERECHO)
# ==============================================================================
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if _slot_data and _slot_data.item_data:
				# Creamos el contexto para el InventoryUI
				var context = {
					"item": _slot_data.item_data,
					"source": "inventory",
					"slot_data": _slot_data, # Datos reales para borrar/consumir
					"ui_node": self          # Referencia a este nodo por si acaso
				}
				slot_right_clicked.emit(context, get_global_mouse_position())

# ==============================================================================
# SISTEMA DRAG & DROP
# ==============================================================================

# 1. INICIAR ARRASTRE (Drag)
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not _slot_data or not _slot_data.item_data:
		return null
		
	var data = {
		"item": _slot_data.item_data,
		"source": "inventory",
		"origin_slot_data": _slot_data
	}
	
	# Crear Preview Visual
	var preview = TextureRect.new()
	preview.texture = icon_node.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	preview.modulate.a = 0.8
	
	# Centrar en el mouse
	var control = Control.new()
	control.add_child(preview)
	preview.position = -preview.size / 2
	set_drag_preview(control)
	
	return data

# 2. VALIDAR SOLTADO (Can Drop)
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Verificamos que sea un diccionario válido con items
	if typeof(data) == TYPE_DICTIONARY and data.has("item"):
		
		# CASO A: Viene del EQUIPO -> Permitimos desequipar aquí
		if data.get("source") == "equipment":
			return true
			
		# CASO B: Viene de OTRO SLOT de Inventario (Reordenar/Stackear)
		# (Pendiente de implementar lógica compleja de swap en PlayerSession)
		# if data.get("source") == "inventory" and data.origin_slot_data != _slot_data:
		# 	return true
			
	return false

# 3. FINALIZAR SOLTADO (Drop)
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source = data.get("source")
	
	if source == "equipment":
		# El jugador arrastró un casco/arma hacia este slot del inventario.
		# Acción: Desequipar ese slot.
		var slot_name = data.get("origin_slot") # Viene de EquipmentSlotUI
		if slot_name:
			PlayerSession.unequip_slot(slot_name)
