extends DesktopBody2D
class_name PickableItem

@export_group("Motion Blur & VFX")
@export var use_motion_blur: bool = true
@export var min_speed: float = 1800.0
@export var stop_speed: float = 800.0
@export var spawn_distance: float = 40.0 
@export var trail_lifetime: float = 0.12 
@export var start_opacity: float = 0.15
@export var max_shader_pull: float = 0.08

var is_dragging: bool = false
var is_hovered: bool = false
var is_attached: bool = false

var drag_offset: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var throw_velocity: Vector2 = Vector2.ZERO

var last_pos: Vector2
var distance_accumulated: float = 0.0
var is_trailing: bool = false
var active_ghosts: Array[Sprite2D] = []
var sprite_node: Node2D = null
var frames_alive: int = 0

func _ready() -> void:
	super._ready()
	
	input_pickable = true
	mouse_entered.connect(func(): is_hovered = true)
	mouse_exited.connect(func(): is_hovered = false)
	
	last_pos = global_position
	add_to_group("pickable")

	if has_node("AnimatedSprite2D"): sprite_node = $AnimatedSprite2D
	elif has_node("Sprite2D"): sprite_node = $Sprite2D
	elif has_node("BodySprite"): sprite_node = $BodySprite

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_hovered:
				var highest_z = -999
				var winner = null
				
				for item in get_tree().get_nodes_in_group("pickable"):
					if is_instance_valid(item) and item.is_hovered:
						if item.base_z_index >= highest_z:
							highest_z = item.base_z_index
							winner = item
							
				if winner == self:
					is_dragging = true
					is_attached = false
					z_index = 100
					drag_offset = global_position - get_global_mouse_position()
					last_mouse_pos = get_global_mouse_position()
					
					throw_velocity = Vector2.ZERO
					distance_accumulated = 0.0
					last_pos = global_position
					
					get_viewport().set_input_as_handled()
					_on_picked_up()
					
		elif not event.pressed and is_dragging:
			is_dragging = false
			z_index = base_z_index
			velocity = throw_velocity
			_on_dropped()

func _physics_process(delta: float) -> void:
	if is_attached:
		pass
	elif is_dragging:
		var current_mouse_pos = get_global_mouse_position()
		throw_velocity = (current_mouse_pos - last_mouse_pos) / delta
		last_mouse_pos = current_mouse_pos
		global_position = current_mouse_pos + drag_offset
		velocity = Vector2.ZERO
	else:
		super._physics_process(delta) 

	if use_motion_blur:
		_handle_motion_blur(delta)
	else:
		last_pos = global_position

func _handle_motion_blur(delta: float) -> void:
	frames_alive += 1
	if frames_alive <= 3:
		last_pos = global_position
		return

	var distance_moved = last_pos.distance_to(global_position)
	
	if distance_moved > 2000.0:
		last_pos = global_position
		distance_accumulated = 0.0
		if sprite_node and sprite_node.material is ShaderMaterial:
			sprite_node.material.set_shader_parameter("blur_velocity", Vector2.ZERO)
		return

	var current_speed = 0.0
	if delta > 0:
		current_speed = distance_moved / delta
		
	if current_speed >= min_speed:
		is_trailing = true
	elif current_speed <= stop_speed:
		is_trailing = false
		distance_accumulated = 0.0

	if is_trailing and distance_moved > 0.001 and sprite_node:
		var direction = (global_position - last_pos).normalized()
		
		if sprite_node.material is ShaderMaterial:
			var pull_strength = min(current_speed * 0.00003, max_shader_pull)
			sprite_node.material.set_shader_parameter("blur_velocity", direction * pull_strength)

		var distance_to_next_spawn = spawn_distance - distance_accumulated
		var distance_traversed = 0.0
		var spawn_count = 0
		
		while distance_to_next_spawn <= (distance_moved - distance_traversed) and spawn_count < 25:
			distance_traversed += distance_to_next_spawn
			_spawn_ghost(last_pos + (direction * distance_traversed))
			distance_accumulated = 0.0
			distance_to_next_spawn = spawn_distance
			spawn_count += 1
			
		if spawn_count >= 25:
			distance_accumulated = 0.0
		else:
			distance_accumulated += (distance_moved - distance_traversed)
	else:
		if sprite_node and sprite_node.material is ShaderMaterial:
			sprite_node.material.set_shader_parameter("blur_velocity", Vector2.ZERO)
			
	last_pos = global_position

func _spawn_ghost(spawn_pos: Vector2) -> void:
	var ghost = Sprite2D.new()
	if sprite_node is AnimatedSprite2D: ghost.texture = sprite_node.sprite_frames.get_frame_texture(sprite_node.animation, sprite_node.frame)
	elif sprite_node is Sprite2D: ghost.texture = sprite_node.texture
	
	ghost.global_position = spawn_pos + sprite_node.position
	ghost.scale = sprite_node.global_scale
	if "flip_h" in sprite_node: ghost.flip_h = sprite_node.flip_h
	
	ghost.z_as_relative = false
	ghost.z_index = base_z_index - 1
	
	ghost.top_level = true
	ghost.modulate = Color(1.0, 1.0, 1.0, start_opacity)
	
	get_parent().add_child(ghost)
	active_ghosts.append(ghost)
	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, trail_lifetime).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		if ghost in active_ghosts:
			active_ghosts.erase(ghost)
		if is_instance_valid(ghost) and not ghost.is_queued_for_deletion():
			ghost.queue_free()
	)

func _on_picked_up() -> void:
	pass

func _on_dropped() -> void:
	pass
