extends PickableItem
class_name PlantPot

@export var corn_scene: PackedScene
@export var sort_container: Node2D

@onready var timer: Timer = $Timer
@onready var spawn_point: Marker2D = $SpawnPoint

var current_corn: Node2D = null

func _ready() -> void:
	z_index = 0
	
	# High dampening so it doesn't slide across the floor
	linear_damp = 5.0
	angular_damp = 5.0

	# Collision logic: Layer 3, Mask 3 (Facilities collide only with Facilities)
	collision_layer = 4 # 2^2
	collision_mask = 4  # 2^2

	# Calling super._ready() allows DesktopBody2D to calculate its bounds_bottom
	super._ready()

	# ARCHITECTURE FIX: Unified Floor Math
	# The PlantPot now calculates the exact same floor limit as the chicken and feeder.
	# It will perfectly rest on the taskbar regardless of your monitor size!
	var viewport_rect = get_viewport_rect()
	var floor_limit = (viewport_rect.size.y - 15.0) - GameSettings.taskbar_offset - bounds_bottom
	global_position = Vector2(global_position.x, floor_limit)

	if timer:
		if not timer.is_connected("timeout", _on_timer_timeout):
			timer.timeout.connect(_on_timer_timeout)
		timer.start()
	else:
		print("ERROR: Timer node not found!")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_instance_valid(current_corn) and not current_corn.is_queued_for_deletion():
		if current_corn.get("is_attached") == true:
			current_corn.global_position = spawn_point.global_position
			current_corn.rotation = self.rotation

func _on_picked_up() -> void:
	super._on_picked_up()
	if is_instance_valid(current_corn) and not current_corn.is_queued_for_deletion():
		if current_corn.get("is_attached") == true:
			current_corn.z_index = self.z_index + 1

func _on_dropped() -> void:
	super._on_dropped()
	if is_instance_valid(current_corn) and not current_corn.is_queued_for_deletion():
		if current_corn.get("is_attached") == true:
			current_corn.z_index = current_corn.base_z_index

func _on_timer_timeout() -> void:
	if is_instance_valid(current_corn) and not current_corn.is_queued_for_deletion():
		if current_corn.get("is_attached") == true:
			return

	spawn_corn()

func spawn_corn() -> void:
	if corn_scene:
		current_corn = corn_scene.instantiate()
		current_corn.add_to_group("food")
		
		if "is_attached" in current_corn:
			current_corn.is_attached = true
			current_corn.freeze = true

		current_corn.z_as_relative = false
		current_corn.z_index = 1
		
		if sort_container:
			sort_container.call_deferred("add_child", current_corn)
		else:
			get_parent().call_deferred("add_child", current_corn)

		await get_tree().process_frame

		if is_instance_valid(current_corn):
			current_corn.global_position = spawn_point.global_position
