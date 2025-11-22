extends Node

# ==========================
# 🔹 REFERENSI NODE
# ==========================
@onready var tombol_jalankan = $map/run
@onready var tombol_kembali  = $map/back
@onready var tombol_petunjuk = $map/tips
@onready var input_area      = $map/TextEdit
@onready var player          = $map/karakter
@onready var sprite_animasi  = $map/karakter/karaktermap2 

@onready var finish_area     = $map/FinishArea
@onready var ui_finish       = $UI_Finish
@onready var tombol_lanjut   = $UI_Finish/TextureRect/TombolLanjut
@onready var tombol_ulangi   = $UI_Finish/TextureRect/TombolUlangi 

# ==========================
# 📝 VARIABEL GLOBAL
# ==========================
var posisi_awal = Vector2.ZERO 
var game_selesai = false 
var sedang_loop = false 

# Menyimpan arah terakhir agar tidak balik badan
var arah_terakhir = "" 

# Petunjuk Baru
var teks_petunjuk = """# Python Code:

if bisa_gerak()
   gerak('arah') 
else:
   gerak('diam')
"""

# ==========================
# 🔹 SETUP AWAL
# ==========================
func _ready():
	input_area.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	input_area.scale = Vector2(1, 1)
	posisi_awal = player.position
	setup_warna_kode()
	input_area.text = teks_petunjuk
	
	ui_finish.visible = false
	for tombol in [tombol_jalankan, tombol_kembali, tombol_petunjuk]:
		tombol.scale = Vector2.ZERO
	_animasi_tombol_masuk()

	for b in [tombol_jalankan, tombol_kembali, tombol_petunjuk]:
		b.mouse_entered.connect(_on_hover_entered.bind(b))
		b.mouse_exited.connect(_on_hover_exited.bind(b))
	
	tombol_jalankan.pressed.connect(_on_jalankan_pressed)
	tombol_kembali.pressed.connect(_on_kembali_pressed)
	tombol_petunjuk.pressed.connect(_on_petunjuk_pressed)
	
	finish_area.body_entered.connect(_on_player_finish)
	tombol_lanjut.pressed.connect(_on_lanjut_pressed)
	tombol_ulangi.pressed.connect(_on_ulangi_pressed)
	
	sprite_animasi.play("diam")

# ==========================
# 🧠 LOGIKA AI (PRIORITAS)
# ==========================
func jalankan_kode_user():
	if game_selesai: return
	
	var daftar_prioritas = parsing_prioritas_arah()
	
	if daftar_prioritas.size() == 0:
		print("Tidak ada perintah gerak() yang valid!")
		return
	
	sedang_loop = true
	
	# Loop Pergerakan
	while sedang_loop and not game_selesai:
		
		var berhasil_gerak = false
		
		# Cek Prioritas (IF -> ELIF -> ELSE)
		for arah in daftar_prioritas:
			
			# 1. Cek Perintah Diam (STOP TOTAL)
			if arah == "diam":
				print("Robot Berhenti (Perintah Diam)")
				sedang_loop = false
				sprite_animasi.play("diam")
				return # Keluar total dari fungsi
			
			# 2. Cek Validasi Gerak
			if cek_validasi_gerak(arah):
				# JALAN 1 LANGKAH
				await gerakkan_player(arah)
				berhasil_gerak = true
				break # Kembali ke prioritas awal
		
		# Jika Buntu Total (Semua prioritas gagal & tidak ada else diam)
		if not berhasil_gerak:
			print("Buntu Total -> Stop Loop")
			sedang_loop = false
			sprite_animasi.play("diam")
			
		await get_tree().create_timer(0.05).timeout 

# Fungsi Parsing Strict
func parsing_prioritas_arah() -> Array:
	var hasil = []
	var baris_kode = input_area.text.split("\n")
	
	for baris in baris_kode:
		baris = baris.strip_edges()
		if baris.begins_with("gerak("):
			var isi_mentah = baris.split("gerak(")[1].split(")")[0].strip_edges()
			
			var pakai_kutip_satu = isi_mentah.begins_with("'") and isi_mentah.ends_with("'")
			var pakai_kutip_dua  = isi_mentah.begins_with('"') and isi_mentah.ends_with('"')
			
			if pakai_kutip_satu or pakai_kutip_dua:
				var arah_bersih = isi_mentah.substr(1, isi_mentah.length() - 2).to_lower()
				hasil.append(arah_bersih)
			else:
				print("Syntax Error: Parameter harus string! -> ", isi_mentah)
				
	return hasil

# ==========================
# 👁️ SENSOR
# ==========================
func cek_validasi_gerak(arah: String) -> bool:
	if arah == "kanan" and arah_terakhir == "kiri": return false
	if arah == "kiri" and arah_terakhir == "kanan": return false
	if arah == "atas" and arah_terakhir == "bawah": return false
	if arah == "bawah" and arah_terakhir == "atas": return false

	var jarak_x = 121
	var jarak_y = 88
	var vec = Vector2.ZERO
	
	match arah:
		"kanan": vec = Vector2.RIGHT * jarak_x
		"kiri":  vec = Vector2.LEFT * jarak_x
		"atas":  vec = Vector2.UP * jarak_y
		"bawah": vec = Vector2.DOWN * jarak_y
		_: return false # Jaga-jaga jika arah aneh

	var tabrakan = player.move_and_collide(vec, true)
	return tabrakan == null

# ==========================
# 🏃 GERAKAN PLAYER (FIXED AUDIO)
# ==========================
func gerakkan_player(arah: String):
	if game_selesai: return

	var jarak_x = 121
	var jarak_y = 88
	var vec = Vector2.ZERO
	
	# [FIX UTAMA DI SINI]
	# Jika arah bukan kanan/kiri/atas/bawah (misal 'diam'), langsung BATALKAN.
	# Ini mencegah audio jalan berbunyi.
	match arah:
		"kanan": vec = Vector2.RIGHT * jarak_x
		"kiri":  vec = Vector2.LEFT * jarak_x
		"atas":  vec = Vector2.UP * jarak_y
		"bawah": vec = Vector2.DOWN * jarak_y
		_: return # ⛔ STOP! Jangan lanjut ke bawah jika arah tidak dikenal/diam.
	
	# 1. Update Animasi
	var nama_anim = "diam"
	var flip = false
	
	match arah:
		"kanan": 
			nama_anim = "jalan_kanan"
			flip = false
		"kiri": 
			nama_anim = "jalan_kiri"
			flip = true
		"atas":  nama_anim = "jalan_atas"
		"bawah": nama_anim = "jalan_bawah"
	
	sprite_animasi.flip_h = flip
	if sprite_animasi.animation != nama_anim:
		sprite_animasi.play(nama_anim)
	
	# 2. Audio Jalan (Hanya bunyi jika lolos match di atas)
	GlobalAudio.play_jalan()
	arah_terakhir = arah 
	
	# 3. Gerakan Tween
	var target_pos = player.position + vec
	var tween = create_tween()
	tween.tween_property(player, "position", target_pos, 0.4).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished

# ==========================
# 🛠️ HELPER & UTILS
# ==========================
func ambil_isi_kurung(teks):
	return teks.split("(")[1].split(")")[0].replace("'", "").replace('"', "").strip_edges()

func setup_warna_kode():
	var h = CodeHighlighter.new()
	h.add_color_region("#", "", Color(0.3, 0.8, 0.3), true)
	
	h.add_keyword_color("gerak", Color("8be9fd")) 
	h.add_keyword_color("bisa_gerak", Color("50fa7b")) 
	h.add_keyword_color("if", Color("ff79c6"))
	h.add_keyword_color("elif", Color("ff79c6"))
	h.add_keyword_color("else", Color("ff79c6"))
	h.add_keyword_color("player", Color("ff5555"))
	h.add_keyword_color("arah", Color("ffd6d6"))
	
	var c = Color(1,1,0)
	h.add_keyword_color("kiri", c); h.add_keyword_color("kanan", c)
	h.add_keyword_color("atas", c); h.add_keyword_color("bawah", c)
	h.add_keyword_color("diam", c)
	
	input_area.syntax_highlighter = h

func reset_posisi_player():
	player.position = posisi_awal
	sprite_animasi.play("diam")
	sprite_animasi.flip_h = false
	arah_terakhir = "" 
	sedang_loop = false

# ==========================
# LOGIKA FINISH & TOMBOL
# ==========================
func _on_player_finish(body):
	if body.name == "karakter" and not game_selesai:
		print("🏆 MENANG!")
		GlobalAudio.play_menang()
		game_selesai = true
		sedang_loop = false
		sprite_animasi.play("diam")
		await get_tree().create_timer(0.5).timeout
		ui_finish.visible = true

func _on_lanjut_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_lanjut, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_lanjut, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://maps/ifElse/view/level2.tscn")

func _on_ulangi_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_ulangi, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_ulangi, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	
	ui_finish.visible = false
	game_selesai = false
	reset_posisi_player()
	input_area.text = teks_petunjuk

func _on_jalankan_pressed():
	if game_selesai or sedang_loop: return
	var tween = create_tween()
	tween.tween_property(tombol_jalankan, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_jalankan, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	
	reset_posisi_player()
	await get_tree().create_timer(0.2).timeout
	jalankan_kode_user()

func _on_kembali_pressed():
	GlobalAudio.play_click()
	sedang_loop = false
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/if_else/if_else.tscn")
func _on_petunjuk_pressed():
	GlobalAudio.play_click()
	input_area.text = teks_petunjuk
func _on_hover_entered(b): create_tween().tween_property(b, "scale", Vector2(1.1, 1.1), 0.1)
func _on_hover_exited(b): create_tween().tween_property(b, "scale", Vector2(1, 1), 0.1)
func _animasi_tombol_masuk():
	for b in [tombol_jalankan, tombol_kembali, tombol_petunjuk]:
		create_tween().tween_property(b, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
