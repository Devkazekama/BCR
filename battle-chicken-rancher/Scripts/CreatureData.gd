extends Resource
class_name CreatureData

@export_group("Identity")
@export var species_name: String = "Apprentice Chick"
@export var rarity: int = 1 # 1 to 4
@export var evolution_tier: int = 1 # 1 to 4

@export_group("Core Stats")
@export var happiness: float = 50.0
@export var current_hunger: float = 100.0
@export var current_energy: float = 50.0
@export var accumulated_rest_time: float = 0.0 # Used to trigger evolutions

# Dynamic stat limits based on tier
var max_hunger: float:
	get: return 100.0 * evolution_tier # Larger chickens hold more food

var max_energy: float:
	get: return 100.0 * evolution_tier # Larger chickens have more stamina

var rest_multiplier: float:
	get: return 1.0 / evolution_tier # Larger chickens take longer to regain energy

var hunger_decay_rate: float:
	get: return 2.0 / evolution_tier # Larger chickens can go longer without food
