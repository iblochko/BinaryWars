extends Node2D

signal unit_selected(unit)
signal unit_moved(unit, from_cell, to_cell)

# === КАРТА ===
var grid: Dictionary = {}
var units_on_map: Dictionary = {}  # cell → unit
var buildings_on_map: Dictionary = {}  # cell → building ✅ Новое!
var highlighted_cells: Array[Vector2i] = []

@export var tile_map: TileMap
@export var cell_size: int = 64

func _ready():
	tile_map.position = Vector2(0, 0)
	add_to_group("map_manager")
	load_map_data()
	print("✅ MapManager готов!")

# === ЗАГРУЗКА КАРТЫ ===
func load_map_data():
	if tile_map == null:
		printerr("❌ TileMap не установлен!")
		return
	
	# === 1. ЗАГРУЗКА КЛЕТОК (слой 0) ===
	var used_cells = tile_map.get_used_cells(0)
	
	for cell in used_cells:
		var tile_id = tile_map.get_cell_source_id(0, cell)
		
		var terrain_type = "unknown"
		var movement_cost = 1.0
		var is_passable = true
		
		match tile_id:
			1:
				terrain_type = "bus"
				movement_cost = 1.0
				is_passable = true
			0:
				terrain_type = "field"
				movement_cost = -1.0
				is_passable = false
			_:
				terrain_type = "bus"
				movement_cost = 1.0
				is_passable = true
		
		grid[cell] = {
			"terrain_type": terrain_type,
			"movement_cost": movement_cost,
			"is_passable": is_passable
		}
	
	print("🗺️ Загружено клеток: ", grid.size())
	
	# === 2. ЗАГРУЗКА ЗДАНИЙ (слой 2) ✅ ===
	_load_buildings_from_tilemap()

# === ЗАГРУЗКА ЗДАНИЙ ИЗ TILEMAP ===
func _load_buildings_from_tilemap():
	var building_cells = tile_map.get_used_cells(2)
	
	if building_cells.size() == 0:
		print("🏗️ Здания на карте не найдены")
		return
	
	print("🏗️ Найдено зданий: ", building_cells.size())
	
	for cell in building_cells:
		var tile_id = tile_map.get_cell_source_id(2, cell)
		var building_scene_path = ""
		
		match tile_id:
			0:
				building_scene_path = "res://scenes/buildings/Barracks.tscn"
			1:
				building_scene_path = "res://scenes/buildings/Tower.tscn"
			2:
				building_scene_path = "res://scenes/buildings/Factory.tscn"
			_:
				print("⚠️ Неизвестный тип здания: ", tile_id, " на клетке ", cell)
				continue
		
		if building_scene_path != "":
			var building_scene = load(building_scene_path)
			if building_scene:
				var building = building_scene.instantiate()
				building.global_position = get_cell_world_position(cell)
				
				var game_scene = get_tree().current_scene
				if game_scene:
					var buildings_node = game_scene.get_node_or_null("Buildings")
					if buildings_node == null:
						buildings_node = Node2D.new()
						buildings_node.name = "Buildings"
						game_scene.add_child(buildings_node)
					
					buildings_node.add_child(building)
					register_building(building, cell)
					
					print("✅ Здание создано: ", building.name, " на клетке ", cell)

# === РЕГИСТРАЦИЯ ЗДАНИЙ ===
func register_building(building, cell: Vector2i):
	buildings_on_map[cell] = building
	print("🏗️ Здание зарегистрировано на клетке: ", cell)
	print("🔍 buildings_on_map keys: ", buildings_on_map.keys())  # ← Отладка

func unregister_building(cell: Vector2i):
	if buildings_on_map.has(cell):
		buildings_on_map.erase(cell)

# === ПРОВЕРКА ЗАНЯТОСТИ (юниты + здания) ===
func is_cell_occupied(cell: Vector2i) -> bool:
	return units_on_map.has(cell) or buildings_on_map.has(cell)

# === ПОЗИЦИИ КЛЕТОК ===
func get_cell_at_position(world_pos: Vector2) -> Vector2i:
	if tile_map == null:
		return Vector2i.ZERO
	var local_pos = tile_map.to_local(world_pos)
	return tile_map.local_to_map(local_pos)

func get_cell_world_position(cell: Vector2i) -> Vector2:
	if tile_map == null:
		return Vector2.ZERO
	return tile_map.map_to_local(cell)

# === ПРОВЕРКА КЛЕТОК ===
func is_passable(cell: Vector2i) -> bool:
	if not grid.has(cell):
		return false
	return grid[cell]["is_passable"]

# === РЕГИСТРАЦИЯ ЮНИТОВ ===
func register_unit(unit, cell: Vector2i):
	units_on_map[cell] = unit

func unregister_unit(cell: Vector2i):
	if units_on_map.has(cell):
		units_on_map.erase(cell)

# === СОСЕДИ ===
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

# === КЛЕТКИ В РАДИУСЕ ===
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

# === ПОИСК ПУТИ ===
func find_path(from_cell: Vector2i, to_cell: Vector2i, max_range: int, ignore_unit: bool = false) -> Array[Vector2i]:
	if from_cell == to_cell:
		return [from_cell]
	
	if not is_passable(to_cell):
		return []
	
	if not ignore_unit and is_cell_occupied(to_cell):
		return []
	
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
				if is_passable(neighbor):
					if not (ignore_unit and neighbor == from_cell) and is_cell_occupied(neighbor):
						continue
					
					queue.append(neighbor)
					visited[neighbor] = current_distance + 1
					came_from[neighbor] = current
	
	if not found:
		return []
	
	var path: Array[Vector2i] = []
	var current = to_cell
	
	while current != null:
		path.append(current)
		current = came_from.get(current)
	
	path.reverse()
	return path

# === ПОДСВЕТКА ===
func highlight_available_cells(center_cell: Vector2i, range: int, unit: BaseUnit = null):
	clear_highlight()
	
	var cells = get_cells_in_range(center_cell, range)
	
	for cell in cells:
		if is_passable(cell) and not is_cell_occupied(cell):
			var path = find_path(center_cell, cell, range, true)
			if not path.is_empty():
				tile_map.set_cell(1, cell, 0, Vector2i(0, 0))
				highlighted_cells.append(cell)
	
	tile_map.set_layer_modulate(1, Color(0.184, 1.0, 1.0, 0.502))

func highlight_attack_cells(center_cell: Vector2i, attack_range: int, attacker: BaseUnit):
	clear_highlight()
	
	var cells = get_cells_in_range(center_cell, attack_range)
	
	for cell in cells:
		if units_on_map.has(cell):
			var unit = units_on_map[cell]
			
			if unit != attacker:
				tile_map.set_cell(1, cell, 0, Vector2i(0, 0))
				highlighted_cells.append(cell)
	
	# Красный оттенок для атаки
	tile_map.set_layer_modulate(1, Color(1, 0.3, 0.3, 0.5))

func clear_highlight():
	for cell in highlighted_cells:
		tile_map.set_cell(1, cell, -1)
	highlighted_cells.clear()
	tile_map.set_layer_modulate(1, Color(1, 1, 1, 1))

# === ВЫБРАННЫЙ ЮНИТ ===
func get_selected_unit() -> BaseUnit:
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit.is_selected:
			return unit
	return null

# === ВВОД ===
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if _is_mouse_over_ui():
			return
		
		var mouse_pos = get_global_mouse_position()
		var cell = get_cell_at_position(mouse_pos)
		
		print("🔍 Клик по клетке: ", cell)
		print("🔍 units_on_map: ", units_on_map.has(cell))
		print("🔍 buildings_on_map: ", buildings_on_map.has(cell))  # ← Добавь!
		print("🔍 buildings_on_map keys: ", buildings_on_map.keys())  # ← Добавь!
		
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if units_on_map.has(cell):
				var unit = units_on_map[cell]
				print("  На клетке есть юнит: ", unit.name)
				# Снимаем выделение со всех зданий
				for b_cell in buildings_on_map:
					var b = buildings_on_map[b_cell]
					if b.is_selected:
						b.deselect_building()
				
				unit.select_unit()
				highlight_available_cells(unit.current_cell, unit.current_movement, unit)
				emit_signal("unit_selected", unit)
			elif buildings_on_map.has(cell):
				# ✅ Клик по зданию
				var building = buildings_on_map[cell]
				print("  На клетке есть здание: ", building.name)
				building.select_building()
			else:
				print("  Клетка пустая")
				handle_cell_click(cell)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click(cell)

func handle_right_click(cell: Vector2i):
	var selected_unit = get_selected_unit()
	
	if not selected_unit:
		for b_cell in buildings_on_map:
			var b = buildings_on_map[b_cell]
			if b.is_selected:
				b.deselect_building()
		clear_highlight()
		print("❌ Нет выбранного юнита")
		return
	
	if selected_unit.is_attack_mode:
		if units_on_map.has(cell):
			var target_unit = units_on_map[cell]
			
			if target_unit != selected_unit:
				if selected_unit.current_attack_amount > 0:
					selected_unit.attack_target(target_unit)
					selected_unit.current_attack_amount -= 1
					var action_panel = get_tree().current_scene.get_node_or_null("ActionPanel")
					if action_panel:
						action_panel.update_health()
					return
				else:
					print("Атаки кончились")
			else:
				print("❌ Нельзя атаковать себя!")
		# ✅ АТАКА ПО ЗДАНИЯМ
		elif buildings_on_map.has(cell):
			var target_building = buildings_on_map[cell]
			
			if target_building.faction != selected_unit.faction:
				if selected_unit.current_attack_amount > 0:
					selected_unit.attack_target(target_building)
					selected_unit.current_attack_amount -= 1
					var action_panel = get_tree().current_scene.get_node_or_null("ActionPanel")
					if action_panel:
						action_panel.update_health()
					return
				else:
					print("Атаки кончились")
			else:
				print("❌ Нельзя атаковать союзное здание!")
		else:
			print("❌ В клетке нет цели!")
		
		selected_unit.disable_attack_mode()
		clear_highlight()
	else:
		clear_highlight()
		selected_unit.deselect()
		print("🚫 Выделение снято")

func _is_mouse_over_ui() -> bool:
	var mouse_pos = get_viewport().get_mouse_position()
	
	var action_panel = get_tree().current_scene.get_node_or_null("ActionPanel")
	if action_panel and action_panel.visible:
		var panel = action_panel.get_node_or_null("PanelContainer")
		if panel:
			var panel_rect = panel.get_global_rect()
			if panel_rect.has_point(mouse_pos):
				return true
	
	var turn_ui = get_tree().current_scene.get_node_or_null("TurnUI")
	if turn_ui and turn_ui.visible:
		var panel = turn_ui.get_node_or_null("Panel")
		if panel:
			var ui_rect = panel.get_global_rect()
			if ui_rect.has_point(mouse_pos):
				return true
	
	return false

func handle_cell_click(cell: Vector2i):
	var selected_unit = get_selected_unit()
	if not selected_unit:
		return
	
	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager:
		if turn_manager.current_faction != turn_manager.Faction.PLAYER:
			print("⚠️ Сейчас не ваш ход!")
			return
		if not turn_manager.is_turn_active:
			print("⚠️ Ход завершён!")
			return
	
	clear_highlight()
	
	if validate_move(selected_unit.current_cell, cell, selected_unit.current_movement):
		var path = find_path(selected_unit.current_cell, cell, selected_unit.current_movement, false)
		selected_unit.move_along_path(path)
	else:
		print("❌ Нельзя переместиться")
		highlight_available_cells(selected_unit.current_cell, selected_unit.current_movement, selected_unit)

func validate_move(from_cell: Vector2i, to_cell: Vector2i, max_range: int) -> bool:
	if not is_passable(to_cell):
		print("❌ Клетка непроходима")
		return false
	
	if is_cell_occupied(to_cell):
		print("❌ Клетка занята")
		return false
	
	var path = find_path(from_cell, to_cell, max_range, false)
	if path.is_empty():
		print("❌ Нет пути")
		return false
	
	return true
