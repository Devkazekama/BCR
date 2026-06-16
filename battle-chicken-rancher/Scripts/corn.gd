extends PickableItem
class_name CornItem

func _ready() -> void:
	z_index = 1

	# Collision logic: Layer 2, Mask 2 (Props collide only with Props)
	collision_layer = 2
	collision_mask = 2

	super._ready()
	
	# Ensure the vacuum recognizes it as food
	add_to_group("food")

func _on_picked_up() -> void:
	super._on_picked_up()
	if is_attached:
		is_attached = false
		# Detach from the plant pot's spawn point and move to the main world tree
		var current_global_pos = global_position
		var current_global_rot = global_rotation
		var old_parent = get_parent()

		if old_parent:
			old_parent.remove_child(self)

		# Add to the root desktop manager container or current scene
		var root = get_tree().current_scene
		if root.has_node("EntityContainer"):
			root.get_node("EntityContainer").add_child(self)
		else:
			root.add_child(self)

		global_position = current_global_pos
		global_rotation = current_global_rot
		freeze = false
