extends CharacterBody2D

# 1. THE VARIABLES: 'normal_speed' is your walking pace.
# 'current_speed' changes when you dash.
@export var normal_speed = 200.0
var current_speed = 200.0
var can_dash = true

# 2. THE MOVEMENT ENGINE: This runs 60 times a second for smooth physics.
func _physics_process(_delta):
	# GET INPUT: This creates a Vector (an arrow) based on W,A,S,D.
	# If you press 'D', input_dir.x becomes 1. If you press 'W', input_dir.y becomes -1.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# APPLY MOVEMENT: We multiply the direction by our speed.
	velocity = input_dir * current_speed
	
	# EXPLANATION: 'move_and_slide' handles collisions so you don't walk through walls.
	move_and_slide()

	# 3. LOOK AT MOUSE: This rotates the player (and the Torch) toward the cursor.
	look_at(get_global_mouse_position())

	# 4. CALL DASH: Check if we are trying to dodge.
	handle_dash()

# 5. THE DODGE LOGIC: Explained below.
func handle_dash():
	# If 'Shift' is pressed and we aren't on cooldown...
	if Input.is_action_just_pressed("dash") and can_dash:
		current_speed = normal_speed * 2.5 # Burst of speed!
		can_dash = false
		
		# Wait 0.2 seconds for the dash to finish
		await get_tree().create_timer(0.2).timeout
		current_speed = normal_speed # Back to walking
		
		# Wait 1.5 seconds before we can dash again (Cooldown)
		await get_tree().create_timer(1.5).timeout
		can_dash = true


@export var light_energy = 100.0
@export var base_drain = 1.0
@onready var torch = $PointLight2D
@onready var monster = get_node("../Monster") # Path to your monster

func _process(delta):
	# 1. Base Drain
	light_energy -= base_drain * delta
	
	# 2. Check if staring at Monster
	var dir_to_monster = (monster.global_position - global_position).normalized()
	var forward_dir = Vector2.RIGHT.rotated(global_rotation)
	var dot_product = forward_dir.dot(dir_to_monster)
	
	# If looking at monster (dot product > 0.8 is roughly a 30-degree cone)
	if dot_product > 0.8:
		light_energy -= (base_drain * 3) * delta
		# Add your "hiss" sound logic here
		
	# 3. Update the visual light scale
	torch.texture_scale = clamp(light_energy / 100.0, 0.0, 1.5)
	
	if light_energy <= 0:
		get_tree().change_scene_to_file("res://GameOver.tscn")
