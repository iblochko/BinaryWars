# MapManager.gd
extends Node2D

# Сигналы
signal unit_selected(unit)
signal unit_moved(unit, from_cell, to_cell)

# Данные карты
var grid: Dictionary = {}
var units_on_map: Dictionary = {}  # cell_pos → unit

@export var tile_map: TileMap
@export var cell_size: int = 64

func _ready():
	# Регистрируем в группе для доступа из других скриптов
	add_to_group("map_manager")
	
	# Загружаем данные карты
	load_map_data()
	
	print("Менеджер карты готов!")

func load_map_data():
	# Проверяем, что tile_map установлен
	if tile_map == null:
		printerr("Ошибка: Не установлена ссылка на TileMap!")
		printerr("Установите tile_map в инспекторе узла MapManager")
		return
	
	# Собираем данные из TileMap
	var used_cells = tile_map.get_used_cells(0)
	
	for cell in used_cells:
		var tile_data = tile_map.get_cell_tile_data(0, cell)
		
		# Определяем тип клетки по индексу тайла (или по цвету)
		var terrain_type = "unknown"
		var movement_cost = 1.0
		var is_passable = true
		
		# Простая логика: если тайл есть — клетка проходима
		if tile_data:
			# Можно определить тип по индексу тайла
			# Например: индекс 0 = трава, 1 = вода, 2 = горы
			var tile_id = tile_map.get_cell_source_id(0, cell)
			
			match tile_id:
				0:  # Трава
					terrain_type = "grass"
					movement_cost = 1.0
					is_passable = true
				1:  # Вода
					terrain_type = "water"
					movement_cost = -1.0
					is_passable = false
				2:  # Горы
					terrain_type = "mountain"
					movement_cost = -1.0
					is_passable = false
				_:  # По умолчанию
					terrain_type = "grass"
					movement_cost = 1.0
					is_passable = true
		else:
			# Пустая клетка
			terrain_type = "empty"
			movement_cost = -1.0
			is_passable = false
		
		grid[cell] = {
			"terrain_type": terrain_type,
			"movement_cost": movement_cost,
			"is_passable": is_passable
		}
	
	print("Загружено клеток: ", grid.size())

func get_cell_at_position(world_pos: Vector2) -> Vector2i:
	# Проверяем, что tile_map установлен
	if tile_map == null:
		return Vector2i.ZERO
	
	# Преобразуем мировые координаты в координаты клетки
	return tile_map.local_to_map(world_pos)

func get_cell_world_position(cell: Vector2i) -> Vector2:
	# Проверяем, что tile_map установлен
	if tile_map == null:
		return Vector2.ZERO
	
	# Преобразуем координаты клетки в мировые координаты
	return tile_map.map_to_local(cell)

func is_passable(cell: Vector2i) -> bool:
	if not grid.has(cell):
		return false
	
	return grid[cell]["is_passable"]

func is_cell_occupied(cell: Vector2i) -> bool:
	return units_on_map.has(cell)

func register_unit(unit, cell: Vector2i):
	units_on_map[cell] = unit
	print("Юнит зарегистрирован на клетке: ", cell)

func unregister_unit(cell: Vector2i):
	if units_on_map.has(cell):
		units_on_map.erase(cell)

func move_unit(unit, from_cell: Vector2i, to_cell: Vector2i):
	# Удаляем юнита со старой клетки
	unregister_unit(from_cell)
	
	# Регистрируем на новой клетке
	register_unit(unit, to_cell)
	
	# Сигнал о перемещении
	emit_signal("unit_moved", unit, from_cell, to_cell)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var cell = get_cell_at_position(mouse_pos)
		
		# Проверяем, кликнули ли на юнита
		if units_on_map.has(cell):
			var unit = units_on_map[cell]
			emit_signal("unit_selected", unit)
		else:
			# Клик по пустой клетке — перемещение
			handle_cell_click(cell)

func handle_cell_click(cell: Vector2i):
	# Находим выделенного юнита
	var selected_unit = get_selected_unit()
	
	if selected_unit:
		selected_unit.try_move_to_cell(cell)

func get_selected_unit():
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit.is_selected:
			return unit
	return null

func get_cells_in_range(center_cell: Vector2i, range: int) -> Array[Vector2i]:
	# Возвращает все клетки в радиусе 'range' от центральной клетки
	var result: Array[Vector2i] = []
	
	# Используем алгоритм "заливки" (BFS) для поиска всех доступных клеток
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []
	
	queue.append(center_cell)
	visited[center_cell] = 0  # Расстояние от центра = 0
	
	while queue.size() > 0:
		var current_cell = queue.pop_front()
		var current_distance = visited[current_cell]
		
		# Если вышли за пределы радиуса — прекращаем
		if current_distance > range:
			continue
		
		# Добавляем клетку в результат
		result.append(current_cell)
		
		# Проверяем всех соседей
		var neighbors = get_neighbors(current_cell)
		
		for neighbor in neighbors:
			if not visited.has(neighbor):
				visited[neighbor] = current_distance + 1
				queue.append(neighbor)
	
	return result


func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	# Возвращает 4 соседние клетки (вверх, вниз, влево, вправо)
	var directions = [
		Vector2i(1, 0),   # Вправо
		Vector2i(-1, 0),  # Влево
		Vector2i(0, 1),   # Вниз
		Vector2i(0, -1)   # Вверх
	]
	
	var neighbors: Array[Vector2i] = []
	
	for dir in directions:
		var neighbor = cell + dir
		
		# Проверяем, что клетка существует на карте
		if grid.has(neighbor):
			neighbors.append(neighbor)
	
	return neighbors
