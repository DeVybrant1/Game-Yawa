extends Control


var button_type = null;
# Called when the node enters the scene tree for the first time.


func _ready() -> void:
	MusicPlayer.play_music(preload("res://Audio/Amani_music.mp3"))

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_options_pressed() -> void:
	button_type = "levels"
	$Fade_transition.show(); 
	$Fade_transition/Fade_timer.start();
	$Fade_transition/AnimationPlayer.play("fade_in")


 # Replace with function body.


func _on_play_pressed() -> void:
	button_type = "play";
	$Fade_transition.show(); 
	$Fade_transition/Fade_timer.start();
	$Fade_transition/AnimationPlayer.play("fade_in")

func _on_restart_pressed() -> void:
	pass # Replace with function body.
	
	


func _on_fade_timer_timeout() -> void:
	if button_type == "play":
		get_tree().change_scene_to_file("res://introcutscene.tscn")# Replace with function body.
	
	if button_type == "levels":
		get_tree().change_scene_to_file("res://Scenes/ui/Main_menu/level_menu.tscn")
		# Replace with function body.
