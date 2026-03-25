# Unit.gd
extends CharacterBody2D
class_name BaseUnit

@export var movement_points: int = 2
@export var move_speed: float = 300.0

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
	
	_on_unit_ready()

func select_unit():
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit != self:
			unit.is_selected = false
			unit._update_visuals()
	
	is_selected = true
	_update_visuals()
	
	#передаём себя, чтобы MapManager игнорировал этого юнита
	if map_manager:
		map_manager.highlight_available_cells(current_cell, current_movement, self)

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
	
	movement_path.clear()
	current_path_index = 0
	is_moving = false
	current_movement -= 1
	
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

func deselect():
	is_selected = false
	is_moving = false
	movement_path.clear()
	_update_visuals()
	if map_manager:
		map_manager.clear_highlight()

func reset_movement():
	current_movement = movement_points
	print("🔄 Ходы восстановлены: ", current_movement)

func _on_unit_ready():
	pass

func _on_movement_finished():
	pass
