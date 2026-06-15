extends CharacterBody2D
class_name DesktopBody2D

@export_group("Physics")
@export var gravity: float = 1200.0
@export var friction: float = 20.0

var is_walking: bool = false
var base_z_index: int = 0

var bounds_top: float = -20.0
var bounds_bottom: float = 20.0
var bounds_left: float = -20.0
var bounds_right: float = 20.0

func _ready() -> void:
	z_as_relative = false
	base_z_index = z_index
	_calculate_collision_extents()

func _calculate_collision_extents() -> void:
	var col_shape = get_node_or_null("CollisionShape2D")
	var poly_shape = get_node_or_null("CollisionPolygon2D")
	
	if col_shape and col_shape.shape:
		var rect = col_shape.shape.get_rect()
		var local_rect = Rect2(col_shape.position + (rect.position * col_shape.scale), rect.size * col_shape.scale)
		bounds_top = local_rect.position.y
		bounds_bottom = local_rect.end.y
		bounds_left = local_rect.position.x
		bounds_right = local_rect.end.x
		
	elif poly_shape and poly_shape.polygon.size() > 0:
		bounds_left = 99999.0
		bounds_right = -99999.0
		bounds_top = 99999.0
		bounds_bottom = -99999.0
		
		for p in poly_shape.polygon:
			var scaled_p = (p * poly_shape.scale) + poly_shape.position
			if scaled_p.x < bounds_left: bounds_left = scaled_p.x
			if scaled_p.x > bounds_right: bounds_right = scaled_p.x
			if scaled_p.y < bounds_top: bounds_top = scaled_p.y
			if scaled_p.y > bounds_bottom: bounds_bottom = scaled_p.y

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	var screen_rect = DisplayServer.screen_get_usable_rect(get_window().current_screen)
	
	var floor_limit = screen_rect.end.y - GameSettings.taskbar_offset - bounds_bottom
	
	if global_position.y >= floor_limit - 1.0 and not is_walking:
		velocity.x = move_toward(velocity.x, 0, friction * 50 * delta)

	move_and_slide()
	_handle_screen_bounce(screen_rect, floor_limit)

func _handle_screen_bounce(screen_rect: Rect2, floor_limit: float) -> void:
	var ceiling_limit = screen_rect.position.y - bounds_top
	var left_limit = screen_rect.position.x - bounds_left
	var right_limit = screen_rect.end.x - bounds_right
	
	if global_position.y > floor_limit:
		global_position.y = floor_limit
		if velocity.y > 200: velocity.y *= -0.5
		else: velocity.y = 0
		
	if global_position.y < ceiling_limit:
		global_position.y = ceiling_limit
		velocity.y *= -0.5
		
	if global_position.x > right_limit:
		global_position.x = right_limit
		velocity.x *= -0.5
		
	if global_position.x < left_limit:
		global_position.x = left_limit
		velocity.x *= -0.5
