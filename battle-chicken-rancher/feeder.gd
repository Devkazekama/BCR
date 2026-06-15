extends PickableItem
class_name Feeder

var food_stock: int = 0
@onready var drop_zone: Area2D = $DropZone

func _ready() -> void:
	z_index = 0
	super._ready()
	add_to_group("feeder")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# The Vacuum Logic
	if drop_zone:
		for body in drop_zone.get_overlapping_bodies():
			if body.is_in_group("food") and not body.is_queued_for_deletion():
				
				# ARCHITECTURE FIX: We removed the "is_dragging" check!
				# Now, if you drag the corn over the Area2D, the feeder will 
				# instantly snatch it right out of your cursor.
				add_food(1)
				body.queue_free()

# ---------------------------------------------------------
# FEEDER DATA LOGIC
# ---------------------------------------------------------

func add_food(amount: int) -> void:
	food_stock += amount
	print("Feeder stocked! Current feed: ", food_stock)

func consume_food() -> bool:
	if food_stock > 0:
		food_stock -= 1
		print("Food consumed. Remaining feed: ", food_stock)
		return true
	return false
