extends PanelContainer

# ==============================================================================
# REFERENCIAS A NODOS UI
# ==============================================================================
@onready var lbl_name: Label = $MarginContainer/VBoxContainer/LblName
@onready var lbl_type: Label = $MarginContainer/VBoxContainer/LblType
@onready var lbl_stats: RichTextLabel = $MarginContainer/VBoxContainer/LblStats
@onready var lbl_reqs: RichTextLabel = $MarginContainer/VBoxContainer/LblRequirements
@onready var lbl_slot_tag: Label = $MarginContainer/VBoxContainer/LblSlotTag
@onready var lbl_hand_equip: RichTextLabel = $MarginContainer/VBoxContainer/LblHandEquip

# ==============================================================================
# MÉTODOS PÚBLICOS
# ==============================================================================

## Muestra la información del item.
## [param slot_name_text]: Texto opcional para indicar dónde está equipado (ej. "MAIN HAND").
## [param compare_against]: (Opcional) Item contra el cual comparar estadísticas.
func display_info(item: ItemData, slot_name_text: String = "", compare_against: ItemData = null) -> void:
	# 1. Ocultar inmediatamente para configurar "detrás de cámaras"
	visible = false
	
	# 2. Configuración de Cabecera (Nombre y Tipo)
	lbl_name.text = item.name
	# Usamos el color definido en el ItemData para la rareza
	var rarity_color = ItemData.RARITY_COLORS.get(item.rarity, "ffffff")
	lbl_name.modulate = Color(rarity_color)
	
	# Usamos el helper de ItemData para obtener el nombre del tipo (ej. "Arma Pesada")
	lbl_type.text = item.get_type_name()
	
	# 3. Configuración de Ubicación (Mano derecha, Izquierda, Cabeza...)
	lbl_hand_equip.text = _get_equip_location_text(item)
	
	# 4. Configuración del Cuerpo (Descripción y Estadísticas)
	# Delegamos la generación del texto al propio item para mantener consistencia.
	# Esto incluye descripción, peso, stats específicas y requerimientos.
	lbl_stats.text = item.get_tooltip_text(compare_against)
	
	# NOTA: Como item.get_tooltip_text() ya incluye los requerimientos al final,
	# ocultamos el label secundario para evitar información duplicada.
	lbl_reqs.visible = false
	lbl_reqs.text = "" 

	# 5. Etiqueta de Slot (ej. [ EQUIPPED ])
	if slot_name_text != "":
		lbl_slot_tag.text = "[ %s ]" % slot_name_text.to_upper()
		lbl_slot_tag.visible = true
		lbl_slot_tag.modulate = Color("88ffff") # Cyan para resaltar
	else:
		lbl_slot_tag.visible = false
	
	# 6. Recalcular tamaño del contenedor (Fix de UI de Godot)
	_resize_tooltip()

# ==============================================================================
# MÉTODOS PRIVADOS Y HELPERS
# ==============================================================================

func _resize_tooltip() -> void:
	# Esperamos un frame para que los RichTextLabels procesen el BBCode y calculen su altura real
	await get_tree().process_frame
	
	# Forzamos el tamaño mínimo vertical a 0 para permitir que el contenedor se encoja
	# si el texto es corto (evita que el tooltip quede gigante después de mostrar un item largo).
	custom_minimum_size.y = 0
	
	# Ordenamos al nodo recalcular su tamaño basado en sus hijos actuales
	reset_size()
	
	# Finalmente lo mostramos
	visible = true

func _get_equip_location_text(item: ItemData) -> String:
	var text = ""
	var color = "88ffff" # Cyan claro
	
	match item.type:
		ItemData.ItemType.WEAPON_SHORT:
			if item.is_dual_wieldable:
				text = "Una mano / Ambas manos"
			else:
				text = "Mano Principal"
		ItemData.ItemType.WEAPON_MEDIUM:
			text = "Mano Principal"
		ItemData.ItemType.WEAPON_HEAVY:
			text = "Dos Manos"
		ItemData.ItemType.SHIELD:
			text = "Mano Secundaria"
		ItemData.ItemType.QUEST: text = "Misión"
		_: text = "" # Misc no muestra nada
	
	if text != "":
		return "[i][color=#%s]%s[/color][/i]" % [color, text]
	return ""
