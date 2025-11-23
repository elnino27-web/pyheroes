extends Node

# ================================
# 1. PRELOAD FILE SUARA
# ================================
var click_sound  = preload("res://assets/Sound/click.wav")
var jalan_sound  = preload("res://assets/Sound/walk.wav") 
var nabrak_sound = preload("res://assets/Sound/hit.wav")
var menang_sound = preload("res://assets/Sound/win.wav")

# ================================
# 2. AUDIO PLAYER
# ================================
var ui_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var walk_player: AudioStreamPlayer 

func _ready():
	# Kita buat 3 player terpisah agar suara tidak saling memotong
	ui_player = AudioStreamPlayer.new()
	add_child(ui_player)
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	walk_player = AudioStreamPlayer.new()
	add_child(walk_player)

# ================================
# 3. FUNGSI PEMANGGIL
# ================================

func play_click():
	if click_sound:
		ui_player.stream = click_sound
		ui_player.play()

func play_nabrak():
	if nabrak_sound:
		sfx_player.stream = nabrak_sound
		sfx_player.play()

func play_menang():
	if menang_sound:
		sfx_player.stream = menang_sound
		sfx_player.play()

# === BAGIAN INI YANG HILANG/BELUM ADA DI SCRIPT KAMU ===

func play_jalan():
	if jalan_sound:
		# Hanya play jika belum playing (biar mulus loop-nya)
		if not walk_player.playing:
			walk_player.stream = jalan_sound
			# Sedikit variasi pitch biar natural
			walk_player.pitch_scale = randf_range(0.95, 1.05)
			walk_player.play()

# [FUNGSI BARU: STOP JALAN]
# Fungsi inilah yang dicari oleh level2.gd tapi tidak ketemu
func stop_jalan():
	if walk_player.playing:
		walk_player.stop()
