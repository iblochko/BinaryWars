extends Camera2D

@export var min_zoom: float = 0.1
@export var max_zoom: float = 3.0
@export var zoom_speed: float = 0.1
@export var move_speed: float = 10.0
@export var move_acceleration: float = 500.0

var _velocity = Vector2.ZERO

func _unhandled_input(event):
	#колесиком мыши
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(1 + zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(1 - zoom_speed)

func _zoom_camera(factor):
	var new_zoom_x = zoom.x * factor
	var new_zoom_y = zoom.y * factor
	new_zoom_x = clamp(new_zoom_x, min_zoom, max_zoom)
	new_zoom_y = clamp(new_zoom_y, min_zoom, max_zoom)
	zoom = Vector2(new_zoom_x, new_zoom_y)

func _process(delta):
	#стрелочками
	var direction = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		direction.y += 1
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	_velocity = _velocity.move_toward(direction * move_speed, move_acceleration * delta)

	position += _velocity * delta * 100 * zoom.x
