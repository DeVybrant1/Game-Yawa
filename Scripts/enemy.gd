class_name Enemy
extends CharacterBody2D

# =====================
# CONFIG
# =====================
@export var move_speed: float = 70.0
@export var attack_range: float = 25.0
@export var attack_cooldown: float = 1.0

# =====================
# STATE
# =====================
var player: Node2D = null
var player_in_aggro: bool = false

var attacking: bool = false
var can_attack: bool = true

# =====================
# DIRECTION (NSEW)
# =====================
var dir: Vector2 = Vector2.ZERO
var facing: String = "s"

# =====================
# NODES
# =====================
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


# =====================
# INIT
# =====================
func _ready():
	player = get_tree().get_first_node_in_group("player")


# =====================
# MAIN LOOP
# =====================
func _physics_process(delta):

	# --- NO AGGRO = IDLE ---
	if not player_in_aggro or player == null:
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	# --- PATHFINDING ---
	nav.target_position = player.global_position
	var next_pos = nav.get_next_path_position()

	dir = (next_pos - global_position).normalized()

	var dist = global_position.distance_to(player.global_position)

	# --- ATTACK ---
	if dist <= attack_range:
		velocity = Vector2.ZERO
		_try_attack()
	else:
		velocity = dir * move_speed
		_update_facing()
		_play_run()

	move_and_slide()


# =====================
# ATTACK
# =====================
func _try_attack():
	if not can_attack or attacking:
		return

	attacking = true
	can_attack = false

	_update_facing()
	anim.play("attack_" + facing)

	await anim.animation_finished

	attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


# =====================
# DIRECTION SYSTEM (NSEW)
# =====================
func _update_facing():
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			facing = "E"
		else:
			facing = "W"
	else:
		if dir.y > 0:
			facing = "S"
		else:
			facing = "N"


# =====================
# ANIMATIONS
# =====================
func _play_idle():
	anim.play("idle_" + facing)

func _play_run():
	if not attacking:
		anim.play("run_" + facing)


# =====================
# AGGRO CONTROL (FROM PLAYER RAYTRACE)
# =====================
func set_aggro(state: bool):
	player_in_aggro = state
