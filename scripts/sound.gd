extends Node
var volume = 0.65
var music: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var cursor = 0

func _ready():
	music = AudioStreamPlayer.new()
	add_child(music)
	for i in range(10):
		var p = AudioStreamPlayer.new()
		add_child(p)
		effects.append(p)
	set_volume(volume)

func set_volume(value: float):
	volume = value
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001,value)))

func song(index: int):
	music.stop()
	music.stream = load("res://assets/audio/music_%d.wav" % (index+1))
	music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream.loop_begin = 0
	music.stream.loop_end = int(music.stream.get_length()*music.stream.mix_rate)
	music.volume_db = -4
	music.play()

func play_sfx(id: String):
	var p = effects[cursor]
	cursor = (cursor+1)%effects.size()
	p.stream = load("res://assets/audio/%s.wav" % id)
	p.play()

func release_audio():
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for p in effects:
		if is_instance_valid(p):
			p.stop()
			p.stream = null

func _exit_tree():
	release_audio()
