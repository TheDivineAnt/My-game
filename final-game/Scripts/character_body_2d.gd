extends CharacterBody2D

@export var max_speed: float = 200.0
@export var acceleration: float = 800.0
@export var rotation_speed: float = 10.0 

@export var max_light_distance: float = 300.0

# Battery configuration (Tuned for slower draining)
@export var max_battery: float = 100.0
var current_battery: float = 100.0
var passive_drain: float = 0.5  # Loses 1 battery every 2 seconds normally
var monster_drain: float = 6.0   # Fast drain when actively staring at the enemy

func _physics_process(delta: float) -> void:
	# 1. MOVEMENT & ROTATION
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
		# If the flashlight runs out of battery, trigger INSTANT DEATH
		if light.enabled:
			current_battery -= passive_drain * delta
			if current_battery <= 0:
				current_battery = 0
				light.enabled = false
				
				print("BATTERY DEPLETED - GAME OVER")
				get_tree().reload_current_scene() 
				return 

		# Calculate battery percentage for dimming (Value between 0.0 and 1.0)
		var battery_percentage: float = current_battery / max_battery
		# Keep a tiny sliver of visibility (0.15) even at near-zero battery so it isn't completely pitch black
		var dim_factor: float = clamp(battery_percentage, 0.15, 1.0)

		# Flashlight physical visual scaling using the RayCast
		if light.enabled and ray and ray.is_colliding():
			var hit_point = ray.get_collision_point()
			var distance = global_position.distance_to(hit_point)
			
			var new_scale = distance / max_light_distance
			light.texture_scale = clamp(new_scale, 0.1, 1.2)
			
			# Base dynamic energy multiplied by our battery dim factor
			var base_energy = 1.2 + (1.0 - (distance / max_light_distance))
			light.energy = base_energy * dim_factor
		else:
			if light.enabled:
				light.texture_scale = 1.2
				# Default energy multiplied by our battery dim factor
				light.energy = 1.0 * dim_factor

		# 4. CONE DETECTOR LOGIC (Stunning the Enemy)
		if light.enabled and flashlight_cone:
			var overlapping_bodies = flashlight_cone.get_overlapping_bodies()
			var actively_stunning: bool = false
			
			for body in overlapping_bodies:
				if body.name == "Enemy" or body.is_in_group("Enemy"):
					actively_stunning = true
					
					if body.has_method("flash_blind"):
						body.flash_blind()
			
			if actively_stunning:
				current_battery -= (monster_drain - passive_drain) * delta
				print("Blinding Enemy! Battery remaining: ", int(current_battery))
				
				# Re-check battery during active stun to prevent delayed death
				if current_battery <= 0:
					current_battery = 0
					light.enabled = false
					print("BATTERY DEPLETED DURING STUN - GAME OVER")
					get_tree().reload_current_scene()
					return

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
	# Only allow toggling if we actually have battery left
	if event.is_action_pressed("ui_right") and current_battery > 0:
		if has_node("flashlight"):
			$flashlight.enabled = !$flashlight.enabled

func _adjusted_acceleration(delta: float) -> float:
	return acceleration * delta

func _direction() -> Vector2:
	return Input.get_vector("left", "right" , "up" , "down")
