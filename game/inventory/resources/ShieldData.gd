extends ItemData
class_name ShieldData

@export_group("Shield Stats")
@export var shield_protection: float = 0.0
@export var fatigue_rate: float = 0.0
@export var shield_effects: Dictionary = {}

func _get_specific_tooltip_text(selected_item: ItemData) -> String:
	var t = ""
	
	var sel_shield = selected_item as ShieldData
	var sel_prot = sel_shield.shield_protection if sel_shield else -1.0
	var sel_fatigue = sel_shield.fatigue_rate if sel_shield else -1.0

	t += _format_stat("Protección", shield_protection, sel_prot) + "\n"
	t += _format_stat("Fatiga", fatigue_rate, sel_fatigue, "", true) + "\n"

	if not shield_effects.is_empty():
		t += "[color=#ffcc00]Pasivas:[/color]\n"
		for effect in shield_effects:
			t += " - %s\n" % effect
	return t
