extends CharacterBody2D

# ---------------------------------------------------
# MOVEMENT / AI
# ---------------------------------------------------
var movement_speed: float = 50.0
@export var target: Node2D = null
@export var stop_distance := 25.0

var player_in_range := false
var attacking := false

# ---------------------------------------------------
# HEALTH
# ---------------------------------------------------
var max_health: int = 5
var health: int = 5

# ---------------------------------------------------
# DIRECTION
# ---------------------------------------------------
var last_direction := "S"

# ---------------------------------------------------
# NODES
# ---------------------------------------------------
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection: Area2D = $detection

@onready var hit_s: Area2D = $Node/hit_S
@onready var hit_e: Area2D = $Node/hit_E
@onready var hit_w: Area2D = $Node/hit_W
@onready var hit_n: Area2D = $Node/hit_N

var hitboxes := {}

# ---------------------------------------------------
# READY
# ---------------------------------------------------
func _ready() -> void:
	hitboxes = {
		"N": hit_n,
		"S": hit_s,
		"E": hit_e,
		"W": hit_w
	}

	_disable_all_hitboxes()

	# detection
	detection.body_entered.connect(_on_detection_body_entered)
	detection.body_exited.connect(_on_detection_body_exited)

	# connect hitboxes (enemy deals damage)
	for box in hitboxes.values():
		box.area_entered.connect(_on_hitbox_area_entered)

	call_deferred("seeker_setup")

# ---------------------------------------------------
# INIT NAV
# ---------------------------------------------------
func seeker_setup():
	await get_tree().physics_frame
	if target:
		navigation_agent.target_position = target.global_position

# ---------------------------------------------------
# PHYSICS LOOP
# ---------------------------------------------------
func _physics_process(delta: float) -> void:
	if not player_in_range:
		velocity = Vector2.ZERO
		move_and_slide()
		play_animation("idle")
		return

	if target:
		navigation_agent.target_position = target.global_position

	var distance_to_target = global_position.distance_to(target.global_position)

	# ---------------------------------------------------
	# ATTACK
	# ---------------------------------------------------
	if distance_to_target <= stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()

		if not attacking:
			attack()
		return

	# ---------------------------------------------------
	# MOVE
	# ---------------------------------------------------
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		play_animation("idle")
		return

	var next_pos = navigation_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()

	velocity = dir * movement_speed
	move_and_slide()

	update_direction(dir)
	play_animation("run")

# ---------------------------------------------------
# ATTACK
# ---------------------------------------------------
func attack():
	attacking = true
	play_animation("attack")

	_update_hitboxes()

	await get_tree().create_timer(0.4).timeout

	_disable_all_hitboxes()
	attacking = false

# ---------------------------------------------------
# HITBOX SYSTEM (ENEMY DEALS DAMAGE)
# ---------------------------------------------------
func _update_hitboxes() -> void:
	_disable_all_hitboxes()

	var active = hitboxes.get(last_direction, null)
	if active:
		active.monitoring = true


func _disable_all_hitboxes() -> void:
	for box in hitboxes.values():
		box.monitoring = false

# ---------------------------------------------------
# DIRECTION
# ---------------------------------------------------
func update_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		last_direction = "E" if dir.x > 0 else "W"
	else:
		last_direction = "S" if dir.y > 0 else "N"

# ---------------------------------------------------
# ANIMATION
# ---------------------------------------------------
func play_animation(state: String):
	var anim_name = state + "_" + last_direction
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

# ---------------------------------------------------
# DETECTION
# ---------------------------------------------------
func _on_detection_body_entered(body):
	if body == target:
		player_in_range = true

func _on_detection_body_exited(body):
	if body == target:
		player_in_range = false

# ---------------------------------------------------
# DAMAGE RECEIVED (PLAYER HITS ENEMY)
# ---------------------------------------------------
func take_damage(amount: int) -> void:
	health -= amount
	print("Enemy Health:", health)

	if health <= 0:
		print("Enemy died!")
		queue_free()

# ---------------------------------------------------
# HITBOX CONTACT (ENEMY DAMAGES PLAYER)
# ---------------------------------------------------
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		if area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(1)
