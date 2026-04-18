extends Control


var button_type = null;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Fade_transition/AnimationPlayer.play("fade_out") 
	pass # Replace with function body.
	
func _on_home_button_pressed() -> void:
	button_type = "home";
	$Fade_transition.show(); 
	$Fade_transition/Fade_timer.start();
	$Fade_transition/AnimationPlayer.play("fade_in")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



 # Replace with function body.



func _on_fade_timer_timeout() -> void:
	if button_type == "home":
		get_tree().change_scene_to_file("res://Scenes/ui/Main_menu/Main_menu.tscn")
		# Replace with function body.



func _on_select_button_pressed() -> void:
	pass # Replace with function body.


func _on_right_button_pressed() -> void:
	pass # Replace with function body.


func _on_left_button_pressed() -> void:
	pass # Replace with function body.




	
