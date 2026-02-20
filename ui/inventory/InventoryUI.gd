extends Control

# ==============================================================================
# VARIABLES EXPORTADAS
# ==============================================================================
@export var slot_scene: PackedScene

# ==============================================================================
# REFERENCIAS A NODOS
# ==============================================================================
@onready var item_list_container: VBoxContainer = $MainPanel/HBoxContainer/VBoxContainer/ScrollContainer/ItemListContainer
@onready var background: ColorRect = $BackgroundBlocker
@onready var main_panel: PanelContainer = $MainPanel

# Sección de Tooltips
@onready var tooltip_layer: Control = $TooltipLayer
@onready var main_tooltip: PanelContainer = $TooltipLayer/MainTooltip
@onready var compare_tooltip_1: PanelContainer = $TooltipLayer/CompareTooltip
@onready var compare_tooltip_2: PanelContainer = $TooltipLayer/CompareTooltip2

# Controles
@onready var context_menu: PanelContainer = $ContextMenu
@onready var sort_options_button: OptionButton = $MainPanel/HBoxContainer/VBoxContainer/HeaderControls/SortSection/SortOptionButton
@onready var filter_container: HBoxContainer = $MainPanel/HBoxContainer/VBoxContainer/HeaderControls/FilterSection

# ==============================================================================
# VARIABLES Y CONSTANTES
# ==============================================================================
var slot_ui_scene = preload("res://ui/inventory/InventorySlotUI.tscn")

# Este array será nuestro "Pool" de casilleros visuales
var slot_pool: Array[Control] = []

# Enum para modos de ordenamiento
enum SortMode { RECENT, OLDEST, NAME_AZ, NAME_ZA }

# Estado actual
var current_filter: String = "ALL"
var current_sort_mode: SortMode = SortMode.RECENT

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# 1. Conexiones Globales
	PlayerSession.inventory_updated.connect(update_inventory_display)
	
	# 2. Inicializar Tooltips (Reseteo forzoso para evitar tamaños fantasma)
	_reset_tooltips()
	
	# 3. Inicializar Ordenamiento
	_setup_sort_options()
	
	# 4. Inicializar Filtros (Conexión dinámica)
	_setup_filter_buttons()
	
	# 5. Estado inicial
	close_inventory()
	update_inventory_display()

func _process(_delta: float) -> void:
	# Solo calculamos posición si el tooltip principal está visible
	if main_tooltip.visible:
		_update_tooltip_positions()

# ==============================================================================
# LÓGICA DE APERTURA / CIERRE
# ==============================================================================
func open_inventory() -> void:
	visible = true
	# Reset visual de filtros
	_update_filter_buttons_visual()
	update_inventory_display()
	
	# Opcional: Sonido de abrir bolsa
	# AudioManager.play_sfx(preload("res://audio/bag_open.wav"))

func close_inventory() -> void:
	visible = false
	hide_all_tooltips()
	context_menu.visible = false

# ==============================================================================
# SISTEMA DE VISUALIZACIÓN (CORE)
# ==============================================================================
func update_inventory_display() -> void:
	var max_capacity = PlayerSession.get_max_inventory_slots()
	var current_inventory = PlayerSession.inventory
	
	# 1. DUPLICAR Y FILTRAR DATOS
	var display_list: Array[SlotData] = current_inventory.duplicate()
	
	# NUEVO: Eliminamos los espacios vacíos del array visual. 
	# En una lista vertical, no queremos mostrar los "huecos", solo los ítems que existen.
	display_list = display_list.filter(func(slot): return slot != null and slot.item_data != null)
	
	# Filtros de botones (Armas, Consumibles, etc)
	if current_filter != "ALL":
		display_list = display_list.filter(func(slot):
			return _check_filter_match(slot.item_data, current_filter)
		)
		
	# Ordenamiento
	_sort_display_list(display_list)

	# 2. EXPANDIR EL POOL (Si es necesario)
	while slot_pool.size() < max_capacity:
		var new_slot_ui = slot_scene.instantiate()
		item_list_container.add_child(new_slot_ui)
		slot_pool.append(new_slot_ui)
		
		# CONEXIONES DE SEÑALES PARA EL POOL
		# Conectamos las señales una sola vez al instanciar el nodo.
		new_slot_ui.slot_right_clicked.connect(_on_slot_right_clicked)
		new_slot_ui.mouse_exited.connect(_on_slot_mouse_exited)
		
		# TRUCO CLAVE: En lugar de bindear los "datos", bindeamos el "nodo" en sí mismo.
		new_slot_ui.mouse_entered.connect(_on_pool_slot_mouse_entered.bind(new_slot_ui))

	# 3. SINCRONIZAR ESTADO VISUAL
	for i in range(slot_pool.size()):
		var slot_ui = slot_pool[i]
		
		if i < display_list.size():
			# Si hay un ítem válido para esta posición, lo mostramos y le pasamos la data
			slot_ui.visible = true
			slot_ui.set_slot_data(display_list[i])
		else:
			# Si ya no hay más ítems en la lista (o es un casillero extra del pool), lo ocultamos por completo
			slot_ui.visible = false

# ==============================================================================
# LÓGICA DE FILTROS Y ORDENAMIENTO
# ==============================================================================
#region Filters & Sorting

func _setup_sort_options() -> void:
	sort_options_button.clear()
	sort_options_button.add_item("Más recientes", SortMode.RECENT)
	sort_options_button.add_item("Más antiguos", SortMode.OLDEST)
	sort_options_button.add_item("Nombre (A-Z)", SortMode.NAME_AZ)
	sort_options_button.add_item("Nombre (Z-A)", SortMode.NAME_ZA)
	sort_options_button.item_selected.connect(_on_sort_selected)

func _on_sort_selected(index: int) -> void:
	current_sort_mode = index as SortMode
	update_inventory_display()

func _sort_display_list(list: Array[SlotData]) -> void:
	match current_sort_mode:
		SortMode.RECENT: list.reverse() # Los nuevos al principio
		SortMode.OLDEST: pass # Orden natural del array
		SortMode.NAME_AZ:
			list.sort_custom(func(a, b): return a.item_data.name.naturalnocasecmp_to(b.item_data.name) < 0)
		SortMode.NAME_ZA:
			list.sort_custom(func(a, b): return a.item_data.name.naturalnocasecmp_to(b.item_data.name) > 0)

func _setup_filter_buttons() -> void:
	# Recorremos todos los hijos del contenedor de filtros
	for child in filter_container.get_children():
		if child is Button:
			# Extraemos el filtro del nombre del botón o de metadata
			# Asumiendo botones llamados "BtnFilterChest", "BtnFilterAll", etc.
			var filter_name = child.name.replace("BtnFilter", "").to_upper()
			
			# Conectamos la señal usando una lambda local
			child.pressed.connect(func(): set_filter(filter_name))
			
			# Guardamos el nombre limpio como meta para usarlo luego
			child.set_meta("filter_type", filter_name)

func set_filter(filter_name: String) -> void:
	current_filter = filter_name
	_update_filter_buttons_visual()
	update_inventory_display()

func _update_filter_buttons_visual() -> void:
	for btn in filter_container.get_children():
		if btn is Button and btn.has_meta("filter_type"):
			var f_type = btn.get_meta("filter_type")
			# Resaltar si es el activo
			if f_type == current_filter:
				btn.modulate = Color(1.5, 1.5, 1.5) # Brillo
			else:
				btn.modulate = Color(1, 1, 1) # Normal

func _check_filter_match(item: ItemData, filter: String) -> bool:
	# Mapeo rápido de Strings a Tipos
	# Nota: Asegúrate de que los nombres de tus botones coincidan con estos strings
	match filter:
		"ALL": return true
		"WEAPON_SHORT": return item.type == ItemData.ItemType.WEAPON_SHORT
		"WEAPON_MEDIUM": return item.type == ItemData.ItemType.WEAPON_MEDIUM
		"WEAPON_HEAVY": return item.type == ItemData.ItemType.WEAPON_HEAVY
		"SHIELD": return item.type == ItemData.ItemType.SHIELD
		"HELMET": return item.type == ItemData.ItemType.HELMET
		"CHEST": return item.type == ItemData.ItemType.CHEST
		"ARMS": return item.type == ItemData.ItemType.ARMS
		"BOOTS": return item.type == ItemData.ItemType.BOOTS
		"CAPE": return item.type == ItemData.ItemType.CAPE
		"BELT": return item.type == ItemData.ItemType.BELT
		"CONSUMABLE": return item.type == ItemData.ItemType.CONSUMABLE
		"QUEST": return item.type == ItemData.ItemType.QUEST
		"MISC": return item.type == ItemData.ItemType.MISC
	return false

#endregion

# ==============================================================================
# SISTEMA DE TOOLTIPS (Posición y Comparación)
# ==============================================================================
#region Tooltips

func _reset_tooltips() -> void:
	main_tooltip.visible = false
	compare_tooltip_1.visible = false
	compare_tooltip_2.visible = false
	
	# Forzamos reseteo de tamaño
	main_tooltip.reset_size()
	compare_tooltip_1.reset_size()
	compare_tooltip_2.reset_size()

func _on_slot_mouse_entered(slot_data: SlotData) -> void:
	if not slot_data or not slot_data.item_data: return
	
	var item_hovered = slot_data.item_data
	
	# --- CAMBIO 1: TOOLTIP PRINCIPAL LIMPIO ---
	# Pasamos 'null' como tercer argumento. 
	# Así, el ítem seleccionado muestra sus stats puras sin colores de comparación.
	main_tooltip.display_info(item_hovered, "", null)
	main_tooltip.visible = true
	
	# --- CAMBIO 2: LÓGICA DE COMPARACIÓN ---
	# Esta función se encarga de llenar los tooltips de los ítems equipados (CompareTooltip 1 y 2)
	_handle_comparison_logic(item_hovered)

func _handle_comparison_logic(item: ItemData) -> void:
	# Ocultamos por defecto
	compare_tooltip_1.visible = false
	compare_tooltip_2.visible = false
	
	# Si no es equipable, no comparamos nada
	if not _is_equipment(item):
		return

	# Obtenemos contra qué comparar (Array de diccionarios {item, slot_name})
	var comparison_targets = _get_comparison_targets(item)
	
	# Asignamos a los tooltips disponibles
	var tooltip_nodes = [compare_tooltip_1, compare_tooltip_2]
	
	for i in range(min(comparison_targets.size(), tooltip_nodes.size())):
		var target = comparison_targets[i]
		var tooltip = tooltip_nodes[i]
		
		# IMPORTANTE: Aquí pasamos el item del inventario como tercer argumento
		# para que el tooltip equipado pueda calcular la diferencia (+/-)
		tooltip.display_info(target.item, target.slot_name, item)
		tooltip.visible = true

## Función puente para el Object Pool. 
## Le preguntamos al nodo visual qué dato tiene en este momento exacto.
func _on_pool_slot_mouse_entered(slot_ui: Control) -> void:
	# Verificamos que el slot siga teniendo datos (esto previene errores si arrastraste/soltaste el ítem muy rápido)
	if slot_ui._slot_data != null and slot_ui._slot_data.item_data != null:
		# Redirigimos a tu función original que maneja la lógica de tooltips de comparación
		_on_slot_mouse_entered(slot_ui._slot_data)

func _get_comparison_targets(item: ItemData) -> Array:
	var targets = []
	
	# Caso 1: Armas Duales (Comprobamos primero si es un WeaponData)
	if item is WeaponData and item.is_dual_wieldable:
		_try_add_target(targets, PlayerSession.SLOT_MAIN_HAND, "Mano Derecha")
		
		# Solo comparamos izquierda si NO es escudo (o si el item nuevo es escudo)
		var off_item = PlayerSession.get_gear_in_slot(PlayerSession.SLOT_OFF_HAND)
		if off_item and off_item.type != ItemData.ItemType.SHIELD:
			_try_add_target(targets, PlayerSession.SLOT_OFF_HAND, "Mano Izquierda")
			
	# Caso 2: Escudos (Podemos usar 'is ShieldData' en lugar del enum si lo prefieres)
	elif item is ShieldData:
		_try_add_target(targets, PlayerSession.SLOT_OFF_HAND, "Mano Izquierda")
		
	# Caso 3: Armas normales o Armaduras
	else:
		# Preguntamos a PlayerSession cuál es el mejor slot para este item
		var slot_key = PlayerSession.get_best_slot_for_item(item)
		if slot_key != "":
			var nice_name = _get_nice_slot_name(slot_key)
			_try_add_target(targets, slot_key, nice_name)
			
	return targets

func _try_add_target(targets_array: Array, slot_key: String, slot_display_name: String) -> void:
	var equipped_item = PlayerSession.get_gear_in_slot(slot_key)
	if equipped_item:
		targets_array.append({
			"item": equipped_item,
			"slot_name": slot_display_name
		})

func _update_tooltip_positions() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var screen_size = get_viewport().get_visible_rect().size
	var spacing = 10
	
	# Lista de tooltips activos a posicionar
	var active_tooltips = [main_tooltip]
	if compare_tooltip_1.visible: active_tooltips.append(compare_tooltip_1)
	if compare_tooltip_2.visible: active_tooltips.append(compare_tooltip_2)
	
	# Calcular posición Y (intentar ponerlo abajo-derecha del mouse)
	var start_y = mouse_pos.y + 20
	# Si el más alto se sale de la pantalla, mover todos arriba del mouse
	if start_y + main_tooltip.size.y > screen_size.y:
		start_y = mouse_pos.y - main_tooltip.size.y - 10
	
	# Calcular posición X (en cascada hacia la izquierda)
	var current_x = mouse_pos.x - main_tooltip.size.x - 20
	
	# Posicionar en orden inverso (Main pegado al mouse, Comparaciones a la izquierda)
	for tooltip in active_tooltips:
		# Si nos salimos por la izquierda, invertimos y ponemos a la derecha
		if current_x < 0:
			current_x = mouse_pos.x + 20
			# Reiniciamos el loop con lógica de derecha a izquierda si fuera necesario
			# (Simplificado: Solo clamp para este ejemplo)
			current_x = max(0, current_x)

		tooltip.global_position = Vector2(current_x, start_y)
		
		# El siguiente se mueve más a la izquierda
		if active_tooltips.size() > 1:
			var next_idx = active_tooltips.find(tooltip) + 1
			if next_idx < active_tooltips.size():
				current_x -= (active_tooltips[next_idx].size.x + spacing)

func _on_slot_mouse_exited() -> void:
	hide_all_tooltips()

func hide_all_tooltips() -> void:
	main_tooltip.visible = false
	compare_tooltip_1.visible = false
	compare_tooltip_2.visible = false

#endregion

# ==============================================================================
# MENÚ CONTEXTUAL & HELPERS
# ==============================================================================
func _on_slot_right_clicked(context: Dictionary, pos: Vector2) -> void:
	context_menu.open(context, pos)
	hide_all_tooltips()

func _is_equipment(item: ItemData) -> bool:
	return item.type != ItemData.ItemType.CONSUMABLE and \
		   item.type != ItemData.ItemType.QUEST and \
		   item.type != ItemData.ItemType.MISC

func _get_nice_slot_name(key: String) -> String:
	match key:
		PlayerSession.SLOT_MAIN_HAND: return "Mano Derecha"
		PlayerSession.SLOT_OFF_HAND: return "Mano Izquierda"
		PlayerSession.SLOT_HEAD: return "Cabeza"
		PlayerSession.SLOT_CHEST: return "Torso"
		PlayerSession.SLOT_ARMS: return "Brazos"
		PlayerSession.SLOT_BOOTS: return "Botas"
		PlayerSession.SLOT_CAPE: return "Capa"
		PlayerSession.SLOT_BELT: return "Cinturón"
	return "Equipo"

# Llamada externa desde Slots de Armadura (Paperdoll)
func show_equipment_tooltip(item: ItemData) -> void:
	main_tooltip.display_info(item, "Equipado", null)
	main_tooltip.reset_size()
	compare_tooltip_1.visible = false
	compare_tooltip_2.visible = false
	main_tooltip.visible = true
	
# Esta función recibe la señal de tus slots de equipamiento (Casco, Pechera, etc.)
func _on_equipment_slot_right_clicked(context: Dictionary, pos: Vector2) -> void:
	# Abre el menú contextual (Equipar/Tirar/Info)
	if context_menu:
		context_menu.open(context, pos)
	
	# Oculta los tooltips para que no estorben
	hide_all_tooltips()
