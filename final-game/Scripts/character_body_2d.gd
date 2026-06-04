extends CharacterBody2D

@export var max_speed: float = 200.0
@export var acceleration: float = 800.0
@export var rotation_speed: float = 10.0 

@export var max_light_distance: float = 300.0

# Node Paths for Plates and Doors (Can be assigned in Inspector, or falls back to names)
@export var plate_1_path: NodePath
@export var plate_2_path: NodePath
@export var door_path: NodePath

# Battery configuration (Tuned for slower draining)
@export var max_battery: float = 100.0
var current_battery: float = 100.0
var passive_drain: float = 0.5  # Loses 1 battery every 2 seconds normally
var monster_drain: float = 6.0   # Fast drain when actively staring at the enemy

# Tracking Variables
var monster: CharacterBody2D
var plate_1: Node2D
var plate_2: Node2D
var exit_door: Node2D

var plate_1_active: bool = false
var plate_2_active: bool = false

func _ready() -> void:
	# Safely look for the Enemy directly in the level
	monster = get_node_or_null("../Enemy") as CharacterBody2D
	if not monster:
		print("WARNING: Could not find the Enemy node in the level!")
		
	# Safely check for paths, using get_node_or_null so the game NEVER freezes if they are missing
	if plate_1_path:
		plate_1 = get_node_or_null(plate_1_path) as Node2D
	else:
		plate_1 = get_node_or_null("../PressurePlate1") as Node2D

	if plate_2_path:
		plate_2 = get_node_or_null(plate_2_path) as Node2D
	else:
		plate_2 = get_node_or_null("../PressurePlate2") as Node2D

	if door_path:
		exit_door = get_node_or_null(door_path) as Node2D
	else:
		exit_door = get_node_or_null("../ExitDoor") as Node2D

func _physics_process(delta: float) -> void:
	# 1. MOVEMENT & ROTATION (Guaranteed to process now)
	velocity = velocity.move_toward(_direction() * max_speed, _adjusted_acceleration(delta))
	move_and_slide()

	var target_angle = (get_global_mouse_position() - global_position).angle()
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

	# 2. TUNNEL CHECKING
	_check_tile_underneath()

	# 3. RAYCAST & FLASHLIGHT LOGIC
	var ray = get_node_or_null("RayCast2D")
	var light = get_node_or_null("flashlight") 
	var flashlight_cone = get_node_or_null("FlashlightCone") 

	if light:
		if light.enabled:
			current_battery -= passive_drain * delta
			if current_battery <= 0:
				current_battery = 0
				light.enabled = false
				
				print("BATTERY DEPLETED - GAME OVER")
				get_tree().reload_current_scene() 
				return 

		var battery_percentage: float = current_battery / max_battery
		var dim_factor: float = clamp(battery_percentage, 0.15, 1.0)

		if light.enabled and ray and ray.is_colliding():
			var hit_point = ray.get_collision_point()
			var distance = global_position.distance_to(hit_point)
			
			var new_scale = distance / max_light_distance
			light.texture_scale = clamp(new_scale, 0.1, 1.2)
			
			var base_energy = 1.2 + (1.0 - (distance / max_light_distance))
			light.energy = base_energy * dim_factor
		else:
			if light.enabled:
				light.texture_scale = 1.2
				light.energy = 1.0 * dim_factor

		# 4. CONE DETECTOR LOGIC (Stunning the Enemy)
		if light.enabled and flashlight_cone:
			var overlapping_bodies = flashlight_cone.get_overlapping_bodies()
			var actively_stunning: bool = false
			
			for body in overlapping_bodies:
				if body.name == "Enemy" or body.is_in_group("Enemy") or body == monster:
					actively_stunning = true
					if body.has_method("flash_blind"):
						body.flash_blind()
			
			if actively_stunning:
				current_battery -= (monster_drain - passive_drain) * delta
				print("Blinding Enemy! Battery remaining: ", int(current_battery))
				
				if current_battery <= 0:
					current_battery = 0
					light.enabled = false
					print("BATTERY DEPLETED DURING STUN - GAME OVER")
					get_tree().reload_current_scene()
					return

func _process(_delta: float) -> void:
	# 5. PRESSURE PLATE & DOOR PROXIMITY LOGIC
	# These blocks now verify the node exists first so your player never locks up
	if plate_1 and global_position.distance_to(plate_1.global_position) < 50.0:
		if not plate_1_active:
			plate_1_active = true
			plate_1.modulate = Color(0, 1, 0)
			print("Plate 1 Activated!")

	if plate_2 and global_position.distance_to(plate_2.global_position) < 50.0:
		if not plate_2_active:
			plate_2_active = true
			plate_2.modulate = Color(0, 1, 0)
			print("Plate 2 Activated!")

	# Handle door visibility and escape conditions safely
	if plate_1_active and plate_2_active and exit_door:
		if exit_door.visible:
			exit_door.visible = false
			print("Exit Door Opened!")
			
		if global_position.distance_to(exit_door.global_position) < 60.0:
			print("YOU ESCAPED! VICTORY!")
			get_tree().reload_current_scene() 

# --- HELPER FUNCTIONS ---

func _check_tile_underneath() -> void:
	var tilemap = get_node_or_null("../TileMap") 
	if tilemap:
		var tile_pos = tilemap.local_to_map(global_position)
		var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
		if tile_data:
			var type = tile_data.get_custom_data("tile_type")
			if type == "tunnel":
				z_index = 0
				modulate.a = 0.5
			elif type == "above":
				z_index = 2
				modulate.a = 1.0
		else:
			z_index = 2
			modulate.a = 1.0

func _input(event):
	if event.is_action_pressed("ui_right") and current_battery > 0:
		if has_node("flashlight"):
			$flashlight.enabled = !$flashlight.enabled

func _adjusted_acceleration(delta: float) -> float:
	return acceleration * delta

func _direction() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")
