extends CharacterBody2D

@export var max_speed: float = 200.0
@export var acceleration: float = 800.0
@export var rotation_speed: float = 10.0 

@export var max_light_distance: float = 300.0

# Battery variables
@export var max_battery: float = 100.0
var current_battery: float = 100.0
var passive_drain: float = 2.0  # Constant drain while light is ON
var monster_drain: float = 15.0 # Extra drain when staring at the monster

func _physics_process(delta: float) -> void:
	# 1. MOVEMENT & ROTATION
	velocity = velocity.move_toward(_direction() * max_speed, _adjusted_acceleration(delta))
	move_and_slide()

	var target_angle = (get_global_mouse_position() - global_position).angle()
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

	# 2. TUNNEL CHECKING
	_check_tile_underneath()

	# 3. RAYCAST & POINTLIGHT2D LOGIC
	var ray = get_node_or_null("RayCast2D")
	var light = get_node_or_null("PointLight2D")

	if light and ray:
		# If the light runs out of battery, shut it off completely
		if light.enabled:
			current_battery -= passive_drain * delta
			if current_battery <= 0:
				current_battery = 0
				light.enabled = false
				print("Flashlight battery died!")

		# Flashlight physical adjustments
		if light.enabled and ray.is_colliding():
			var collider = ray.get_collider()
			var hit_point = ray.get_collision_point()
			var distance = global_position.distance_to(hit_point)
			
			var new_scale = distance / max_light_distance
			light.texture_scale = clamp(new_scale, 0.1, 1.2)
			light.energy = 1.2 + (1.0 - (distance / max_light_distance))

			# Monster Interaction
			if collider and collider.name == "Monster":
				# Battery drains much faster when resisting the monster
				current_battery -= monster_drain * delta
				
				# Trigger the monster's flee mechanism
				if collider.has_method("flash_blind"):
					collider.flash_blind()
		else:
			if light.enabled:
				light.texture_scale = 1.2
				light.energy = 1.0

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
		if has_node("PointLight2D"):
			$PointLight2D.enabled = !$PointLight2D.enabled

func _adjusted_acceleration(delta:float) -> float:
	return acceleration * delta

func _direction() -> Vector2:
	return Input.get_vector("left", "right" , "up" , "down")
