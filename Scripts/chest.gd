extends Node2D

@onready var area_2d: Area2D = $Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player_inside := false
var is_open := false
var player: Player = null   # store player reference


func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	print("Chest ready")


func _process(_delta: float) -> void:
	if player_inside and not is_open and Input.is_action_just_pressed("interact"):
		
		if player == null:
			return
		
		var health: Health = player.health
		
		# ✅ ONLY open if player is NOT at full health
		if health.health < health.max_health:
			health.heal(1)
			
			is_open = true
			animation_player.stop()
			animated_sprite_2d.play("open")
			
			print("Opened! +1 HP")
		else:
			print("HP full → chest does nothing")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = true
		player = body   # ✅ store the player
		
		if not is_open:
			animation_player.play("hover")
			print("Hover playing")


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = false
		player = null
		
		if not is_open:
			animation_player.stop()
