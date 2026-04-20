## fireball.gd
## HOW TO CREATE THE FIREBALL SCENE:
##   1. Scene → New Scene → root type: Area2D → rename root to "Fireball"
##   2. Add child: AnimatedSprite2D
##        - Create a new SpriteFrames resource
##        - Add animation "fly" with frames from res://sprites/fb-sprite.png
##          (it's a spritesheet: set the Hframes to match the frame count)
##        - Set Autoplay to "fly"
##   3. Add child: CollisionShape2D → CircleShape2D, radius 7
##   4. On the root Area2D:
##        collision_layer = 4   (HitBox layer)
##        collision_mask  = 8   (Player HurtBox layer)
##   5. Attach this script to the root Area2D
##   6. Save as res://Scenes/fireball.tscn
##   7. Back in the boss's Inspector, assign it to "Fireball Scene"

extends Area2D

@export var speed: float    = 240.0
@export var damage: int     = 1
@export var lifetime: float = 5.0

## Set by the boss right after instantiation
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Rotate sprite to face travel direction
	rotation = direction.angle()

	# Connect hit signals
	area_entered.connect(_on_hit_area)
	body_entered.connect(_on_hit_body)

	# Auto-destroy so stray fireballs don't linger forever
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

## Called by the boss to set the travel direction after instantiation.
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation  = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_hit_area(area: Area2D) -> void:
	# Hit the player's hurtbox
	if area is HurtBox:
		# Don't damage the boss's own hurtbox
		if area.get_parent() == get_parent():
			return
		if area.health != null:
			area.health.take_damage(damage)
		queue_free()

func _on_hit_body(body: Node2D) -> void:
	# Hit a wall / static body / tilemap
	if body is StaticBody2D or body is TileMapLayer or body is TileMap:
		queue_free()
