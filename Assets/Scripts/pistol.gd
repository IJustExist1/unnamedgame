extends Node3D

@onready var anims = $Anims
@onready var shot = $shot
var can_shoot: bool = true

@rpc("call_local")
func _process(_delta):
	if Input.is_action_just_pressed("shoot") and can_shoot:
		if not is_multiplayer_authority(): return
		anims.stop()
		anims.play("shoot")
		shot.play()
		can_shoot = false
		
		var cooldown_timer = get_tree().create_timer(0.35)
		cooldown_timer.connect("timeout", _on_cooldown_timeout)

func _on_cooldown_timeout():
	can_shoot = true
