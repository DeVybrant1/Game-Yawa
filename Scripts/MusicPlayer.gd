extends AudioStreamPlayer

func play_music(music_stream: AudioStream):
	if stream == music_stream:
		return # Don't restart if it's already playing the same song
	stream = music_stream
	play()
