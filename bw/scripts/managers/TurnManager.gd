extends Node

# === Сигналы ===
signal turn_started(turn_number, current_faction)
signal turn_ended(turn_number, previous_faction)
signal phase_changed(phase)

# === Фракции ===
enum Faction {
	PLAYER,
	ENEMY
}

# === Состояние ===
var current_turn: int = 1
var current_faction: Faction = Faction.PLAYER
var is_turn_active: bool = true
var units_moved: int = 0
var total_units: int = 0

# === Настройки ===
@export var allow_enemy_turn: bool = true

func _ready():
	add_to_group("turn_manager")
	print(" TurnManager готов!")
	
	# Начинаем первый ход
	start_turn()

# === НАЧАЛО ХОДА ===
func start_turn():
	print("🔄 === Ход ", current_turn, " ===")
	print("👤 Фракция: ", _get_faction_name(current_faction))
	
	is_turn_active = true
	units_moved = 0
	total_units = 0
	
	# Считаем юнитов текущей фракции
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if _is_unit_faction(unit, current_faction):
			total_units += 1
			# Восстанавливаем ходы
			unit.reset_movement()
			unit.reset_attacks()
	
	emit_signal("turn_started", current_turn, current_faction)
	emit_signal("phase_changed", "player_action" if current_faction == Faction.PLAYER else "enemy_action")

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
	if current_faction == Faction.PLAYER:
		current_faction = Faction.ENEMY
		
		# Если есть вражеский ход
		if allow_enemy_turn:
			start_turn()
			# Здесь для врага
			await _enemy_turn()
		else:
			# Сразу обратно к игроку
			current_turn += 1
			current_faction = Faction.PLAYER
			start_turn()
	else:
		current_turn += 1
		current_faction = Faction.PLAYER
		start_turn()

# === ПРОСТОЙ AI ВРАГА (заглушка) ===
func _enemy_turn():
	print("🤖 Ход врага...")
	
	# TODO: Добавить логику вражеских юнитов
	# Например: случайные движения или атака
	
	await get_tree().create_timer(2.0).timeout
	print("🤖 Враг завершил ход")
	
	# Автоматически завершаем ход врага
	end_turn()

# === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
func _get_faction_name(faction: Faction) -> String:
	match faction:
		Faction.PLAYER:
			return "Игрок"
		Faction.ENEMY:
			return "Враг"
		_:
			return "Неизвестно"

func _is_unit_faction(unit, faction: Faction) -> bool:
	# Проверяем фракцию юнита (можно добавить свойство faction в Unit.gd)
	# Пока считаем всех юнитов игрока
	return true  # TODO: Добавить проверку фракции

# === КНОПКА ЗАВЕРШИТЬ ХОД (вызывается из UI) ===
func on_end_turn_button_pressed():
	if current_faction == Faction.PLAYER and is_turn_active:
		end_turn()
	else:
		print("⚠️ Сейчас не ваш ход!")

# === СТАТИСТИКА ===
func get_turn_info() -> Dictionary:
	return {
		"turn": current_turn,
		"faction": current_faction,
		"is_active": is_turn_active,
		"units_moved": units_moved,
		"total_units": total_units
	}
