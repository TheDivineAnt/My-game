extends Control

@onready var menu_flashlight = $MenuFlashlight

func _ready() -> void:
	# 1. FIX THE NULL INSTANCE ERROR FOR SUB-MENUS:
	# Automatically focus on the first interactive button in this scene 
	# (like your "Back" button) so controller/keyboard works instantly.
	var back_button = find_child("BackButton", true, false)
	if back_button:
		back_button.grab_focus()

func _process(_delta: float) -> void:
	# 2. Track the mouse with our lamp texture
	if menu_flashlight:
		menu_flashlight.position = get_local_mouse_position()




func _on_go_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
