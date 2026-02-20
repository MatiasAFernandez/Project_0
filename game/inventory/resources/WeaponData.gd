extends ItemData
class_name WeaponData

@export_group("Weapon Stats")
@export var weapon_damage: float = 0.0
@export_range(0, 100) var crit_chance: float = 5.0
@export var crit_multiplier: float = 1.5
@export var weapon_effects: Dictionary = {}
@export var is_dual_wieldable: bool = false

# Sobrescribimos la función virtual de la clase padre
func _get_specific_tooltip_text(selected_item: ItemData) -> String:
	var t = ""
	
	# Casteamos de forma segura para comparar manzanas con manzanas
	var sel_weapon = selected_item as WeaponData
	var sel_dmg = sel_weapon.weapon_damage if sel_weapon else -1.0
	var sel_crit = sel_weapon.crit_chance if sel_weapon else -1.0

	t += _format_stat("Daño", weapon_damage, sel_dmg) + "\n"
	t += _format_stat("Crítico", crit_chance, sel_crit, "%") + "\n"

	if not weapon_effects.is_empty():
		t += "[color=#ffcc00]Efectos:[/color]\n"
		for effect in weapon_effects:
			t += " - %s: %s\n" % [effect, str(weapon_effects[effect])]
	return t
