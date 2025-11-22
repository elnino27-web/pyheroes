extends Node

# ================================
# 1. PRELOAD FILE SUARA
# ================================
# Pastikan nama file di folder "res://assets/Sound/" sesuai dengan yang kamu punya
var click_sound  = preload("res://assets/Sound/click.wav")
var jalan_sound  = preload("res://assets/Sound/walk.wav") 
var nabrak_sound = preload("res://assets/Sound/hit.wav")
var menang_sound = preload("res://assets/Sound/win.wav")

# ================================
# 2. AUDIO PLAYER
# ================================
var ui_player: AudioStreamPlayer   # Khusus suara UI (Klik)
var sfx_player: AudioStreamPlayer  # Khusus suara Game (Jalan, Nabrak, Menang)

func _ready():
	# Kita buat 2 player supaya suara klik dan jalan bisa bunyi bersamaan
	
	# A. Setup Player UI
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "Master" # Bisa diganti bus lain jika ada
	add_child(ui_player)
	
	# B. Setup Player SFX
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)

# ================================
# 3. FUNGSI PEMANGGIL
# ================================

func play_click():
	if click_sound:
		ui_player.stream = click_sound
		ui_player.pitch_scale = 1.0
		ui_player.play()

func play_jalan():
	if jalan_sound:
		sfx_player.pitch_scale = randf_range(0.9, 1.1)
		sfx_player.stream = jalan_sound
		sfx_player.play()

func play_nabrak():
	if nabrak_sound:
		sfx_player.pitch_scale = 1.0
		sfx_player.stream = nabrak_sound
		sfx_player.play()

func play_menang():
	if menang_sound:
		sfx_player.pitch_scale = 1.0
		sfx_player.stream = menang_sound
		sfx_player.play()
