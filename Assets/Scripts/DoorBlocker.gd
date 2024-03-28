extends Node3D
@onready var show_on_collect = get_tree().get_first_node_in_group("ShowCollect")
@onready var static_body_3d = $"../ShowWhenCollected/StaticBody3D"

func _ready():
	for i in show_on_collect.get_children():
		for x in static_body_3d.get_children():
			x.disabled = true
		i.hide()

func show_collect():
	for i in show_on_collect.get_children():
		for x in static_body_3d.get_children():
			x.disabled = false
		i.show()
