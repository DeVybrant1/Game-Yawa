class_name Player
extends CharacterBody2D

# --- Movement ---
var move_speed: float = 100.0
var attack_speed_multiplier: float = 0.4
var dash_speed: float = 400.0
var dash_duration: float = 0.15
var dash_cooldown_time: float = 0.3
var dash_global_cooldown: float = 0.3

var direction: Vector2 = Vector2.ZERO
var lastdir: String = "d"

# --- Attack ---
var attacking: bool = false
var attacknum: int = 1
var attack_dir: String = "d"

# --- Dash ---
var dashing: bool = false
var dash_dir: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var dash_ready: bool = true

var last_press_time = {
	"up": 0.0,
	"down": 0.0,
	"left": 0.0,
	"right": 0.0
}
var dash_timer_global: float = 0.0

# --- Nodes ---
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: Health = $health
@onready var health_bar: TextureProgressBar = $CanvasLayer/Healthbar_main



func _ready() -> void:
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	health_bar.max_value = health.max_health
	health_bar.value = health.max_health

	animated_sprite_2d.animation_changed.connect(_on_animated_sprite_2d_animation_changed)

	# Create the flash shader material
	var shader = Shader.new()
	shader.code = "
		shader_type canvas_item;
		uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
		void fragment() {
			vec4 col = texture(TEXTURE, UV);
			col.rgb = mix(col.rgb, vec3(1.0), flash_amount * col.a);
			COLOR = col;
		}
	"
	var mat = ShaderMaterial.new()
	mat.shader = shader
	animated_sprite_2d.material = mat

func _process(_delta: float) -> void:
	dash_timer_global += _delta

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
		attack_dir = lastdir
		animated_sprite_2d.play("attack" + str(attacknum) + "_" + attack_dir)
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
	if dashing:
		velocity = dash_dir * dash_speed
		dash_timer -= _delta
		if dash_timer <= 0:
			dashing = false
			dash_ready = false
			await get_tree().create_timer(dash_global_cooldown).timeout
			dash_ready = true
	elif attacking:
		velocity = direction * move_speed * attack_speed_multiplier
	else:
		velocity = direction * move_speed

	move_and_slide()


# --- Dash helpers ---
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


# --- Animation finished ---
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation.begins_with("attack"):
		attacking = false

# --- Animation changed (catches interrupted attacks) ---
func _on_animated_sprite_2d_animation_changed() -> void:
	if attacking and not animated_sprite_2d.animation.begins_with("attack"):
		attacking = false


func _on_died() -> void:
	set_physics_process(false)
	set_process(false)

	var tween = create_tween()
	tween.tween_method(_set_white_flash, 0.0, 1.0, 0.1)
	tween.tween_method(_set_white_flash, 1.0, 0.0, 0.1)
	tween.tween_method(_set_white_flash, 0.0, 1.0, 0.1)
	tween.tween_method(_set_white_flash, 1.0, 0.0, 0.1)
	tween.tween_method(_set_white_flash, 0.0, 1.0, 0.1)
	await tween.finished

	get_tree().reload_current_scene()


func _set_white_flash(amount: float) -> void:
	animated_sprite_2d.material.set_shader_parameter("flash_amount", amount)

func _on_health_changed(new_health: int, max_health: int) -> void:
	health_bar.value = new_health
	print("Player HP: %d / %d" % [new_health, max_health])
