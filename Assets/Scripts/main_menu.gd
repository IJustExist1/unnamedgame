extends Control

func _ready():
	$".".show()

func _on_tutorial_pressed():
	Globals.is_multiplayer = false
	get_tree().change_scene_to_file("res://Assets/Worlds/debug_world.tscn")


func _on_quit_pressed():
	get_tree().quit()


func _on_multiplayer_pressed():
	Globals.is_multiplayer = true
	get_tree().change_scene_to_file("res://Assets/Worlds/debug_world.tscn")
