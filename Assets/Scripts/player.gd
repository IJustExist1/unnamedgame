extends CharacterBody3D

@export_category("FOV Stuff")
@export var norm_fov: int = 75
@export var run_fov: int = 100
@export var slide_fov: int = 150
@export var air_fov: int = 125

@onready var parent = $".."
@onready var player = $"."
@onready var head = $Neck/Head
@onready var neck = $Neck
@onready var eyes = $Neck/Head/Eyes
@onready var cam = $Neck/Head/Eyes/Cam
@onready var standing_collision = $standing_collision
@onready var crouching_collision = $crouching_collision
@onready var raycats_meow = $NoUnCrouchingUnderStuffAnymoreThingyMajig
@onready var cam_anims = $Neck/Head/Eyes/CamAnims
@onready var footsteps = $Sounds/Footsteps
@onready var death = $CanvasLayer/Control/Death
@onready var interact = $CanvasLayer/Control/Interact
@onready var end = $CanvasLayer/Control/End
@onready var slide_particles = $Neck/Head/Eyes/Cam/SlideParticles
@onready var slide_cooldown = $slide_cooldown
@onready var recharge = $Recharge


#Other Stuff
var direction = Vector3.ZERO
var current_speed: float = 1.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var lerp_speed = 10.0
var cam_lerp_speed_run = 1.25
var cam_lerp_speed_slide = 2.0
var air_lerp_speed = 2.0
var crouching_depth = 0.0
var free_look_tilt_amount: float = 8

#Velocity Vars
const walking_speed: float = 9.0
const sprinting_speed: float = 16.5
const sliding_speed: float = 18.5
const jump_velocity: float = 5.5
const sensitivity: float = 0.15

#State Vars
var walking: bool = false
var sprinting: bool = false
var crouching: bool = false
var freelooking: bool = false
var sliding: bool = false
var flipping: bool = false
var dead: bool = false
var interact_open: bool = false
var can_slide: bool = true
var was_sliding: bool = false
var slide_filling: bool = false

#Slide Timers and Dirs
var sliding_timer: float = 0.0
var sliding_timer_max: float = 1.0
var slide_dir = Vector2.ZERO

#Some fuckin head bobbing stuff
const head_bobbing_sprinting_speed: float = 22.0
const head_bobbing_walking_speed: float = 14.0
const head_bobbing_explosion_speed: float = 100.0
const head_bobbing_sprinting_intensity: float = 0.2
const head_bobbing_walking_intensity: float = 0.1
const head_bobbing_explosion_intensity: float = 0.55
var head_bobbing_vector: Vector2 = Vector2.ZERO
var head_bobbing_index: float = 0.0
var head_bobbing_current_intensity: float = 0.0

#Last Vel
var last_velocity = Vector3.ZERO

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	if cam.current == true:
		$Neck/vmachine.visible = false
	else:
		$Neck/Head/pistol.hide()
	#doesnt run unless player has authority to
	if not is_multiplayer_authority(): return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.current = true
	end.hide()
	cam.fov = norm_fov
	
	#Sets up the discord API
	DiscordSDK.app_id = 1222333673924464711
	DiscordSDK.run_callbacks()
	print("Discord working: " + str(DiscordSDK.get_is_discord_working()))
	DiscordSDK.details = "Multiplayer semi-functional"
	DiscordSDK.state = "Zoomin'"
	DiscordSDK.large_image = "astolfolouisthe14th"
	DiscordSDK.large_image_text = "Louis the 14th was a femboy!?"
	
	DiscordSDK.refresh()
	
#Shows and hides the interact menu
func show_interact() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(interact, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	interact_open = true

func hide_interact() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(interact, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.25)
	interact_open = false

#Does some camera stuff
func _input(event) -> void:
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		if freelooking:
			neck.rotate_y(deg_to_rad(-event.relative.x * sensitivity))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		
		if !flipping:
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


#Kills player
func kill() -> void:
	dead = true
	death.show()
	$CanvasLayer/Control/Death/AnimationPlayer.play("text_appear")
	$Voice.stream = load("res://Assets/Voicelines/Death/death.wav")
	$Voice.playing = true
	await $Voice.finished
	$Voice.stream = null

func _on_slide_cooldown_timeout():
	can_slide = true
	slide_filling = false
	recharge.play()

#TODO: Clean up this method
#The pile of shit that is this method
func _physics_process(delta) -> void:
	if not is_multiplayer_authority(): return
	#Gets the vectors for our input_dir
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	if slide_filling:
		$CanvasLayer/Control/Slide/ProgressBar.value = (((slide_cooldown.time_left / slide_cooldown.wait_time) * 100) - 100) * -1
	
	#Dead
	if dead:
		input_dir = Vector2.ZERO
	
	#Changes FOV based on what player is doing
	if sprinting and !sliding and input_dir != Vector2.ZERO:
		cam.fov = lerp(float(cam.fov), float(run_fov), delta * cam_lerp_speed_run)
	elif sliding:
		#self.floor_snap_length = 0.0
		cam.fov = lerp(float(cam.fov), float(slide_fov), delta * cam_lerp_speed_slide)
	else:
		#self.floor_snap_length = 0.1
		cam.fov = lerp(float(cam.fov), float(norm_fov), delta * lerp_speed)
	
	#Makes wind particles appear even when not sliding but only in DIFFICULTY.TRAM difficulty
	var world = get_tree().get_first_node_in_group("World")
	if sliding || world.difficulty == Globals.DIFFCULTY.TRAM:
		slide_particles.amount_ratio = lerp(slide_particles.amount_ratio, 1.0, delta * air_lerp_speed)
		cam.fov = lerp(float(cam.fov), float(slide_fov), delta * cam_lerp_speed_slide)
	else:
		slide_particles.amount_ratio = lerp(slide_particles.amount_ratio, 0.0, delta * lerp_speed)
		
	#TODO: get footsteps working correctly
	if sprinting and crouching == false and sliding == false and is_on_floor():
		footsteps.play()
	else:
		footsteps.stop()
	
	#Slides
	if Input.is_action_pressed("crouch") and is_on_floor() and can_slide:
		head.position.y = lerp(head.position.y, crouching_depth - 1, lerp_speed * delta)
		standing_collision.disabled = true
		crouching_collision.disabled = false
		#makes sure we can slide
		if input_dir != Vector2.ZERO && sliding == false and crouching == false and is_on_floor(): 
			sliding = true
			slide_dir = input_dir
		#if we arent holding any movement keys down we will always slide forward
		elif input_dir == Vector2.ZERO && sliding == false and crouching == false and is_on_floor():
			sliding = true
			slide_dir = Vector2(0, -1)
			
	#TODO: fix this
	#raycats neow :333
	elif !raycats_meow.is_colliding():
		head.position.y = lerp(head.position.y, crouching_depth, lerp_speed * delta)
		current_speed = lerp(current_speed, walking_speed, lerp_speed * delta)
		standing_collision.disabled = false
		crouching_collision.disabled = true
		walking = true
		sprinting = false
		crouching = false
		if Input.is_action_pressed("sprint"):
			current_speed = lerp(current_speed, sprinting_speed, lerp_speed * delta)
			walking = false
			sprinting = true
			crouching = false
		else:
			current_speed = lerp(current_speed, walking_speed, lerp_speed * delta)
			walking = true
			sprinting = false
			crouching = false
	
	if Input.is_action_just_released("crouch") && sliding == true:
		slide_cooldown.start()
		can_slide = false
		head.position.y = lerp(head.position.y, crouching_depth + 1, lerp_speed * delta)
		standing_collision.disabled = false
		crouching_collision.disabled = true
		sliding = false
		slide_filling = true
		
	#Freelook
	if Input.is_action_pressed("freelook") || sliding:
		freelooking = true
		eyes.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else:
		freelooking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, lerp_speed * delta)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, lerp_speed * delta)
	
	# makes the players camera wave based on what state they are in
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta

	if is_on_floor() && sliding == false && input_dir != Vector2.ZERO && velocity != Vector3.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index / 2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity / 2.0), lerp_speed * delta)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * head_bobbing_current_intensity, lerp_speed * delta)
	else:
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * 0.0, lerp_speed * delta)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * 0.0, lerp_speed * delta)
		
	if !is_on_floor():
		flipping = true
	else:
		flipping = false
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		if sliding:
			cam.fov = lerp(float(cam.fov), float(air_fov), delta * air_lerp_speed)

	# applies fucking GRAVITY to the player in a kind and respectful matter by forcibly dragging the player to the ground
	if Input.is_action_just_pressed("jump") and is_on_floor() and dead == false and !sliding:
		cam_anims.play("jump")
		velocity.y = jump_velocity

	#Makes the camera animate based on the players last velocity
	if is_on_floor():
		cam.fov = lerp(float(cam.fov), float(norm_fov), delta * air_lerp_speed  )
		if last_velocity.y < 0.0:
			cam_anims.play("landing")
		if last_velocity.y < -15.0:
			cam_anims.play("hard_landing")

	#Gets the direction for walking / running in
	if is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), lerp_speed * delta)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), air_lerp_speed * delta)
	
	#Sliding
	if sliding:
		direction = (transform.basis * Vector3(slide_dir.x, 0, slide_dir.y)).normalized()
		current_speed = lerp(current_speed, current_speed + 1, lerp_speed * delta)

	#Walks
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	#UnWalks
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
	last_velocity = velocity
	was_sliding = sliding
	
	move_and_slide()
