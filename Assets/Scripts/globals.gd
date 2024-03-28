extends Node

enum DIFFCULTY {EASY, NORMAL, HARD, INSANE, TRAM, DEBUG}
@export var difficulty: DIFFCULTY = DIFFCULTY.NORMAL

var is_multiplayer: bool = false
