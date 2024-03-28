extends Control

func _process(_delta):
	if !$AudioStreamPlayer.is_playing():
		get_tree().change_scene_to_file("res://Assets/Worlds/main_menu.tscn")
