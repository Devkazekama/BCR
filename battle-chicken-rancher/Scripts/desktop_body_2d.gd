extends RigidBody2D
class_name DesktopBody2D

@export_group("Prototyping")
## Scales every visual and physics node attached to this object mathematically.
@export var base_scale_multiplier: float = 1.0

var is_walking: bool = false
var base_z_index: int = 0

var bounds_top: float = -20.0
var bounds_bottom: float = 20.0
var bounds_left: float = -20.0
var bounds_right: float = 20.0

func _ready() -> void:
	z_as_relative = false
	base_z_index = z_index
	
	# Enable contact monitoring for bounce and collisions
	contact_monitor = true
	max_contacts_reported = 4

	# 1. Universally scale everything inside this object FIRST
	if base_scale_multiplier != 1.0:
		_apply_universal_scale(self)
		
	# 2. THEN calculate the bounds based on the new massive/tiny size
	_calculate_collision_extents()

# ---------------------------------------------------------
# THE UNIVERSAL X-RAY SCALER
# ---------------------------------------------------------

func _apply_universal_scale(current_node: Node) -> void:
	for child in current_node.get_children():
		
		# Multiply local position offsets for ALL 2D nodes
		if child is Node2D:
			child.position *= base_scale_multiplier
			
		# Scale visual sprites
		if child is Sprite2D or child is AnimatedSprite2D:
			child.scale *= base_scale_multiplier
			
		# Multiply Raycast length (vital for your chicken's ground detection)
		elif child is RayCast2D:
			child.target_position *= base_scale_multiplier
			
		# Mathematically multiply Polygon silhouette points
		elif child is CollisionPolygon2D:
			var scaled_points = PackedVector2Array()
			for point in child.polygon:
				scaled_points.append(point * base_scale_multiplier)
			child.polygon = scaled_points
			
		# Mathematically multiply standard primitive shapes (Rectangles, Capsules, Circles)
		elif child is CollisionShape2D and child.shape:
			child.shape = child.shape.duplicate() # Duplicate so we don't scale globally shared resources
			if child.shape is RectangleShape2D:
				child.shape.size *= base_scale_multiplier
			elif child.shape is CapsuleShape2D:
				child.shape.radius *= base_scale_multiplier
				child.shape.height *= base_scale_multiplier
			elif child.shape is CircleShape2D:
				child.shape.radius *= base_scale_multiplier
				
		# Recursively dive deeper (e.g., Area2D -> CollisionShape2D)
		if child.get_child_count() > 0:
			_apply_universal_scale(child)

# ---------------------------------------------------------
# DESKTOP PHYSICS BOUNDARIES
# ---------------------------------------------------------

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

func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	# Bouncing and edge detection is now handled automatically
	# by the StaticBody2D boundaries spawned by DesktopManager.
	pass

