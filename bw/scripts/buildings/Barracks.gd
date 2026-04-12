extends "res://scripts/buildings/Building.gd"
class_name BaseBarracks

@export var production_cost: int = 50
@export var unit_scene: PackedScene  # Сцена юнита для производства
var max_industry: int = 2
var industry: int = 2

func _on_building_ready():
	can_produce = true
	max_health = 150
	current_health = max_health
	build_cost = 100
	building_size = Vector2i(3, 3)
	# ✅ Текстуры устанавливаются в Building.gd через _apply_faction_visuals()
	
	print("⚔️ Казарма готова! Фракция: ", faction, " | Стоимость: ", build_cost)

func produce_unit():
	if not can_produce:
		print("❌ Казарма не может производить!")
		return
	
	if unit_scene == null:
		printerr("❌ Не назначена сцена юнита!")
		return
	
	print("🏗️ Производство юнита...")
	
	var unit = unit_scene.instantiate()
	var spawn_cell = _find_spawn_location()
	
	if spawn_cell != Vector2i.ZERO:
		unit.global_position = map_manager.get_cell_world_position(spawn_cell)
		
		# ✅ Устанавливаем фракцию юнита равной фракции здания!
		unit.faction = self.faction
		
		get_tree().current_scene.add_child(unit)
		print("✅ Юнит создан на клетке: ", spawn_cell, " | Фракция: ", unit.faction)
	else:
		print("❌ Нет места для юнита или достигнуто максимальное количество производимых юнитов!")
		unit.queue_free()

func _find_spawn_location() -> Vector2i:
	if industry <= 0:
		return Vector2i.ZERO
	# ✅ Проверяем клетки ВОКРУГ здания (не вокруг центра!)
	var half_width = floor(building_size.x / 2.0)
	var half_height = floor(building_size.y / 2.0)
	
	# Проверяем все клетки в радиусе 1 от границ здания
	for x in range(-half_width - 1, half_width + 2):
		for y in range(-half_height - 1, half_height + 2):
			var spawn_cell = current_cell + Vector2i(x, y)
			
			# ✅ Пропускаем клетки самого здания
			if occupied_cells.has(spawn_cell):
				continue
			
			# ✅ Проверяем проходимость и занятость
			if map_manager.is_passable(spawn_cell) and not map_manager.is_cell_occupied(spawn_cell):
				industry -= 1
				return spawn_cell
	
	return Vector2i.ZERO
func update_building():
	industry = max_industry
