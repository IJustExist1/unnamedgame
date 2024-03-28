extends Node
@export var difficulty: Globals.DIFFCULTY = Globals.DIFFCULTY.NORMAL
@export var is_exploding: bool = false

@export var worldenv: WorldEnvironment
@export var yoinked_env: Environment

@export var has_doors_blocked: bool = false

@onready var main_menu = $Multiplayer
@onready var address_entry = $Multiplayer/MainMenu/MarginContainer/VBoxContainer/Address

const Player = preload("res://assets/entities/player.tscn")

const PORT = 3298
var enet_peer = ENetMultiplayerPeer.new()

var using_upnp: bool = false

func _ready():
	main_menu.hide()
	if Globals.is_multiplayer:
		main_menu.show()
	else:
		main_menu.hide()
		add_player(multiplayer.get_unique_id())
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
func _on_use_upn_p_toggled(toggled_on):
	using_upnp = toggled_on

func _on_host_pressed():
	main_menu.hide()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	if using_upnp:
		upnp_setup()

func _on_join_pressed():
	main_menu.hide()
	
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Assets/Worlds/main_menu.tscn")
