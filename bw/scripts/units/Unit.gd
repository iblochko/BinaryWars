# Unit.gd
extends CharacterBody2D

# Параметры юнита
@export var movement_points: int = 2  # Сколько клеток может пройти за ход
@export var current_movement: int = 2  # Текущие очки движения

# Состояние
var is_selected: bool = false
var target_cell: Vector2i = Vector2i.ZERO
var current_cell: Vector2i = Vector2i.ZERO

# Ссылки
var map_manager = null

func _ready():
	# Находим менеджер карты
	map_manager = get_tree().get_first_node_in_group("map_manager")
	
	if map_manager == null:
		print("Ошибка: Не найден менеджер карты!")
		return
	
	# Регистрируем юнита в менеджере
	current_cell = map_manager.get_cell_at_position(global_position)
	map_manager.register_unit(self, current_cell)
	
	print("Юнит создан на клетке: ", current_cell)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
				# Проверяем, попал ли клик в коллизию
		var mouse_pos = get_global_mouse_position()
		var collision_shape = $CollisionShape2D
		
		# Отладка
		print("Позиция мыши: ", mouse_pos)
		print("Позиция коллизии: ", collision_shape.global_position)
		print("Размер коллизии: ", collision_shape.shape.extents)
		
		# Проверяем, попадает ли клик в коллизию
		var shape = collision_shape.shape
		if shape and shape is RectangleShape2D:
			var rect = shape.extents * 2
			var rect_pos = collision_shape.global_position - rect
			
			if mouse_pos.x > rect_pos.x and mouse_pos.x < rect_pos.x + rect.x and \
			mouse_pos.y > rect_pos.y and mouse_pos.y < rect_pos.y + rect.y:
				print("Клик попал в коллизию!")
				select_unit()

	# Проверяем клик только если юнит видим и активен
	if not visible or not is_inside_tree():
		return
	
	# Клик по юниту (выбор)
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		
		# Проверяем, попал ли клик в юнита
		if global_position.distance_to(mouse_pos) < 32:
			select_unit()

func select_unit():
	# Снимаем выделение со всех юнитов
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		unit.is_selected = false
		unit.update_indicator(false)
	
	# Выделяем текущего юнита
	is_selected = true
	update_indicator(true)
	
	print("Выбран юнит на клетке: ", current_cell)
	print("Осталось ходов: ", current_movement)

func update_indicator(show: bool):
	# Показываем/скрываем индикатор выделения
	if has_node("SelectionIndicator"):
		$SelectionIndicator.visible = show

func deselect():
	is_selected = false
	update_indicator(false)
	target_cell = Vector2i.ZERO

func _process(delta):
	# Если есть цель — двигаемся к ней
	if target_cell != Vector2i.ZERO:
		move_to_target(delta)

func move_to_target(delta):
	var target_world_pos = map_manager.get_cell_world_position(target_cell)
	
	# Плавное движение к цели
	global_position = global_position.move_toward(target_world_pos, 200 * delta)
	
	# Проверяем, достигли ли цели
	if global_position.distance_to(target_world_pos) < 1:
		on_arrived_at_target()

func on_arrived_at_target():
	# Обновляем текущую клетку
	current_cell = target_cell
	target_cell = Vector2i.ZERO
	
	# Расходуем очки движения
	current_movement -= 1
	
	print("Юнит прибыл на клетку: ", current_cell)
	print("Осталось ходов: ", current_movement)
	
	# Если закончились ходы — снимаем выделение
	if current_movement <= 0:
		deselect()

func try_move_to_cell(cell: Vector2i):
	# Проверяем, можно ли идти на эту клетку
	if not map_manager.is_passable(cell):
		print("Клетка непроходима!")
		return false
	
	if map_manager.is_cell_occupied(cell):
		print("Клетка занята другим юнитом!")
		return false
	
	if current_movement <= 0:
		print("Нет очков движения!")
		return false
	
	# Устанавливаем цель
	target_cell = cell
	print("Юнит идёт на клетку: ", cell)
	
# В скрипте юнита
func reset_movement():
	current_movement = movement_points
	print("Ходы восстановлены!")
	return true
