# Onerrior.gd
extends CharacterBody2D

# Параметры юнита
@export var speed: float = 100.0  # Скорость движения
@export var health: int = 100     # Здоровье
@export var attack: int = 10      # Атака

func _ready():
	print("Воин создан! Здоровье: ", health)

func _process(delta):
	# Получаем направление движения (стрелки)
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Устанавливаем скорость
	velocity = direction * speed
	
	# Двигаем юнита
	move_and_slide()

func take_damage(amount: int):
	health = max(0, health - amount)
	print("Получено ", amount, " урона. Осталось: ", health)
	
	if health <= 0:
		die()

func die():
	print("Воин умер!")
	queue_free()  # Удаляем юнита из сцены
