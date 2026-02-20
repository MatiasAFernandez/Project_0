extends ScrollContainer
class_name InventoryListDropZone

# ==============================================================================
# DRAG & DROP: VALIDACIÓN
# ==============================================================================
## Determina si esta zona (el fondo de la lista del inventario) acepta el objeto arrastrado.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# 1. Validamos que la estructura de datos sea la correcta
	if typeof(data) != TYPE_DICTIONARY:
		return false
		
	# 2. Solo aceptamos drops que vengan del cuerpo del jugador (equipment).
	# Si viene del propio inventario, devolverá false (evita acciones redundantes).
	return data.get("source") == "equipment"

# ==============================================================================
# DRAG & DROP: EJECUCIÓN
# ==============================================================================
## Se ejecuta cuando el jugador suelta el ítem de equipamiento sobre la lista.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source: String = data.get("source", "")
	
	if source == "equipment":
		var origin_slot: String = data.get("origin_slot", "")
		
		# Si tenemos un slot de origen válido, procedemos a desequipar
		if origin_slot != "":
			# Delegamos la lógica compleja (mover el ítem al inventario, recalcular stats) a PlayerSession
			PlayerSession.unequip_slot(origin_slot)
			
			# Opcional: Descomenta esto si necesitas depurar
			# print("InventoryDropZone: Ítem desequipado exitosamente desde '%s'." % origin_slot)
