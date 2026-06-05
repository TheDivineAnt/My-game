extends Control

@export_file("*.tscn") var first_level_scene: String

# Grabs your PointLight2D node
@onready var menu_flashlight = $MenuFlashlight

func _ready() -> void:
	# Automatically highlights the PlayButton so keyboard/controller inputs work
	var play_button = find_child("PlayButton", true, false)
	if play_button:
		play_button.grab_focus()

func _process(_delta: float) -> void:
	# Snaps the PointLight2D directly to the mouse cursor's exact position
	if menu_flashlight:
		menu_flashlight.position = get_local_mouse_position()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Map.tscn")


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")
