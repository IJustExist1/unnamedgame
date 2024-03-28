extends Area3D
@onready var take = $Take
@onready var evac = $Evac
@onready var music = $Music
var collected: bool = false
var player_in_area: bool = false

signal player_collected

@onready var player = get_tree().get_first_node_in_group("Players")

func _ready():
	player.connect("explosion_cancelled",_on_explosion_cancelled)
	var expldeconctr = get_tree().get_first_node_in_group("ExplosionConnecter")
	if expldeconctr != null:
		expldeconctr.connect("explosion", _on_facility_explode)
	else:
		push_error("World must have an Explosion Connecter")

func _on_explosion_cancelled():
	music.stop()
	evac.stop()
	take.stop()

func _on_facility_explode() -> void:
	music.stop()
	evac.stop()
	take.stop()

func _process(delta):
	if player_in_area :
		if player.interact_open == false:
			player.show_interact()
		if Input.is_action_just_pressed("interact"):
			collected = true
			$core.hide()
			player_collected.emit()

			var lights = get_tree().get_nodes_in_group("Lights")
			for light: Light3D in lights:
				light.light_energy = lerp(light.light_energy, 1.0, delta)

			take.play()
			music.play()
			await take.finished
			evac.play()
	else:
		player.hide_interact()

func _on_body_entered(body):
	if body.is_in_group("Players") and collected == false:
		player_in_area = true

func _on_body_exited(body):
	if body.is_in_group("Players"):
		player_in_area = false
