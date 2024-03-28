extends CharacterBody3D

@export_category("Movement Settings")
@export var gravity: float = -9.8
@export var speed: float = 10.0
@export var accel: float = 30
@export_category("Target Settings")
@export var target: Node3D

var current_speed: float = 1.0
var norm_speed: float = 1.0
var direction = Vector3.ZERO
var lerp_speed = 10.0

@onready var nav: NavigationAgent3D = $NavigationAgent3D

func _process(delta) -> void:
	var distance_to_target = sqrt(pow(target.position.x, 2) + pow(target.position.z, 2))
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var dir = Vector3()
	
	nav.target_position = target.global_position
	
	dir = nav.get_next_path_position() - global_position
	dir = dir.normalized()
	
	if distance_to_target >= 10.0:
		slide(dir, delta)
	else:
		current_speed = norm_speed
	
	look_at(dir)

	velocity = velocity.lerp(dir * current_speed, accel * delta)
	
	move_and_slide()
	
func slide(slide_dir: Vector3, delta: float) -> void:
	print("sliding")
	direction = (transform.basis * Vector3(slide_dir.x, 0, slide_dir.y)).normalized()
	current_speed = lerp(current_speed, current_speed + 1, lerp_speed * delta)
