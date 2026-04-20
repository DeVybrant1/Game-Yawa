# fireball.gd - Attach to the "fireball" (boil) Node2D scene
extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: HitBox = $HitBox


@export var speed: float = 200.0
@export var damage: int = 1
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var hit: bool = false
var life_timer: float = 0.0

func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.area_entered.connect(_on_area_entered)
	animated_sprite_2d.play("flying")
	# Set collision to hit player layer (layer 2 = mask bit 2)
	area_2d.collision_layer = 8
	area_2d.collision_mask = 2

func _process(delta: float) -> void:
	if hit:
		return
	life_timer += delta
	if life_timer >= lifetime:
		queue_free()
		return
	position += direction * speed * delta

func _do_hit() -> void:
	if hit:
		return
	hit = true
	set_process(false)
	animated_sprite_2d.play("impact")
	await animated_sprite_2d.animation_finished
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if hit:
		return
	if body.is_in_group("player"):
		if body.has_node("health"):
			body.get_node("health").take_damage(damage)
	_do_hit()

func _on_area_entered(area: Area2D) -> void:
	if hit:
		return
	# Hit player hurtbox
	if area.is_in_group("player_hurtbox"):
		if area.get_parent().has_node("health"):
			area.get_parent().get_node("health").take_damage(damage)
		_do_hit()
