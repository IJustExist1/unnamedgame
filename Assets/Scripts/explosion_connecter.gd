extends Node3D
signal explosion

func _ready():
	var plyr = get_tree().get_first_node_in_group("Players")
	if plyr != null:
		plyr.connect("facility_explode", _on_facility_explode)
	else:
		push_error("Player connot be non existent")

func _on_facility_explode() -> void:
	$Explosion.play()
	explosion.emit()
