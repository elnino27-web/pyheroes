extends Node

var click_sound = preload("res://assets/Sound/click.wav")
var audio_player: AudioStreamPlayer

func _ready():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

func play_click():
	audio_player.stream = click_sound
	audio_player.play()
