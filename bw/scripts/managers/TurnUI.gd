extends CanvasLayer

@onready var turn_label = $Panel/TurnLabel
@onready var faction_label = $Panel/FactionLabel
@onready var end_turn_button = $Panel/EndTurnButton

var turn_manager = null

func _ready():
	print("🔍 TurnLabel: ", $Panel/TurnLabel)
	print("🔍 FactionLabel: ", $Panel/FactionLabel)
	print("🔍 EndTurnButton: ", $Panel/EndTurnButton)
	turn_manager = get_tree().get_first_node_in_group("turn_manager")
	
	if turn_manager:
		# Подключаемся к сигналам
		turn_manager.turn_started.connect(_on_turn_started)
		turn_manager.turn_ended.connect(_on_turn_ended)
		
		# Обновляем UI
		_update_ui()
	
	# Кнопка
	end_turn_button.pressed.connect(_on_end_turn_pressed)

func _input(event):
	
	if event is InputEventKey and event.pressed:
		var key_name = OS.get_keycode_string(event.keycode).to_lower()
		
		if key_name == "t":
			_on_end_turn_pressed()
			get_viewport().set_input_as_handled()

func _update_ui():
	if not turn_manager:
		return
	
	var info = turn_manager.get_turn_info()
	
	turn_label.text = "Ход: " + str(info.turn)
	
	# ✅ ИСПРАВЬ ПРОВЕРКУ — используем enum TurnManager!
	if info.faction == turn_manager.Faction.PLAYER_0:
		faction_label.text = "👤 Player 0 (Zerrior)"
		faction_label.modulate = Color(0.5, 1, 0.5, 1)
		end_turn_button.disabled = not info.is_active
	else: 
		faction_label.text = "👤 Player 1 (Onerrior)"
		faction_label.modulate = Color(0.5, 1, 0.5, 1)
		end_turn_button.disabled = not info.is_active

func _on_turn_started(turn_number, faction):
	_update_ui()

func _on_turn_ended(turn_number, faction):
	_update_ui()

func _on_end_turn_pressed():
	if turn_manager:
		turn_manager.on_end_turn_button_pressed()
