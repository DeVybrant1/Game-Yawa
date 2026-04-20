extends Control


var button_type = null;
# Called when the node enters the scene tree for the first time.
@onready var level_num_text = $control/HBoxContainer/Label
@onready var  level_num = level_num_text.text.to_int()
@onready var levels_text = $Label


func _ready() -> void:
	pass
	
func _on_home_button_pressed() -> void:
	button_type = "home";
	$Fade_transition.show(); 
	$Fade_transition/Fade_timer.start();
	$Fade_transition/AnimationPlayer.play("fade_in")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


 # Replace with function body.


func _on_select_button_pressed() -> void:
	if (level_num == 0):
		get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
	pass # Replace with function body.
	if (level_num == 1):
		get_tree().change_scene_to_file("res://Scenes/level1.tscn")
	
	if (level_num == 2):
		levels_text.text = "Cannot select this level!"

		

func _on_right_button_pressed() -> void:
	if ( level_num < 2):
		level_num +=1
		level_num_text.text = str(level_num)
	
	if (level_num < 2):
		levels_text.text = "Levels"
		
	if (level_num > 1):
		levels_text.text = "Coming soon!"
		

func _on_left_button_pressed() -> void:
	if (level_num > 0):
			level_num -=1
			level_num_text.text = str(level_num)
	
	if (level_num < 2):
		levels_text.text = "Levels"
		
	if (level_num > 1):
		levels_text.text = "Coming soon!"
		
func _on_fade_timer_timeout() -> void:
	if button_type == "home":
		get_tree().change_scene_to_file("res://Scenes/ui/Main_menu/Main_menu.tscn")
	
