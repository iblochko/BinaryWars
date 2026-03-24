# Unit.gd (Базовый класс)
extends CharacterBody2D
class_name BaseUnit  # ← Важно! Позволяет ссылаться на тип в других скриптах

# === Общие параметры ===
@export var movement_points: int = 2
@export var move_speed: float = 300.0

# === Состояние ===
var is_selected: bool = false
var is_moving: bool = false
var current_movement: int = 2
var target_cell: Vector2i = Vector2i.ZERO
var current_cell: Vector2i = Vector2i.ZERO
var original_scale: Vector2
var original_modulate: Color
var movement_path: Array[Vector2i] = []
var current_path_index: int = 0

# === Ссылки ===
var map_manager = null

func _ready():
	original_scale = scale
	original_modulate = modulate
	
	await get_tree().process_frame
	
	map_manager = get_tree().get_first_node_in_group("map_manager")
	if map_manager == null:
		printerr("Ошибка: Не найден менеджер карты!")
		return
	
	current_cell = map_manager.get_cell_at_position(global_position)
	global_position = map_manager.get_cell_world_position(current_cell)
	map_manager.register_unit(self, current_cell)
	add_to_group("units")
	
	# Вызываем виртуальный метод для дочерних классов
	_on_unit_ready()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Проверяем клик по юниту (независимо от выделения)
		if global_position.distance_to(mouse_pos) < 40:
			select_unit()
			get_viewport().set_input_as_handled()
			return

func select_unit():
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit != self:
			unit.is_selected = false
			unit._update_visuals()
	
	is_selected = true
	_update_visuals()

func _update_visuals():
	if is_selected:
		modulate = Color(0.5, 1, 0.5, 1)
		scale = original_scale * 1.2
	else:
		modulate = original_modulate
		scale = original_scale

func _move_to_target(delta):
	if map_manager == null:
		return
	
	var target_pos = map_manager.get_cell_world_position(target_cell)
	var distance = global_position.distance_to(target_pos)
	
	if distance < 2.0:
		global_position = target_pos
		_on_arrived()
	else:
		var direction = (target_pos - global_position).normalized()
		global_position += direction * move_speed * delta

func _on_arrived():
	map_manager.unregister_unit(current_cell)
	current_cell = target_cell
	map_manager.register_unit(self, current_cell)
	
	target_cell = Vector2i.ZERO
	is_moving = false
	current_movement -= 1
	
	if current_movement <= 0:
		deselect()
	else:
		_update_visuals()
	
	# Вызываем метод для дочерних классов
	_on_movement_finished()

func move_along_path(path: Array[Vector2i]):
	if path.is_empty():
		return
	
	movement_path = path
	current_path_index = 0
	is_moving = true
	
	print("🛤️ Получен путь из ", path.size(), " клеток")

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
		# Достигли промежуточной клетки
		current_path_index += 1
	else:
		# Двигаемся к ней
		var direction = (target_pos - global_position).normalized()
		global_position += direction * move_speed * delta

func _on_path_completed():
	# Обновляем регистрацию
	map_manager.unregister_unit(current_cell)
	current_cell = movement_path[-1]  # Последняя клетка пути
	map_manager.register_unit(self, current_cell)
	
	movement_path.clear()
	current_path_index = 0
	is_moving = false
	current_movement -= 1
	
	print("✅ Прибыл на: ", current_cell)
	
	if current_movement <= 0:
		deselect()
	else:
		_update_visuals()

func deselect():
	is_selected = false
	is_moving = false
	target_cell = Vector2i.ZERO
	_update_visuals()

func reset_movement():
	current_movement = movement_points

# === ВИРТУАЛЬНЫЕ МЕТОДЫ (переопределяются в наследниках) ===
func _on_unit_ready():
	pass  # Пустая реализация

func _on_movement_finished():
	pass  # Пустая реализация
