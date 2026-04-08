# Unit.gd
extends CharacterBody2D
class_name BaseUnit

@export var movement_points: int = 2
@export var move_speed: float = 300.0
@export var max_health: int = 100
@export var max_attack_amount: int = 2

var current_attack_amount: int = 2
var attack_range: int = 1  # Можно переопределить в дочерних классах
var attack_damage: int = 10  # Можно переопределить в дочерних классах
var current_health: int = 100
var faction: int = 0
var is_selected: bool = false
var is_moving: bool = false
var current_movement: int = 2
var target_cell: Vector2i = Vector2i.ZERO
var current_cell: Vector2i = Vector2i.ZERO
var original_scale: Vector2
var original_modulate: Color
var movement_path: Array[Vector2i] = []
var current_path_index: int = 0
var map_manager = null
var is_attack_mode: bool = false

func _ready():
	original_scale = scale
	original_modulate = modulate
	
	await get_tree().process_frame
	
	map_manager = get_tree().get_first_node_in_group("map_manager")
	if map_manager == null:
		printerr("❌ Не найден менеджер карты!")
		return
	
	current_cell = map_manager.get_cell_at_position(global_position)
	#выравнивание по центру клетки
	global_position = map_manager.get_cell_world_position(current_cell)
	map_manager.register_unit(self, current_cell)
	add_to_group("units")
	
	faction = 0
	
	_on_unit_ready()
	current_movement = movement_points
	current_health = max_health
	print("✅ Юнит создан! HP: ", current_health, "/", max_health)
	
func _draw():
	
	print("🔍 _draw() вызван для: ", name)
	# Позиция и размер
	var bar_width = 50
	var bar_height = 6
	var bar_pos = Vector2(-bar_width/2, 35)  # Под спрайтом
	
	# Фон (тёмный)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0, 0, 0, 0.7))
	
	# Заполнение
	var health_percent = float(current_health) / float(max_health)
	var fill_width = (bar_width - 4) * health_percent
	
	# Цвет по здоровью
	var fill_color = Color(0.3, 0.8, 0.3)  # Зелёный
	if health_percent <= 0.6:
		fill_color = Color(0.9, 0.9, 0.3)  # Жёлтый
	if health_percent <= 0.3:
		fill_color = Color(0.9, 0.3, 0.3)  # Красный
	
	draw_rect(Rect2(bar_pos + Vector2(2, 2), Vector2(fill_width, bar_height - 4)), fill_color)
	
func select_unit():
	queue_redraw()
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit != self:
			unit.is_selected = false
			unit._update_visuals()
	
	is_selected = true
	_update_visuals()

	var root = get_tree().current_scene
	var action_panel = root.get_node_or_null("ActionPanel")
	
	if action_panel:
		action_panel.show_panel(self)
		print("✅ Панель показана")
	else:
		printerr("❌ ActionPanel не найден в корневой сцене!")
	
	#передаём себя, чтобы MapManager игнорировал этого юнита
	is_attack_mode = false  # ← Сбрасываем режим атаки при выделении
	if map_manager:
		map_manager.highlight_available_cells(current_cell, current_movement, self)

func enable_attack_mode():
	is_attack_mode = true
	print("🎯 Режим атаки включён!")
	
	if map_manager:
		map_manager.clear_highlight()
		map_manager.highlight_attack_cells(current_cell, attack_range, self)

func disable_attack_mode():
	is_attack_mode = false
	if map_manager:
		map_manager.clear_highlight()

func attack_target(target: BaseUnit):
	if target == null:
		return
	
	if target == self:
		print("❌ Нельзя атаковать себя!")
		return
	
	# Проверяем дистанцию
	var distance = abs(current_cell.x - target.current_cell.x) + abs(current_cell.y - target.current_cell.y)
	
	if distance > attack_range:
		print("❌ Цель слишком далеко! Дистанция: ", distance, " / ", attack_range)
		return
	
	# Наносим урон
	target.take_damage(attack_damage)
	
	print("⚔️ Атака! Нанесено ", attack_damage, " урона по ", target.name)
	
	# Выходим из режима атаки
	disable_attack_mode()
	deselect()

# В deselect() добавь сброс режима атаки:
func deselect():
	is_selected = false
	is_moving = false
	is_attack_mode = false  # ← Сбрасываем режим атаки
	movement_path.clear()
	_update_visuals()
	
	if map_manager:
		map_manager.clear_highlight()

func _update_visuals():
	if is_selected:
		modulate = Color(0.5, 1, 0.5, 1)
		scale = original_scale * 1.2
	else:
		modulate = original_modulate
		scale = original_scale

func _process(delta):
	if is_moving and movement_path.size() > 0:
		_move_along_path(delta)

func _move_along_path(delta):
	if current_path_index >= movement_path.size():
		_on_path_completed()
		return
	
	var target_cell = movement_path[current_path_index]
	var target_pos = map_manager.get_cell_world_position(target_cell)
	var distance = global_position.distance_to(target_pos)
	
	if distance < 2.0:
		current_path_index += 1
	else:
		var direction = (target_pos - global_position).normalized()
		global_position += direction * move_speed * delta

func _on_path_completed():
	map_manager.unregister_unit(current_cell)
	current_cell = movement_path[-1]
	map_manager.register_unit(self, current_cell)
	
	current_path_index = 0
	is_moving = false
	current_movement -= (movement_path.size()-1)
	movement_path.clear()
	if map_manager:
		map_manager.highlight_available_cells(current_cell, current_movement, self)
		
	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager:
		turn_manager.units_moved += 1
	
	var action_panel = get_tree().current_scene.get_node_or_null("ActionPanel")
	if action_panel and action_panel.current_unit == self:
		action_panel.update_health()  # Обновляет HP и ходы
	
	print("✅ Прибыл на: ", current_cell, " | Ходов осталось: ", current_movement)
	
	if current_movement <= 0:
		deselect()
	else:
		_update_visuals()

func move_along_path(path: Array[Vector2i]):
	if path.is_empty():
		print("❌ Пустой путь!")
		return
	
	movement_path = path
	current_path_index = 0
	is_moving = true
	print("🛤️ Путь из ", path.size(), " клеток")


func reset_movement():
	current_movement = movement_points
	print("🔄 Ходы восстановлены: ", current_movement)

func reset_attacks():
	current_attack_amount=max_attack_amount
	print("Атаки восстановлены: ", current_attack_amount)

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	queue_redraw()  # ← Обновить полоску
	await get_tree().process_frame
	queue_redraw()
	
	var action_panel = get_tree().get_first_node_in_group("action_panel")
	if action_panel and action_panel.current_unit == self:
		action_panel.update_health()
	
	print("💥 ", name, " получил ", amount, " урона! HP: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	queue_redraw()
	print("💚 ", name, " вылечен на ", amount, "! HP: ", current_health, "/", max_health)

func die():
	print("💀 ", name, " погиб!")
	if map_manager:
		map_manager.unregister_unit(current_cell)
	queue_free()

func _on_unit_ready():
	pass

func _on_movement_finished():
	pass
