extends Node

# Instanciamos los subsistemas
var inv_manager: InventoryManager = InventoryManager.new()
var equip_manager: EquipmentManager = EquipmentManager.new()

# Variables globales que sí pertenecen aquí
var money: int = 0

# --- SEÑALES (Redirigidas desde los managers para compatibilidad hacia atrás) ---
signal inventory_updated
signal equipment_updated
signal gear_updated(slot_name: String)

# --- CONSTANTES DE SLOTS (Expuestas para compatibilidad) ---
const SLOT_HEAD      := "Head"
const SLOT_CHEST     := "Chest"
const SLOT_CAPE      := "Cape"
const SLOT_BELT      := "Belt"
const SLOT_ARMS      := "Arms"
const SLOT_BOOTS     := "Boots"
const SLOT_MAIN_HAND := "MainHand"
const SLOT_OFF_HAND  := "OffHand"

func _ready() -> void:
	# Inicializamos la jerarquía
	add_child(inv_manager)
	add_child(equip_manager)
	
	# Le damos al gestor de equipo acceso al inventario
	equip_manager.setup(inv_manager)
	
	# Conectamos las señales internas a las globales
	inv_manager.inventory_updated.connect(func(): inventory_updated.emit())
	equip_manager.equipment_updated.connect(func(): equipment_updated.emit())
	equip_manager.gear_updated.connect(func(slot): gear_updated.emit(slot))

# ==============================================================================
# FACHADA: INVENTARIO (Redirige las llamadas al InventoryManager)
# ==============================================================================
var inventory: Array[SlotData]:
	get: return inv_manager.inventory
	set(val): inv_manager.inventory = val

func get_max_inventory_slots() -> int:
	return inv_manager.get_max_slots()

func add_item(item: ItemData, quantity: int = 1) -> bool:
	return inv_manager.add_item(item, quantity)

func remove_item_from_slot(slot: SlotData, amount: int = 1) -> void:
	inv_manager.remove_item_from_slot(slot, amount)

func consume_item(slot: SlotData) -> void:
	inv_manager.consume_item(slot)

func expand_inventory_capacity(extra_slots: int = 10) -> void:
	inv_manager.expand_capacity(extra_slots)

# ==============================================================================
# FACHADA: EQUIPAMIENTO (Redirige las llamadas al EquipmentManager)
# ==============================================================================
var equipped_gear: Dictionary:
	get: return equip_manager.equipped_gear

func get_gear_in_slot(slot_name: String) -> ItemData:
	return equip_manager.get_gear_in_slot(slot_name)

func equip_item_to_slot(inventory_slot: SlotData, target_slot: String) -> void:
	equip_manager.equip_item_to_slot(inventory_slot, target_slot)

func can_equip_in_slot(item, slot): 
	return equip_manager.can_equip_in_slot(item, slot)

func unequip_slot(slot_name: String) -> void:
	equip_manager.unequip_slot(slot_name)

func auto_equip_from_inventory(inventory_slot: SlotData) -> void:
	equip_manager.auto_equip_from_inventory(inventory_slot)

func swap_slots(from_slot: String, to_slot: String) -> void:
	equip_manager.swap_slots(from_slot, to_slot)

func get_best_slot_for_item(item: ItemData) -> String:
	return equip_manager.get_best_slot_for_item(item)

func destroy_equipment_in_slot(slot_name: String) -> void:
	equip_manager.destroy_equipment_in_slot(slot_name)
