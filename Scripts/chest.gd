extends Node2D

@onready var area_2d: Area2D = $Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player_inside := false
var is_open := false

func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	print("Script ready - Area2D connected")

func _process(_delta: float) -> void:
	if player_inside and not is_open and Input.is_action_just_pressed("interact"):
		is_open = true
		animation_player.stop()
		animated_sprite_2d.play("open")
		print("Opened!")
	
			
			
func _on_body_entered(body: Node2D) -> void:
	print("Body entered: ", body.name)
	if body.name == "Player":  # change "Player" to whatever your player node is named
		player_inside = true
		if not is_open:
			animation_player.play("hover")
			print("Hover playing")

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":  # same name here
		player_inside = false
		if not is_open:
			animation_player.stop()
