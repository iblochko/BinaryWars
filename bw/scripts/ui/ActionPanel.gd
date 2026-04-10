extends CanvasLayer

@onready var panel = $PanelContainer
@onready var unit_name = $PanelContainer/UnitInfo/UnitName
@onready var health_label = $PanelContainer/UnitInfo/HealthLabel
@onready var movement_label = $PanelContainer/UnitInfo/MovementLabel
@onready var attack_button = $PanelContainer/ActionButtons/AttackButton
@onready var defend_button = $PanelContainer/ActionButtons/DefendButton
@onready var wait_button = $PanelContainer/ActionButtons/ActionButton  # ⚠️ Проверь имя!
@onready var close_button = $PanelContainer/CloseButton

# === ХОТКЕИ ===
@export var hotkey_attack: String = "a"      
@export var hotkey_defend: String = "d"
@export var hotkey_wait: String = "space"     # Space — Пропуск
@export var hotkey_close: String = "escape"   # Escape — Закрыть

var current_unit: BaseUnit = null
var current_building: BaseBuilding = null
var is_visible_panel: bool = false

func _ready():
	panel.visible = false
	
	attack_button.pressed.connect(_on_attack_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	print("✅ ActionPanel готов!")

# === ОБРАБОТКА КЛАВИАТУРЫ ===
func _input(event):
	# Хоткеи работают ТОЛЬКО когда панель открыта
	if not is_visible_panel:
		return
	
	if event is InputEventKey and event.pressed:
		var key_name = OS.get_keycode_string(event.keycode).to_lower()
		
		if key_name == hotkey_attack:
			_on_attack_pressed()
			get_viewport().set_input_as_handled()
		
		elif key_name == hotkey_defend:
			_on_defend_pressed()
			get_viewport().set_input_as_handled()
		
		# Пропуск (Space)
		elif key_name == hotkey_wait:
			_on_wait_pressed()
			get_viewport().set_input_as_handled()
		
		# Закрыть (Escape)
		elif key_name == hotkey_close:
			_on_close_pressed()
			get_viewport().set_input_as_handled()

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
	current_unit = null
	panel.visible = false
	print("📋 Панель закрыта")

func _update_unit_info():
	if current_unit == null:
		return
	
	unit_name.text = "⚔️ " + current_unit.name
	health_label.text = "❤️ HP: " + str(current_unit.current_health) + "/" + str(current_unit.max_health) + " ⚔️ Атаки: " + str(current_unit.current_attack_amount) + "/" + str(current_unit.max_attack_amount)
	movement_label.text = "🚶 Ходы: " + str(current_unit.current_movement) + "/" + str(current_unit.movement_points)

func _update_buttons():
	if current_unit == null:
		return
	
	attack_button.disabled = false
	defend_button.disabled = false
	wait_button.disabled = false

func _on_defend_pressed():
	if current_unit == null:
		return
	
	print("🛡️ Защитная стойка!")
	current_unit.current_movement = 0
	current_unit.deselect()
	hide_panel()  # ← Закрыть панель

func _on_wait_pressed():
	if current_unit == null:
		return
	
	print("⏳ Пропуск хода")
	current_unit.current_movement = 0
	current_unit.deselect()
	hide_panel()  # ← Закрыть панель

func _on_close_pressed():
	hide_panel()

func show_panel_for_building(building: BaseBuilding):
	if building == null:
		return
	
	current_building = building
	current_unit = null  # Сбрасываем юнита
	is_visible_panel = true
	
	_update_building_info()
	panel.visible = true
	_update_building_buttons()

func _update_building_info():
	if current_building == null:
		return
	
	unit_name.text = "🏗️ " + current_building.name
	health_label.text = "❤️ HP: " + str(current_building.current_health) + "/" + str(current_building.max_health)
	movement_label.text = "💰 Стоимость: " + str(current_building.build_cost)

func _update_building_buttons():
	if current_building == null:
		return
	
	# Показываем кнопки для зданий
	attack_button.text = "⚔️ Произвести"
	attack_button.visible = current_building is BaseBarracks
	defend_button.visible = false
	wait_button.visible = false

func _on_attack_pressed():
	if current_building:
		# Производство юнита
		if current_building is BaseBarracks:
			current_building.produce_unit()
			hide_panel()
	elif current_unit:
		# Атака юнитом
			current_unit.enable_attack_mode()
	
			var map_manager = get_tree().get_first_node_in_group("map_manager")
			if map_manager:
				map_manager.set_process_input(true)
				current_unit.enable_attack_mode()
	hide_panel()

func update_health():
	if current_unit:
		_update_unit_info()
