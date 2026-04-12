extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var tutorial_button = $VBoxContainer/TutorialButton
@onready var exit_button = $VBoxContainer/ExitButton
@onready var tutorial_popup = $TutorialPopup

func _ready():
	# Подключаем кнопки
	print("создано")
	start_button.pressed.connect(_on_start_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# ✅ Скрываем туториал
	if tutorial_popup:
		tutorial_popup.visible = false
	
	print("🎮 Главное меню готово!")

func _on_start_pressed():
	print("🚀 Запуск игры...")
	
	var game_scene = load("res://scenes/game/Game.tscn")
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		printerr("❌ Не удалось загрузить сцену игры!")

func _on_tutorial_pressed():
	print("📖 Открытие туториала...")
	
	if tutorial_popup:
		tutorial_popup.show_tutorial()
	else:
		print("📖 Не открылся...")
func _on_exit_pressed():
	print("👋 Выход из игры...")
	get_tree().quit()
