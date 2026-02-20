extends Resource
class_name SlotData

# ==============================================================================
# SEÑALES
# ==============================================================================
## Emitida automáticamente cuando cambian los datos o la cantidad de este slot
signal slot_updated

# ==============================================================================
# DATOS DEL SLOT
# ==============================================================================
@export var item_data: ItemData:
	set(value):
		item_data = value
		slot_updated.emit()
		emit_changed() # Señal nativa de la clase Resource

@export_range(1, 999) var quantity: int = 1:
	set(value):
		quantity = maxi(0, value) # Evita que la cantidad sea negativa
		slot_updated.emit()
		emit_changed()

# ==============================================================================
# MÉTODOS DE VALIDACIÓN
# ==============================================================================

## Devuelve true si el slot no tiene ningún ítem o su cantidad es 0
func is_empty() -> bool:
	return item_data == null or quantity <= 0

## Calcula cuánto espacio libre queda en este slot para el ítem actual
func get_free_space() -> int:
	if is_empty():
		return 0
	return item_data.max_stack_size - quantity

## Devuelve true si ambos slots tienen exactamente el mismo ítem
func is_same_item_as(other_slot: SlotData) -> bool:
	if is_empty() or other_slot.is_empty():
		return false
	return item_data == other_slot.item_data

# ==============================================================================
# MÉTODOS DE APILAMIENTO (STACKING)
# ==============================================================================

## Verifica si TODO el contenido del otro slot cabe en este
func can_fully_merge_with(other_slot: SlotData) -> bool:
	if not is_same_item_as(other_slot):
		return false
	return get_free_space() >= other_slot.quantity

## Une completamente los slots (Asume que ya verificaste con can_fully_merge_with)
func fully_merge_with(other_slot: SlotData) -> void:
	quantity += other_slot.quantity
	# Vaciamos el slot original ya que movimos todo
	other_slot.item_data = null
	other_slot.quantity = 0

## Une todo lo que pueda, y deja el sobrante en el otro slot.
## Útil cuando intentas meter 10 ítems pero solo hay espacio para 4.
func merge_with(other_slot: SlotData) -> void:
	if not is_same_item_as(other_slot):
		return
		
	var available_space = get_free_space()
	
	if available_space > 0:
		# Calculamos cuánto podemos pasar realmente
		var amount_to_move = mini(available_space, other_slot.quantity)
		
		# Transferimos las cantidades
		quantity += amount_to_move
		other_slot.quantity -= amount_to_move
		
		# Si el otro slot se quedó vacío, lo limpiamos por seguridad
		if other_slot.quantity == 0:
			other_slot.item_data = null
