extends Control

@onready var close_button = $Panel/VBoxContainer/CloseButton

func _ready():
	# Скрываем при старте
	visible = false
	
	# Подключаем кнопку
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

func _on_close_button_pressed():
	hide_popup()

func show_tutorial():
	visible = true
	print("📖 Туториал открыт")

func hide_popup():
	visible = false
	print("📖 Туториал закрыт")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and visible:
			hide_popup()
