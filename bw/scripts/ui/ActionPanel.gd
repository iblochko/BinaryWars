extends CanvasLayer

@onready var panel = $PanelContainer
@onready var unit_name = $PanelContainer/UnitInfo/UnitName
@onready var health_label = $PanelContainer/UnitInfo/HealthLabel
@onready var movement_label = $PanelContainer/UnitInfo/MovementLabel
@onready var attack_button = $PanelContainer/ActionButtons/AttackButton
@onready var defend_button = $PanelContainer/ActionButtons/DefendButton
@onready var wait_button = $PanelContainer/ActionButtons/ActionButton
@onready var close_button = $PanelContainer/CloseButton

var current_unit: BaseUnit = null
var is_visible_panel: bool = false

func _ready():
	panel.visible = false
	
	attack_button.pressed.connect(_on_attack_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	print("✅ ActionPanel готов!")

func show_panel(unit: BaseUnit):
	if unit == null:
		printerr("❌ Юнит не передан в show_panel()!")
		return
	
	current_unit = unit
	is_visible_panel = true
	
	_update_unit_info()
	panel.visible = true
	_update_buttons()
	
	print("📋 Панель открыта для: ", unit.name)

func hide_panel():
	is_visible_panel = false
	current_unit = null  # Сбрасываем
	panel.visible = false
	print("📋 Панель закрыта")

func _update_unit_info():
	if current_unit == null:  # ✅ ПРОВЕРКА!
		return
	
	unit_name.text = "⚔️ " + current_unit.name
	health_label.text = "❤️ HP: " + str(current_unit.current_health) + "/" + str(current_unit.max_health)
	movement_label.text = "🚶 Ходы: " + str(current_unit.current_movement) + "/" + str(current_unit.movement_points)

func _update_buttons():
	if current_unit == null:  # ✅ ПРОВЕРКА!
		return
	
	attack_button.disabled = false
	defend_button.disabled = false
	wait_button.disabled = false

func _on_attack_pressed():
	if current_unit == null:  # ✅ ПРОВЕРКА!
		printerr("❌ current_unit = null в _on_attack_pressed()!")
		return
	
	print("⚔️ Атака выбрана!")
	
	var map_manager = get_tree().get_first_node_in_group("map_manager")
	if map_manager:
		map_manager.highlight_attack_cells(current_unit.current_cell, 1)
	
	hide_panel()

func _on_defend_pressed():
	if current_unit == null:
		return
	
	print("🛡️ Защитная стойка!")
	current_unit.current_movement = 0
	current_unit.deselect()
	hide_panel()

func _on_wait_pressed():
	if current_unit == null:
		return
	
	print("⏳ Пропуск хода")
	current_unit.current_movement = 0
	current_unit.deselect()
	hide_panel()

func _on_close_pressed():
	hide_panel()

func update_health():
	if current_unit:  # ✅ ПРОВЕРКА!
		_update_unit_info()
