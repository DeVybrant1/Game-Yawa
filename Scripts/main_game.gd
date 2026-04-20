extends Node2D

func _ready() -> void:
	add_to_group("main_game")
	$Fade_transition/AnimationPlayer.play("fade_out")
	MusicPlayer.volume_db = -10

func _process(_delta: float) -> void:
	pass

# Called by enemies when they die - routes baraka to the player
func add_baraka(amount: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_baraka"):
		player.add_baraka(amount)
