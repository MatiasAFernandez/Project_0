extends Node
class_name InventoryManager

signal inventory_updated

var base_slots: int = 20
var bonus_slots: int = 0
var inventory: Array[SlotData] = []

func get_max_slots() -> int:
	return base_slots + bonus_slots

func add_item(item: ItemData, quantity: int = 1) -> bool:
	if item == null: return false
	
	quantity = _stack_item(item, quantity)
	
	if quantity > 0:
		if not _create_new_slots(item, quantity):
			inventory_updated.emit()
			return false
	
	inventory_updated.emit()
	return true

func _stack_item(item: ItemData, quantity: int) -> int:
	for slot in inventory:
		if slot.item_data == item and slot.quantity < item.max_stack_size:
			var available = item.max_stack_size - slot.quantity
			var to_add = min(quantity, available)
			slot.quantity += to_add
			quantity -= to_add
			if quantity == 0: break
	return quantity

func _create_new_slots(item: ItemData, quantity: int) -> bool:
	while quantity > 0:
		if inventory.size() >= get_max_slots() and not item.is_quest_item:
			return false 
		var new_slot = SlotData.new()
		new_slot.item_data = item
		var to_add = min(quantity, item.max_stack_size)
		new_slot.quantity = to_add
		inventory.append(new_slot)
		quantity -= to_add
	return true

func remove_item_from_slot(slot: SlotData, amount: int = 1) -> void:
	slot.quantity -= amount
	if slot.quantity <= 0:
		inventory.erase(slot)
	inventory_updated.emit()

func consume_item(slot: SlotData) -> void:
	if not slot or not slot.item_data: return
	print("Consumiendo: ", slot.item_data.name)
	remove_item_from_slot(slot, 1)

func expand_capacity(extra_slots: int = 10) -> void:
	bonus_slots += extra_slots
	print("Capacidad de inventario aumentada a: ", get_max_slots())
	inventory_updated.emit()
