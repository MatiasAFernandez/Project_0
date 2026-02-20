extends ColorRect
class_name InventoryDropZone

# ==============================================================================
# DRAG & DROP: VALIDACIÓN
# ==============================================================================
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# 1. Validar que la información arrastrada sea un diccionario correcto
	if typeof(data) != TYPE_DICTIONARY or not data.has("item"):
		return false
		
	var item: ItemData = data.get("item")
	
	# 2. Reglas de negocio: Los objetos clave (Misión/Quest) no se pueden tirar
	if item and item.is_quest_item:
		return false
		
	return true

# ==============================================================================
# DRAG & DROP: EJECUCIÓN
# ==============================================================================
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source: String = data.get("source", "")
	
	# Dependiendo de dónde venga el ítem, ejecutamos una acción distinta
	match source:
		"inventory":
			_handle_drop_from_inventory(data)
			
		"equipment":
			_handle_drop_from_equipment(data)

# ==============================================================================
# HELPERS DE ELIMINACIÓN PRIVADOS
# ==============================================================================

func _handle_drop_from_inventory(data: Dictionary) -> void:
	var slot_data: SlotData = data.get("origin_slot_data")
	
	if slot_data:
		# Borramos la cantidad total que tenga el stack en ese slot del inventario
		PlayerSession.remove_item_from_slot(slot_data, slot_data.quantity)
		print("DropZone: '%s' descartado desde el inventario." % slot_data.item_data.name)
		
		# TODO: Instanciar el objeto físico en el mundo si en lugar de "destruir", 
		# quieres que el ítem caiga al suelo.

func _handle_drop_from_equipment(data: Dictionary) -> void:
	var slot_name: String = data.get("origin_slot", "")
	
	if slot_name != "":
		# Le damos la orden centralizada a PlayerSession para que maneje toda la lógica
		# de destrucción (vaciar slot, actualizar UI, recalcular stats).
		PlayerSession.destroy_equipment_in_slot(slot_name)
