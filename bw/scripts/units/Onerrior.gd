# Onerrior.gd
extends "res://scripts/units/Unit.gd"  # ← Наследуемся от базового класса

#уникальные характеристики
@export var health: int = 100
@export var attack: int = 10
@export var defense: int = 5

#инициализация
func _on_unit_ready():
	attack_range = 1
	movement_points = 4
	max_health = 100
	print("⚔️ Воин создан! Здоровье: ", health, " Атака: ", attack)
	#добавить визуальные эффекты?

func attack_target(target_unit: BaseUnit):
	if target_unit == null:
		return
	
	var distance = _get_distance_to(target_unit.current_cell)
	if distance <= attack_range:
		target_unit.take_damage(attack)
		print("⚔️ Атака по цели! Урон: ", attack)
	else:
		print("❌ Цель слишком далеко!")

func _get_distance_to(cell: Vector2i) -> int:
	return abs(current_cell.x - cell.x) + abs(current_cell.y - cell.y)

func die():
	print("💀 Воин погиб!")
	if map_manager:
		map_manager.unregister_unit(current_cell)
	queue_free()

#после движения
func _on_movement_finished():
	print(" Воин завершил движение")
