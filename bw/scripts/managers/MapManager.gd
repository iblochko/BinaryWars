# MapManager.gd
extends Node2D

signal unit_selected(unit)
signal unit_moved(unit, from_cell, to_cell)

var grid: Dictionary = {}
var units_on_map: Dictionary = {}
var highlighted_cells: Array[Vector2i] = []

@export var tile_map: TileMap
@export var cell_size: int = 64

func _ready():
	tile_map.position = Vector2(0, 0)
	add_to_group("map_manager")
	load_map_data()
	print("✅ MapManager готов!")

func get_tile_id_at_cell(cell: Vector2i) -> int:
	if tile_map == null:
		return -1
	return tile_map.get_cell_source_id(0, cell)

# === ПОДСВЕТКА КЛЕТОК ===
func highlight_available_cells(center_cell: Vector2i, range: int, unit: BaseUnit = null):
	clear_highlight()
	
	var cells = get_cells_in_range(center_cell, range)
	
	for cell in cells:
		if is_passable(cell) and not is_cell_occupied(cell):
			# Передаём ignore_unit=true, чтобы юнит не блокировал сам себя
			var path = find_path(center_cell, cell, range, true)
			if not path.is_empty():
				tile_map.set_cell(1, cell, 0, Vector2i(0, 0))
				tile_map.set_layer_modulate(1, Color(0.184, 1.0, 1.0, 0.502)) # ← Добавь это!
				highlighted_cells.append(cell)

func clear_highlight():
	for cell in highlighted_cells:
		tile_map.set_cell(1, cell, -1)  # -1 удаляет тайл
	highlighted_cells.clear()

# === ПОИСК ПУТИ (BFS с обходом препятствий) ===

# Исправленная функция поиска пути
func find_path(from_cell: Vector2i, to_cell: Vector2i, max_range: int, ignore_unit: bool = false) -> Array[Vector2i]:
	if from_cell == to_cell:
		return [from_cell]
	
	if not is_passable(to_cell):
		return []
	
	# Если ignore_unit = true, не проверяем занятость целевой клетки
	# (потому что там стоит сам юнит, который хочет пойти)
	if not ignore_unit and is_cell_occupied(to_cell):
		return []
	
	# BFS
	var queue: Array[Vector2i] = []
	var came_from: Dictionary = {}
	var visited: Dictionary = {}
	
	queue.append(from_cell)
	visited[from_cell] = 0
	came_from[from_cell] = null
	
	var found = false
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_distance = visited[current]
		
		if current == to_cell:
			found = true
			break
		
		if current_distance >= max_range:
			continue
		
		var neighbors = get_neighbors(current)
		for neighbor in neighbors:
			if not visited.has(neighbor):
				# Проверяем проходимость
				if is_passable(neighbor):
					# Для промежуточных клеток тоже проверяем занятость
					if not (ignore_unit and neighbor == from_cell) and is_cell_occupied(neighbor):
						continue
					
					queue.append(neighbor)
					visited[neighbor] = current_distance + 1
					came_from[neighbor] = current
	
	if not found:
		return []
	
	# Восстанавливаем путь
	var path: Array[Vector2i] = []
	var current = to_cell
	
	while current != null:
		path.append(current)
		current = came_from.get(current)
	
	path.reverse()
	return path

# === ПРОВЕРКА ВАЛИДНОСТИ ===
func validate_move(from_cell: Vector2i, to_cell: Vector2i, max_range: int) -> bool:
	if not is_passable(to_cell):
		print("❌ Клетка непроходима")
		return false
	
	if is_cell_occupied(to_cell):
		print("❌ Клетка занята юнитом")
		return false
	
	var path = find_path(from_cell, to_cell, max_range, false)
	if path.is_empty():
		print("❌ Нет пути")
		return false
	
	return true

# === ОБРАБОТКА КЛИКОВ ===
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var cell = get_cell_at_position(mouse_pos)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if units_on_map.has(cell):
				# Клик по юниту → ВЫДЕЛЕНИЕ + ПОДСВЕТКА
				var unit = units_on_map[cell]
				unit.select_unit()
				highlight_available_cells(unit.current_cell, unit.current_movement)
				emit_signal("unit_selected", unit)
			else:
				# Клик по пустой клетке → ПЕРЕМЕЩЕНИЕ
				handle_cell_click(cell)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# ПКМ → отмена выделения и очистка подсветки
			clear_highlight()
			var selected = get_selected_unit()
			if selected:
				selected.deselect()

func handle_cell_click(cell: Vector2i):
	var selected_unit = get_selected_unit()
	if not selected_unit:
		return
	
	clear_highlight()
	
	# Здесь ignore_unit=false, потому что проверяем реальное перемещение
	if validate_move(selected_unit.current_cell, cell, selected_unit.current_movement):
		var path = find_path(selected_unit.current_cell, cell, selected_unit.current_movement, false)
		selected_unit.move_along_path(path)
	else:
		print("❌ Нельзя переместиться")

func load_map_data():
	if tile_map == null:
		printerr("❌ TileMap не установлен!")
		return
	
	var used_cells = tile_map.get_used_cells(0)
	
	for cell in used_cells:
		var tile_id = tile_map.get_cell_source_id(0, cell)
		
		var terrain_type = "unknown"
		var movement_cost = 1.0
		var is_passable = true
		
		match tile_id:
			1:  # bus
				terrain_type = "bus"
				movement_cost = 1.0
				is_passable = true
			0:  # field (непроходимо)
				terrain_type = "field"
				movement_cost = -1.0
				is_passable = false
			_:  # по умолчанию
				terrain_type = "bus"
				movement_cost = 1.0
				is_passable = true
		
		grid[cell] = {
			"terrain_type": terrain_type,
			"movement_cost": movement_cost,
			"is_passable": is_passable
		}
	
	print("🗺️ Загружено клеток: ", grid.size())

func get_cell_at_position(world_pos: Vector2) -> Vector2i:
	if tile_map == null:
		return Vector2i.ZERO
	var local_pos = tile_map.to_local(world_pos)
	return tile_map.local_to_map(local_pos)

func get_cell_world_position(cell: Vector2i) -> Vector2:
	if tile_map == null:
		return Vector2.ZERO
	# map_to_local() уже возвращает центр клетки!
	return tile_map.map_to_local(cell)

func is_passable(cell: Vector2i) -> bool:
	if not grid.has(cell):
		return false
	return grid[cell]["is_passable"]

func is_cell_occupied(cell: Vector2i) -> bool:
	return units_on_map.has(cell)

func register_unit(unit, cell: Vector2i):
	units_on_map[cell] = unit

func unregister_unit(cell: Vector2i):
	if units_on_map.has(cell):
		units_on_map.erase(cell)

func get_selected_unit():
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit.is_selected:
			return unit
	return null

func get_cells_in_range(center_cell: Vector2i, range: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []
	
	queue.append(center_cell)
	visited[center_cell] = 0
	
	while queue.size() > 0:
		var current_cell = queue.pop_front()
		var current_distance = visited[current_cell]
		
		if current_distance > range:
			continue
		
		result.append(current_cell)
		
		var neighbors = get_neighbors(current_cell)
		for neighbor in neighbors:
			if not visited.has(neighbor):
				visited[neighbor] = current_distance + 1
				queue.append(neighbor)
	
	return result

func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]
	
	var neighbors: Array[Vector2i] = []
	for dir in directions:
		var neighbor = cell + dir
		if grid.has(neighbor):
			neighbors.append(neighbor)
	
	return neighbors
