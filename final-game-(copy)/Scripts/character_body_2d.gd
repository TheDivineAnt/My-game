extends CharacterBody2D

@export var max_speed: float = 200.0
@export var acceleration: float = 800.0
@export var rotation_speed: float = 10.0 

# This should match the 'Target Position X' of your RayCast2D
@export var max_light_distance: float = 300.0

# Battery/Light logic
var light_energy: float = 100.0
var base_drain: float = 1.0

func _physics_process(delta: float) -> void:
	# 1. MOVEMENT
	velocity = velocity.move_toward(_direction() * max_speed, _adjusted_acceleration(delta))
	move_and_slide()

	# 2. SMOOTH ROTATION
	var target_angle = (get_global_mouse_position() - global_position).angle()
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

	# 3. RAYCAST & POINTLIGHT2D LOGIC
	var ray = get_node_or_null("RayCast2D")
	var light = get_node_or_null("PointLight2D")

	if ray and light:
		if ray.is_colliding():
			# Get the distance to whatever the light is hitting
			var hit_point = ray.get_collision_point()
			var distance = global_position.distance_to(hit_point)
			
			# CALCULATE REALISTIC SIZE:
			# Shorter distance = smaller texture_scale
			var new_scale = distance / max_light_distance
			light.texture_scale = clamp(new_scale, 0.1, 1.2)
			
			# CALCULATE REALISTIC BRIGHTNESS:
			# Makes the light 'hotter' and brighter when close to a wall
			light.energy = 1.2 + (1.0 - (distance / max_light_distance))

			# Monster Interaction
			if ray.get_collider().name == "Monster":
				light_energy -= (base_drain * 5) * delta
				print("Monster in light!")
		else:
			# RESET: If looking into the void, keep the light at normal size/brightness
			light.texture_scale = 1.2
			light.energy = 1.0

# --- HELPER FUNCTIONS ---

func _input(event):
	# Toggle light with right-click
	if event.is_action_pressed("ui_right"):
		if has_node("PointLight2D"):
			$PointLight2D.enabled = !$PointLight2D.enabled

func _adjusted_acceleration(delta:float) -> float:
	return acceleration * delta

func _direction() -> Vector2:
	return Input.get_vector("left", "right" , "up" , "down")
