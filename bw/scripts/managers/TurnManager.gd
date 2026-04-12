extends Node

# === Сигналы ===
signal turn_started(turn_number, current_faction)
signal turn_ended(turn_number, previous_faction)
signal phase_changed(phase)

# === Фракции ===
enum Faction {
	PLAYER_0,  # Zerrior (команда 0)
	PLAYER_1   # Onerrior (команда 1)
}

# === Состояние ===
var current_turn: int = 1
var current_faction: Faction = Faction.PLAYER_1  # ✅ Начинаем с Player 1
var is_turn_active: bool = true
var units_moved: int = 0
var total_units: int = 0

# === Настройки ===
@export var allow_enemy_turn: bool = true

func _ready():
	add_to_group("turn_manager")
	print("🔄 TurnManager готов!")
	
	# Начинаем первый ход
	start_turn()

# === НАЧАЛО ХОДА ===
func start_turn():
	print("🔄 === Ход ", current_turn, " ===")
	print("👤 Фракция: ", _get_faction_name(current_faction))
	
	is_turn_active = true
	units_moved = 0
	total_units = 0
	
	# Считаем юнитов текущей фракции и восстанавливаем ходы
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if _is_unit_faction(unit, current_faction):
			total_units += 1
			# Восстанавливаем ходы и атаки
			unit.reset_movement()
			unit.reset_attacks()
			print("  ✅ ", unit.name, " получил ходы: ", unit.current_movement, " | Атаки: ", unit.current_attack_amount)
	
	emit_signal("turn_started", current_turn, current_faction)
	emit_signal("phase_changed", "player_action")
	

# === ЗАВЕРШЕНИЕ ХОДА ===
func end_turn():
	if not is_turn_active:
		print("⚠️ Ход уже завершён!")
		return
	
	print("✅ Ход ", current_turn, " завершён")
	
	is_turn_active = false
	emit_signal("turn_ended", current_turn, current_faction)
	
	# Снимаем выделение со всех юнитов
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		unit.deselect()
	
	# Снимаем выделение со всех зданий
	var all_buildings = get_tree().get_nodes_in_group("buildings")
	for building in all_buildings:
		building.update_building()
		if building.is_selected:
			building.deselect_building()
	
	# Очищаем подсветку
	var map_manager = get_tree().get_first_node_in_group("map_manager")
	if map_manager:
		map_manager.clear_highlight()
	
	# Переходим к следующему ходу
	await get_tree().create_timer(0.5).timeout
	_next_turn()

# === СЛЕДУЮЩИЙ ХОД ===
func _next_turn():
	# Смена фракции
	if current_faction == Faction.PLAYER_1:
		# Player 1 → Player 0
		current_faction = Faction.PLAYER_0
		start_turn()
	else:
		# Player 0 → Player 1 (новый ход)
		current_turn += 1
		current_faction = Faction.PLAYER_1
		start_turn()

# === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
func _get_faction_name(faction: Faction) -> String:
	match faction:
		Faction.PLAYER_0:
			return "Player 0 (Zerrior)"
		Faction.PLAYER_1:
			return "Player 1 (Onerrior)"
		_:
			return "Неизвестно"

func _is_unit_faction(unit, faction: Faction) -> bool:
	# ✅ ПРОВЕРЯЕМ faction юнита (0 или 1)
	if faction == Faction.PLAYER_0:
		return unit.faction == 0
	elif faction == Faction.PLAYER_1:
		return unit.faction == 1
	return false

# === КНОПКА ЗАВЕРШИТЬ ХОД (вызывается из UI) ===
func on_end_turn_button_pressed():
	if is_turn_active:
		end_turn()
	else:
		print("⚠️ Ход уже завершён!")

# === СТАТИСТИКА ===
func get_turn_info() -> Dictionary:
	return {
		"turn": current_turn,
		"faction": current_faction,
		"is_active": is_turn_active,
		"units_moved": units_moved,
		"total_units": total_units
	}
