extends VideoStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicPlayer.stop();
 # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_finished() -> void:
	get_tree().change_scene_to_file("res://Scenes/level1.tscn") # Replace with function body.
