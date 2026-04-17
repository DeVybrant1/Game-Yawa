class_name Player
extends CharacterBody2D

# --- Movement ---
var move_speed: float = 100.0
var attack_speed_multiplier: float = 0.4  # slower movement while attacking
var dash_speed: float = 400.0
var dash_duration: float = 0.15
var dash_cooldown_time: float = 0.3 # double-tap max interval to trigger dash
var dash_global_cooldown: float = 0.3  # cooldown after dash ends

var direction: Vector2 = Vector2.ZERO
var lastdir: String = "d"

# --- Attack ---
var attacking: bool = false
var attacknum: int = 1  # toggle between 1 and 2

# --- Dash ---
var dashing: bool = false
var dash_dir: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var dash_ready: bool = true  # prevents dashing during cooldown

var last_press_time = {
	"up": 0.0,
	"down": 0.0,
	"left": 0.0,
	"right": 0.0
}
var dash_timer_global: float = 0.0  # delta-based timer

# --- Nodes ---
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
		# Assign hurtbox owner
	pass


func _process(_delta: float) -> void:
	# Increment global timer
	dash_timer_global += _delta

	# Skip normal input during dash
	if dashing:
		return

	# --- Movement input ---
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_dir.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = input_dir.normalized()

	# --- Double-tap dash detection ---
	if dash_ready:
		_check_dash("up", Vector2.UP)
		_check_dash("down", Vector2.DOWN)
		_check_dash("left", Vector2.LEFT)
		_check_dash("right", Vector2.RIGHT)

	# --- Attack input ---
	if Input.is_action_just_pressed("attack_1") and not attacking:
		attacking = true
		animated_sprite_2d.play("attack" + str(attacknum) + "_" + lastdir)
		attacknum = 2 if attacknum == 1 else 1

	# --- Animation ---
	if not attacking:
		if direction == Vector2.ZERO:
			animated_sprite_2d.play("idle_" + lastdir)
		else:
			if abs(direction.x) > 0:
				lastdir = "r" if direction.x > 0 else "l"
			elif abs(direction.y) > 0:
				lastdir = "d" if direction.y > 0 else "u"
			animated_sprite_2d.play("run_" + lastdir)


func _physics_process(_delta: float) -> void:
	# --- Dash logic ---
	if dashing:
		velocity = dash_dir * dash_speed
		dash_timer -= _delta
		if dash_timer <= 0:
			dashing = false
			dash_ready = false  # start cooldown after dash ends
			# Use await instead of yield
			await get_tree().create_timer(dash_global_cooldown).timeout
			dash_ready = true
	elif attacking:
		velocity = direction * move_speed * attack_speed_multiplier
	else:
		velocity = direction * move_speed

	move_and_slide()


# --- Dash helper ---
func _check_dash(key_name: String, vec: Vector2) -> void:
	if Input.is_action_just_pressed(key_name):
		var time_now = dash_timer_global
		if time_now - last_press_time[key_name] <= dash_cooldown_time:
			_start_dash(vec)
		last_press_time[key_name] = time_now


func _start_dash(vec: Vector2) -> void:
	dashing = true
	dash_dir = vec
	dash_timer = dash_duration
	animated_sprite_2d.play("run_" + lastdir)


# --- Animation finished callback ---
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation.begins_with("attack"):
		attacking = false
