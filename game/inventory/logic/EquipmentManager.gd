extends Node
class_name EquipmentManager

signal equipment_updated
signal gear_updated(slot_name: String)

const SLOT_HEAD      := "Head"
const SLOT_CHEST     := "Chest"
const SLOT_CAPE      := "Cape"
const SLOT_BELT      := "Belt"
const SLOT_ARMS      := "Arms"
const SLOT_BOOTS     := "Boots"
const SLOT_MAIN_HAND := "MainHand"
const SLOT_OFF_HAND  := "OffHand"

var equipped_gear: Dictionary = {
	SLOT_HEAD: null, SLOT_CHEST: null, SLOT_CAPE: null, SLOT_BELT: null,
	SLOT_ARMS: null, SLOT_BOOTS: null, SLOT_MAIN_HAND: null, SLOT_OFF_HAND: null
}

# Referencia al inventario para poder desequipar ítems
var _inventory_manager: InventoryManager

func setup(inventory_manager: InventoryManager) -> void:
	_inventory_manager = inventory_manager

func get_gear_in_slot(slot_name: String) -> ItemData:
	return equipped_gear.get(slot_name)

func equip_item_to_slot(inventory_slot: SlotData, target_slot: String) -> void:
	var item_to_equip = inventory_slot.item_data
	
	if not can_equip_in_slot(item_to_equip, target_slot):
		print("EquipmentManager: Item no permitido en slot ", target_slot)
		return

	_handle_equipment_conflicts(item_to_equip, target_slot)
	var previously_equipped = equipped_gear[target_slot]
	
	if previously_equipped != null:
		if not _inventory_manager.add_item(previously_equipped, 1):
			print("ADVERTENCIA: Inventario lleno. No se puede desequipar.")
			return 
	
	equipped_gear[target_slot] = item_to_equip
	_inventory_manager.remove_item_from_slot(inventory_slot, 1)
	_emit_gear_update(target_slot)

func unequip_slot(slot_name: String) -> void:
	var item = equipped_gear[slot_name]
	if item == null: return
	
	if _inventory_manager.add_item(item, 1):
		equipped_gear[slot_name] = null
		_emit_gear_update(slot_name)
	else:
		print("Inventario lleno, no se puede desequipar.")

func auto_equip_from_inventory(inventory_slot: SlotData) -> void:
	var item = inventory_slot.item_data
	var target_slot = get_best_slot_for_item(item)
	if target_slot != "":
		equip_item_to_slot(inventory_slot, target_slot)

func swap_slots(from_slot: String, to_slot: String) -> void:
	var item_moving = equipped_gear[from_slot]
	var item_displaced = equipped_gear[to_slot]
	
	if item_moving and not can_equip_in_slot(item_moving, to_slot):
		_emit_all_gear_updates() 
		return

	if item_displaced and not can_equip_in_slot(item_displaced, from_slot):
		_handle_asymmetric_swap(from_slot, to_slot, item_moving, item_displaced)
		return

	equipped_gear[to_slot] = item_moving
	equipped_gear[from_slot] = item_displaced
	_emit_gear_update(from_slot)
	_emit_gear_update(to_slot)

func destroy_equipment_in_slot(slot_name: String) -> void:
	if equipped_gear.has(slot_name) and equipped_gear[slot_name] != null:
		equipped_gear[slot_name] = null
		gear_updated.emit(slot_name)
		equipment_updated.emit()
	else:
		push_warning("Intento de destruir ítem en slot vacío: " + slot_name)

# --- REGLAS PRIVADAS (Idénticas a tu código original) ---

func can_equip_in_slot(item: ItemData, slot: String) -> bool:
	if item == null: return true 
	match slot:
		SLOT_MAIN_HAND: return item.type != ItemData.ItemType.SHIELD
		SLOT_OFF_HAND:
			if item.type == ItemData.ItemType.SHIELD: return true
			if item is WeaponData and item.is_dual_wieldable: return true
			return false
		SLOT_HEAD: return item.type == ItemData.ItemType.HELMET
		SLOT_CHEST: return item.type == ItemData.ItemType.CHEST
		SLOT_ARMS: return item.type == ItemData.ItemType.ARMS
		SLOT_BOOTS: return item.type == ItemData.ItemType.BOOTS
		SLOT_BELT: return item.type == ItemData.ItemType.BELT 
		_: return false

func _handle_asymmetric_swap(from_slot: String, to_slot: String, item_moving: ItemData, item_displaced: ItemData) -> void:
	if _inventory_manager.add_item(item_displaced, 1):
		equipped_gear[to_slot] = item_moving
		equipped_gear[from_slot] = null
	_emit_gear_update(from_slot)
	_emit_gear_update(to_slot)

func _handle_equipment_conflicts(item: ItemData, target_slot: String) -> void:
	if item.type == ItemData.ItemType.WEAPON_HEAVY:
		if target_slot == SLOT_MAIN_HAND: unequip_slot(SLOT_OFF_HAND)
	if target_slot == SLOT_OFF_HAND:
		var main_hand = equipped_gear[SLOT_MAIN_HAND]
		if main_hand and main_hand.type == ItemData.ItemType.WEAPON_HEAVY:
			unequip_slot(SLOT_MAIN_HAND)

func get_best_slot_for_item(item: ItemData) -> String:
	if item is WeaponData and item.is_dual_wieldable:
		return _get_slot_for_dual_wield(item)
	match item.type:
		ItemData.ItemType.SHIELD:       return SLOT_OFF_HAND
		ItemData.ItemType.WEAPON_HEAVY: return SLOT_MAIN_HAND
		ItemData.ItemType.WEAPON_MEDIUM:return SLOT_MAIN_HAND
		ItemData.ItemType.HELMET:       return SLOT_HEAD
		ItemData.ItemType.CHEST:        return SLOT_CHEST
		ItemData.ItemType.CAPE:         return SLOT_CAPE
		ItemData.ItemType.BELT:         return SLOT_BELT
		ItemData.ItemType.ARMS:         return SLOT_ARMS
		ItemData.ItemType.BOOTS:        return SLOT_BOOTS
		_: return ""

func _get_slot_for_dual_wield(_item: ItemData) -> String:
	var off = equipped_gear[SLOT_OFF_HAND]
	if off and off.type == ItemData.ItemType.SHIELD: return SLOT_MAIN_HAND
	if equipped_gear[SLOT_MAIN_HAND] == null: return SLOT_MAIN_HAND
	if equipped_gear[SLOT_OFF_HAND] == null: return SLOT_OFF_HAND
	return SLOT_MAIN_HAND

func _emit_gear_update(slot: String) -> void:
	gear_updated.emit(slot)
	equipment_updated.emit()

func _emit_all_gear_updates() -> void:
	for slot in equipped_gear.keys(): gear_updated.emit(slot)
	equipment_updated.emit()
