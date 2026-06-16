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
