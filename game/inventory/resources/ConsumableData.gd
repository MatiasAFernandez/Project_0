extends ItemData
class_name ConsumableData

@export_group("Consumable Effects")
@export var health_restore: float = 0.0
@export var fatigue_restore: float = 0.0
@export var duration_seconds: float = 0.0 # 0 significa instantáneo
@export var temporary_buffs: Dictionary = {} # Ej: {"Strength": 5, "Defense": 10}

func _get_specific_tooltip_text(_selected_item: ItemData) -> String:
	var t = ""
	
	# Para los consumibles normalmente no comparamos estadísticas directas como las armas
	# Así que simplemente listamos sus efectos.
	
	if health_restore > 0:
		t += "[color=#44ff44]Restaura %.1f de Salud[/color]\n" % health_restore
	
	if fatigue_restore > 0:
		t += "[color=#44ff44]Restaura %.1f de Fatiga[/color]\n" % fatigue_restore
		
	if not temporary_buffs.is_empty():
		var time_text = " (%d seg)" % duration_seconds if duration_seconds > 0 else ""
		t += "\n[color=#ffcc00]Efectos Temporales%s:[/color]\n" % time_text
		for buff in temporary_buffs:
			var val = temporary_buffs[buff]
			t += " +%d %s\n" % [val, buff.capitalize()]
			
	return t
