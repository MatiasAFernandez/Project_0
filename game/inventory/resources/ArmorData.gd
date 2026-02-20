extends ItemData
class_name ArmorData

@export_group("Armor Stats")
@export var armor_rating: float = 0.0
@export var damage_reduction_percent: float = 0.0
@export var stat_bonuses: Dictionary = {} # Ej: {"Strength": 2, "Agility": -1}

func _get_specific_tooltip_text(selected_item: ItemData) -> String:
	var t = ""
	
	# Casteo seguro: Si el ítem a comparar no es ArmorData, esto será null
	var sel_armor = selected_item as ArmorData
	var sel_rating = sel_armor.armor_rating if sel_armor else -1.0
	var sel_reduction = sel_armor.damage_reduction_percent if sel_armor else -1.0

	t += _format_stat("Armadura", armor_rating, sel_rating) + "\n"
	
	if damage_reduction_percent > 0:
		t += _format_stat("Reducción de Daño", damage_reduction_percent, sel_reduction, "%") + "\n"

	if not stat_bonuses.is_empty():
		t += "\n[color=#44ff44]Bonos de Atributos:[/color]\n"
		for stat in stat_bonuses:
			var bonus = stat_bonuses[stat]
			# Si el bono es negativo, lo pintamos de rojo
			if bonus >= 0:
				t += " +%d %s\n" % [bonus, stat.capitalize()]
			else:
				t += "[color=#ff4444] %d %s[/color]\n" % [bonus, stat.capitalize()]
				
	return t
