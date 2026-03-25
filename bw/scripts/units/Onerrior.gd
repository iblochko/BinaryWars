# Onerrior.gd
extends "res://scripts/units/Unit.gd"  # ← Наследуемся от базового класса

#уникальные характеристики
@export var health: int = 100
@export var max_health: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var attack_range: int = 1

#инициализация
func _on_unit_ready():
	print("⚔️ Воин создан! Здоровье: ", health, " Атака: ", attack)
	#добавить визуальные эффекты?

#уникальные способности
func take_damage(amount: int):
	var actual_damage = max(0, amount - defense)
	health = max(0, health - actual_damage)
	print("🛡️ Воин получил ", actual_damage, " урона. Осталось: ", health)
	
	if health <= 0:
		die()

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
