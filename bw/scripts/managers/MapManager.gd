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
	
		# Установите смещение карты
	tile_map.position = Vector2(0, 0)
	
	# Или если нужно сместить:
	# tile_map.position = Vector2(-32, -32)  # Центрирование
	# Регистрируем в группе для доступа из других скриптов
	add_to_group("map_manager")
	
	# Загружаем данные карты
	load_map_data()
	
	print("Менеджер карты готов!")
	print("ID тайла на клетке (0, 0): ", get_tile_id_at_cell(Vector2i(0, 0)))
	print("ID тайла на клетке (-18, -9): ", get_tile_id_at_cell(Vector2i(-18, -9)))

func get_tile_id_at_cell(cell: Vector2i) -> int:
	if tile_map == null:
		return -1
	return tile_map.get_cell_source_id(0, cell)

func get_tile_id_at_position(world_pos: Vector2) -> int:
	var cell = get_cell_at_position(world_pos)
	return tile_map.get_cell_source_id(0, cell)

# Визуализация доступных клеток для перемещения
func highlight_moveable_cells(center_cell: Vector2i, range: int):
	var cells = get_cells_in_range(center_cell, range)
	for cell in cells:
		if is_passable(cell) and not is_cell_occupied(cell):
			# Здесь можно добавить визуальный эффект (например, изменить цвет тайла)
			print("Доступна клетка: ", cell)

# Добавь эти функции в MapManager.gd

# Проверка валидности перемещения с учётом дальности
func validate_move(from_cell: Vector2i, to_cell: Vector2i, max_range: int) -> bool:
	if not is_passable(to_cell):
		print("❌ Клетка непроходима")
		return false
	if is_cell_occupied(to_cell):
		print("❌ Клетка занята")
		return false
	
	# Манхэттенское расстояние
	var distance = abs(to_cell.x - from_cell.x) + abs(to_cell.y - from_cell.y)
	if distance > max_range:
		print("❌ Слишком далеко")
		return false
	
	return true

# Поиск пути (простой BFS для начала)
func find_path(from_cell: Vector2i, to_cell: Vector2i, max_range: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	
	if not validate_move(from_cell, to_cell, max_range):
		return path
	
	# Для начала — прямой путь (можно улучшить алгоритмом A*)
	var current = from_cell
	while current != to_cell:
		path.append(current)
		
		# Двигаемся по оси X сначала
		if current.x < to_cell.x:
			current.x += 1
		elif current.x > to_cell.x:
			current.x -= 1
		# Потом по оси Y
		elif current.y < to_cell.y:
			current.y += 1
		elif current.y > to_cell.y:
			current.y -= 1
	
	path.append(to_cell)
	return path

# Обновлённая handle_cell_click
func handle_cell_click(cell: Vector2i):
	var selected_unit = get_selected_unit()
	if not selected_unit:
		return
	
	# Запрашиваем путь у MapManager
	var path = find_path(selected_unit.current_cell, cell, selected_unit.current_movement)
	
	if path.is_empty():
		print("❌ Невозможно переместиться")
		return
	
	# Передаём путь юниту
	selected_unit.move_along_path(path)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var cell = get_cell_at_position(mouse_pos)
		
		# Выводим координаты клетки
		print("Клик по клетке: ", cell)
		print("  Мировые координаты: ", mouse_pos)
	
		if units_on_map.has(cell):
			var unit = units_on_map[cell]
			print("  На клетке есть юнит: ", unit.name)
			emit_signal("unit_selected", unit)
		else:
			# Клик по пустой клетке — перемещение
			print("  Клетка пустая")
			handle_cell_click(cell)

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
				1:  
					terrain_type = "bus"
					movement_cost = 1.0
					is_passable = true
				0:
					terrain_type = "field"
					movement_cost = -1.0
					is_passable = false
				_:  # По умолчанию
					terrain_type = "bus"
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

# Используем правильный размер клетки (16)
func get_cell_at_position(world_pos: Vector2) -> Vector2i:
	if tile_map == null:
		return Vector2i.ZERO
	
	var local_pos = tile_map.to_local(world_pos)
	
	return tile_map.local_to_map(local_pos)

func get_cell_world_position(cell: Vector2i) -> Vector2:
	if tile_map == null:
		return Vector2.ZERO
	
	# Правильное преобразование
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
