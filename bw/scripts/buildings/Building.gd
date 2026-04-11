extends StaticBody2D
class_name BaseBuilding

# === Общие параметры ===
@export var max_health: int = 200
@export var build_cost: int = 100
@export var build_time: float = 3.0  # Секунды

# === Состояние ===
var current_health: int = 200
var faction: int = 0  # 0 = игрок, 1 = враг
var is_selected: bool = false
var current_cell: Vector2i = Vector2i.ZERO
var original_scale: Vector2
var original_modulate: Color
var map_manager = null
var show_health_bar: bool = false

# === Для производства ===
var can_produce: bool = false
var production_queue: Array = []

func _ready():
	original_scale = scale
	original_modulate = modulate
	
	await get_tree().process_frame
	
	map_manager = get_tree().get_first_node_in_group("map_manager")
	if map_manager == null:
		printerr("❌ Не найден менеджер карты!")
		return
	
	current_cell = map_manager.get_cell_at_position(global_position)
	global_position = map_manager.get_cell_world_position(current_cell)
	
	# ✅ РЕГИСТРАЦИЯ ЗДАНИЯ (не юнита!)
	map_manager.register_building(self, current_cell)
	
	current_health = max_health
	
	print("🏗️ Здание создано: ", name, " | HP: ", current_health)
	print("🔍 Клетка здания: ", current_cell)
	
	_on_building_ready()

func select_building():
	# ✅ ДОБАВЬ ЭТО В НАЧАЛО:
	# Снимаем выделение со всех юнитов
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit.is_selected:
			unit.deselect()
	
	# Снимаем выделение с других зданий
	var all_buildings = get_tree().get_nodes_in_group("buildings")
	for b in all_buildings:
		if b != self and b.is_selected:
			b.deselect_building()
	# ✅ КОНЕЦ ДОБАВЛЕННОГО
	
	is_selected = true
	show_health_bar = true
	queue_redraw()
	_update_visuals()
	
	var action_panel = get_tree().current_scene.get_node_or_null("ActionPanel")
	if action_panel:
		action_panel.show_panel_for_building(self)

func deselect_building():
	is_selected = false
	show_health_bar = false
	queue_redraw()
	_update_visuals()
	
	var action_panel = get_tree().current_scene.get_node_or_null("ActionPanel")
	if action_panel:
		action_panel.hide_panel()

func _update_visuals():
	if is_selected:
		modulate = Color(0.5, 1, 0.5, 1)
		scale = original_scale * 1.1
	else:
		modulate = original_modulate
		scale = original_scale

func _draw():
	if not show_health_bar:
		return
	
	var bar_width = 50
	var bar_height = 6
	var bar_pos = Vector2(-bar_width/2, 35)
	
	# Фон
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0, 0, 0, 0.7))
	
	# Заполнение
	var health_percent = float(current_health) / float(max_health)
	var fill_width = (bar_width - 4) * health_percent
	
	var fill_color = Color(0.3, 0.8, 0.3)
	if health_percent <= 0.6:
		fill_color = Color(0.9, 0.9, 0.3)
	if health_percent <= 0.3:
		fill_color = Color(0.9, 0.3, 0.3)
	
	draw_rect(Rect2(bar_pos + Vector2(2, 2), Vector2(fill_width, bar_height - 4)), fill_color)

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	queue_redraw()
	
	print("💥 ", name, " получил ", amount, " урона! HP: ", current_health, "/", max_health)
	
	if current_health <= 0:
		destroy()

func destroy():
	print("💀 ", name, " разрушено!")
	
	if map_manager:
		map_manager.unregister_building(current_cell)
	
	queue_free()

# === ВИРТУАЛЬНЫЕ МЕТОДЫ ===
func _on_building_ready():
	pass

func _on_production_complete():
	pass
