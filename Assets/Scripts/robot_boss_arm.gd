extends Node3D
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
#
#func _ready():
	#self.hide()
	#var core = get_tree().get_first_node_in_group("Cores")
	#if core != null:
		#core.connect("player_collected", _on_player_collected)
#
#func _on_player_collected():
	#animation_player.play("Armature_001")
	#self.show()
	#await animation_player.animation_finished
	#self.hide()
