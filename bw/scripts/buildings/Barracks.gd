extends "res://scripts/buildings/Building.gd"

class_name BaseBarracks

@export var production_cost: int = 50
@export var unit_scene: PackedScene  # Сцена юнита для производства

func _on_building_ready():
	can_produce = true
	max_health = 150
	current_health = max_health
	build_cost = 100
	print("⚔️ Казарма готова! Стоимость: ", build_cost)

func produce_unit():
	if not can_produce:
		print("❌ Казарма не может производить!")
		return
	
	if unit_scene == null:
		printerr("❌ Не назначена сцена юнита!")
		return
	
	# Проверяем стоимость (нужна система ресурсов)
	# if resources < production_cost: return
	
	print("🏗️ Производство юнита...")
	
	# Создаём юнита рядом с казармой
	var unit = unit_scene.instantiate()
	var spawn_cell = _find_spawn_location()
	
	if spawn_cell != Vector2i.ZERO:
		unit.global_position = map_manager.get_cell_world_position(spawn_cell)
		get_tree().current_scene.add_child(unit)
		print("✅ Юнит создан на клетке: ", spawn_cell)
	else:
		print("❌ Нет места для юнита!")
		unit.queue_free()

func _find_spawn_location() -> Vector2i:
	# Ищем свободную клетку рядом
	var directions = [
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 0), Vector2i(-1, 0)
	]
	
	for dir in directions:
		var spawn_cell = current_cell + dir
		if map_manager.is_passable(spawn_cell) and not map_manager.is_cell_occupied(spawn_cell):
			return spawn_cell
	
	return Vector2i.ZERO
