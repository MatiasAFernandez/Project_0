extends Resource
class_name ItemData

# ==============================================================================
# ENUMS (Se mantienen en la base para acceso global)
# ==============================================================================
enum ItemType {
	CONSUMABLE, HELMET, CHEST, ARMS, BOOTS, BELT, CAPE,
	WEAPON_SHORT, WEAPON_MEDIUM, WEAPON_HEAVY, SHIELD, QUEST, MISC
}

enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const RARITY_COLORS = {
	ItemRarity.COMMON:    "b0b0b0",
	ItemRarity.UNCOMMON:  "55ff55",
	ItemRarity.RARE:      "5555ff",
	ItemRarity.EPIC:      "aa00ff",
	ItemRarity.LEGENDARY: "ffaa00"
}

# ==============================================================================
# DATOS GENERALES COMPARTIDOS
# ==============================================================================
@export_group("General Info")
@export var name: String = "Item Nuevo"
@export var type: ItemType = ItemType.MISC
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var icon: Texture2D
@export_multiline var description: String = "Descripción..."

@export_group("Economy & Physics")
@export var price: int = 10
@export var is_quest_item: bool = false
@export var max_stack_size: int = 1
@export var weight: float = 1.0

@export_group("Requirements")
@export var attributes_required: Dictionary = {}

# ==============================================================================
# MÉTODOS PÚBLICOS
# ==============================================================================
func get_colored_name() -> String:
	var hex = RARITY_COLORS.get(rarity, "ffffff")
	return "[color=#%s]%s[/color]" % [hex, name]

func get_tooltip_text(compare_item: ItemData = null) -> String:
	var text = "%s\n" % description

	# Peso
	var selected_weight = compare_item.weight if compare_item else -1.0
	text += _format_stat("Peso", weight, selected_weight, "kg", true) + "\n\n"

	# Lógica polimórfica: Llamamos a la función que las clases hijas definirán
	text += _get_specific_tooltip_text(compare_item)

	if not attributes_required.is_empty():
		text += "\n[b]Requisitos:[/b]\n"
		for attr in attributes_required:
			text += " %s: %d\n" % [attr.capitalize(), attributes_required[attr]]

	return text

func get_type_name() -> String:
	match type:
		ItemType.CONSUMABLE:    return "Consumible"
		ItemType.HELMET:        return "Casco"
		ItemType.CHEST:         return "Pechera"
		ItemType.ARMS:          return "Guanteletes"
		ItemType.BOOTS:         return "Botas"
		ItemType.BELT:          return "Cinturón"
		ItemType.CAPE:          return "Capa"
		ItemType.WEAPON_SHORT:  return "Arma Corta"
		ItemType.WEAPON_MEDIUM: return "Arma Media"
		ItemType.WEAPON_HEAVY:  return "Arma Pesada"
		ItemType.SHIELD:        return "Escudo"
		ItemType.QUEST:         return "Objeto de Misión"
		ItemType.MISC:          return "Material"
		_: return "Desconocido"

func check_requirements_met(player_stats: Dictionary) -> Dictionary:
	var result = {}
	for attr in attributes_required:
		var required_val = attributes_required[attr]
		var player_val = player_stats.get(attr, 0)
		result[attr] = (player_val >= required_val)
	return result

# ==============================================================================
# MÉTODOS VIRTUALES Y HELPERS PARA CLASES HIJAS
# ==============================================================================

## FUNCIÓN VIRTUAL: Debe ser sobrescrita por WeaponData, ArmorData, etc.
func _get_specific_tooltip_text(_compare_item: ItemData) -> String:
	return ""

## Helper maestro para formatear diferencias (se mantiene en la base)
func _format_stat(label: String, val_self: float, val_selected: float, suffix: String = "", invert_color: bool = false) -> String:
	var base_text = "%s: %.1f%s" % [label, val_self, suffix]
	if val_selected < 0: return base_text

	var diff = val_selected - val_self
	if is_zero_approx(diff): return base_text + " [color=#888888](=)[/color]"

	var good_color = "44ff44" 
	var bad_color = "ff4444"  
	var final_color = ""

	if diff > 0:
		final_color = bad_color if invert_color else good_color
		return base_text + " [color=#%s](+%.1f)[/color]" % [final_color, abs(diff)]
	else:
		final_color = good_color if invert_color else bad_color
		return base_text + " [color=#%s](-%.1f)[/color]" % [final_color, abs(diff)]
