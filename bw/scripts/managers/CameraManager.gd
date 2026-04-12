extends Camera2D

@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_speed: float = 0.1
@export var move_speed: float = 10.0
@export var move_acceleration: float = 500.0

@export var edge_scroll_enabled: bool = true
@export var edge_scroll_margin: int = 1
@export var edge_scroll_speed: float = 15.0

@export var map_width: float = 2520
@export var map_height: float = 1580
@export var bounds_enabled: bool = true

var _velocity = Vector2.ZERO

func _ready():
	position = Vector2(0, 0)
	print("📷 Camera ready! Map: ", map_width, "x", map_height)

func _unhandled_input(event):
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
	var direction = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1
	if Input.is_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_key_pressed(KEY_DOWN):
		direction.y += 1
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	if edge_scroll_enabled:
		direction += _get_edge_scroll_direction()
	
	if direction.length() > 0:
		if direction.length() > 1.0:
			direction = direction.normalized()
		
		_velocity = _velocity.move_toward(direction * move_speed, move_acceleration * delta)
	else:
		_velocity = _velocity.move_toward(Vector2.ZERO, move_acceleration * delta)
	
	position += _velocity * delta * 100 * zoom.x
	
	if bounds_enabled:
		_limit_position()

func _limit_position():
	var viewport_size = get_viewport().get_visible_rect().size
	var visible_width = viewport_size.x / zoom.x
	var visible_height = viewport_size.y / zoom.y
	
	var half_map_width = map_width / 2
	var half_map_height = map_height / 2
	
	var half_visible_width = visible_width / 2
	var half_visible_height = visible_height / 2
	
	var x_limit = half_map_width - half_visible_width
	var y_limit = half_map_height - half_visible_height
	
	if x_limit < 0: x_limit = 0
	if y_limit < 0: y_limit = 0
	
	position.x = clamp(position.x, -x_limit, x_limit)
	position.y = clamp(position.y, -y_limit, y_limit)

func _get_edge_scroll_direction() -> Vector2:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var direction = Vector2.ZERO
	
	if mouse_pos.x < edge_scroll_margin:
		direction.x -= 1
	if mouse_pos.x > viewport_size.x - edge_scroll_margin:
		direction.x += 1
	if mouse_pos.y < edge_scroll_margin:
		direction.y -= 1
	if mouse_pos.y > viewport_size.y - edge_scroll_margin:
		direction.y += 1
	
	return direction
