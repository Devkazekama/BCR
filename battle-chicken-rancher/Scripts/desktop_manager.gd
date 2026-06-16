extends Node
class_name DesktopManager

@export var entity_container: Node2D

func _ready() -> void:
	get_viewport().transparent_bg = true
	Input.set_use_accumulated_input(false)
	call_deferred("_setup_window")

func _setup_window() -> void:
	var main_window: Window = get_window()
	main_window.borderless = true
	main_window.always_on_top = true
	main_window.transparent = true
	
	var screen_rect = DisplayServer.screen_get_usable_rect(main_window.current_screen)
	main_window.position = screen_rect.position
	
	# The 15px invisible gutter to safely catch interpolation bounces
	main_window.size = Vector2(screen_rect.size.x, screen_rect.size.y + 15)

	if entity_container:
		entity_container.position = Vector2.ZERO

	_setup_physics_boundaries(screen_rect)

func _setup_physics_boundaries(screen_rect: Rect2) -> void:
	var boundary_thickness = 100.0

	# Create boundaries parent node
	var boundaries_node = Node2D.new()
	boundaries_node.name = "PhysicsBoundaries"
	add_child(boundaries_node)

	# Helper to create a static body segment
	var create_wall = func(rect: Rect2, name: String):
		var static_body = StaticBody2D.new()
		static_body.name = name

		# Set collision layers - boundary walls should collide with everything
		static_body.collision_layer = 1 | 2 | 4 | 8
		static_body.collision_mask = 0 # Walls don't need to check for anything, just be hit

		var collision_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = rect.size
		collision_shape.shape = rect_shape
		collision_shape.position = rect.position + (rect.size / 2.0)

		static_body.add_child(collision_shape)
		boundaries_node.add_child(static_body)

	# Floor
	var floor_y = screen_rect.size.y - GameSettings.taskbar_offset
	create_wall.call(Rect2(-boundary_thickness, floor_y, screen_rect.size.x + (boundary_thickness * 2), boundary_thickness), "Floor")

	# Ceiling
	create_wall.call(Rect2(-boundary_thickness, -boundary_thickness, screen_rect.size.x + (boundary_thickness * 2), boundary_thickness), "Ceiling")

	# Left Wall
	create_wall.call(Rect2(-boundary_thickness, -boundary_thickness, boundary_thickness, screen_rect.size.y + (boundary_thickness * 2)), "LeftWall")

	# Right Wall
	create_wall.call(Rect2(screen_rect.size.x, -boundary_thickness, boundary_thickness, screen_rect.size.y + (boundary_thickness * 2)), "RightWall")

func _process(_delta: float) -> void:
	_update_passthrough_region()

func _update_passthrough_region() -> void:
	var polygons: Array[PackedVector2Array] = []
	
	for child in entity_container.get_children():
		if not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
			
		if child.is_visible_in_tree() and child is Node2D:
			var rect = _get_node_rect(child)
			if rect.has_area():
				var poly = PackedVector2Array([
					rect.position,
					Vector2(rect.end.x, rect.position.y),
					rect.end,
					Vector2(rect.position.x, rect.end.y)
				])
				polygons.append(poly)
				
	if polygons.size() == 0:
		DisplayServer.window_set_mouse_passthrough([Vector2(-1, -1)])
		return

	var islands = polygons.duplicate()
	var merging = true
	while merging:
		merging = false
		for i in range(islands.size()):
			for j in range(i + 1, islands.size()):
				var result = Geometry2D.merge_polygons(islands[i], islands[j])
				if result.size() == 1:
					islands[i] = result[0]
					islands.remove_at(j)
					merging = true
					break
			if merging:
				break

	var sorted_islands = []
	for island in islands:
		var highest_point = island[0]
		var highest_index = 0
		for i in range(1, island.size()):
			if island[i].y < highest_point.y:
				highest_point = island[i]
				highest_index = i
		sorted_islands.append({
			"poly": island,
			"point": highest_point,
			"index": highest_index
		})
		
	sorted_islands.sort_custom(func(a, b): return a.point.x < b.point.x)

	var master_poly = PackedVector2Array()
	var win_size = get_window().size
	
	master_poly.append(Vector2(1, -1)) 

	for data in sorted_islands:
		var island = data.poly
		var highest_point = data.point
		var highest_index = data.index

		master_poly.append(Vector2(highest_point.x, -1))
		master_poly.append(highest_point)

		for i in range(island.size() + 1):
			var idx = (highest_index + i) % island.size()
			master_poly.append(island[idx])
			
		master_poly.append(Vector2(highest_point.x + 0.1, -1))

	master_poly.append(Vector2(win_size.x - 1, -1)) 
	DisplayServer.window_set_mouse_passthrough(master_poly)

func _get_node_rect(node: Node2D) -> Rect2:
	var base_rect: Rect2
	
	var poly_node: CollisionPolygon2D = node.get_node_or_null("CollisionPolygon2D")
	var col_shape: CollisionShape2D = node.get_node_or_null("CollisionShape2D")
	
	if poly_node and poly_node.polygon.size() > 0:
		var points = poly_node.polygon
		var min_p = points[0]
		var max_p = points[0]
		for p in points:
			min_p.x = min(min_p.x, p.x)
			min_p.y = min(min_p.y, p.y)
			max_p.x = max(max_p.x, p.x)
			max_p.y = max(max_p.y, p.y)
			
		var scaled_size = (max_p - min_p) * poly_node.global_scale
		var scaled_pos = min_p * poly_node.global_scale
		base_rect = Rect2(poly_node.global_position + scaled_pos, scaled_size)
		
	elif col_shape and col_shape.shape:
		var rect = col_shape.shape.get_rect()
		base_rect = Rect2(col_shape.global_position + rect.position, rect.size * col_shape.global_scale)
	else:
		base_rect = Rect2(node.global_position - Vector2(25, 25), Vector2(50, 50))
		
	if "active_ghosts" in node:
		for ghost in node.active_ghosts:
			if is_instance_valid(ghost) and not ghost.is_queued_for_deletion():
				var ghost_rect = Rect2(ghost.global_position - (base_rect.size / 2.0), base_rect.size)
				base_rect = base_rect.merge(ghost_rect)

	if "is_dragging" in node and node.get("is_dragging") == true:
		base_rect = base_rect.grow(150.0)
		
		if "throw_velocity" in node:
			var predicted_offset = node.throw_velocity * get_process_delta_time() * 4.0 
			var future_rect = base_rect
			future_rect.position += predicted_offset
			base_rect = base_rect.merge(future_rect)
			
	elif "velocity" in node and node.get("velocity") != Vector2.ZERO:
		var vel = node.get("velocity")
		
		var predicted_offset = vel * get_process_delta_time() * 6.0
		var future_rect = base_rect
		future_rect.position += predicted_offset
		base_rect = base_rect.merge(future_rect)
		
		var speed_buffer = max(30.0, vel.length() * get_process_delta_time() * 0.75)
		base_rect = base_rect.grow(speed_buffer)
		
	var final_rect = base_rect.grow(5.0)
	var safe_window_rect = Rect2(Vector2.ZERO, get_window().size).grow(-2.0)
	
	return final_rect.intersection(safe_window_rect)
