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

@onready var ui_petunjuk     = $UI_Tips
@onready var tombol_go       = $UI_Tips/TextureRect/go

# ==========================
# 📝 VARIABEL GLOBAL
# ==========================
var posisi_awal = Vector2.ZERO 
var game_selesai = false 
var sedang_loop = false 

var arah_terakhir = "" 

# [BARU] Pointer untuk menunjuk baris kode mana yang sedang aktif
var indeks_instruksi = 0 

var teks_petunjuk = """# Python Code:

if player_gerak():
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
	ui_petunjuk.visible = false
	
	atur_interaksi(true)
	
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
	
	tombol_go.pressed.connect(_on_go_pressed)
	
	sprite_animasi.play("diam")

# ==========================
# 🧠 LOGIKA AI (SEQUENTIAL EXECUTION)
# ==========================
func jalankan_kode_user():
	if game_selesai: return
	
	# 1. Ambil daftar semua perintah secara berurutan
	# Contoh: ["bawah", "kanan", "diam"]
	var daftar_instruksi = parsing_prioritas_arah_python_asli()
	
	if daftar_instruksi.size() > 0 and daftar_instruksi[0] == "RESET_GAME":
		handle_reset_command()
		return
	
	if daftar_instruksi.size() == 0:
		print("❌ Kode tidak valid.")
		return
	
	sedang_loop = true
	indeks_instruksi = 0 # Mulai dari perintah pertama
	
	while sedang_loop and not game_selesai:
		
		# Pastikan kita tidak kehabisan instruksi
		if indeks_instruksi >= daftar_instruksi.size():
			print("Habis instruksi -> Stop")
			sedang_loop = false
			sprite_animasi.play("diam")
			break
			
		# Ambil arah yang sedang aktif sekarang
		var arah_sekarang = daftar_instruksi[indeks_instruksi]
		
		# Cek Typo
		if not (arah_sekarang in ["kanan", "kiri", "atas", "bawah", "diam"]):
			print("⚠️ Typo: ", arah_sekarang, " -> Skip ke baris berikutnya")
			indeks_instruksi += 1
			continue
		
		# Jika perintah DIAM
		if arah_sekarang == "diam":
			print("Robot Berhenti (Perintah Diam)")
			sedang_loop = false
			GlobalAudio.stop_jalan()
			sprite_animasi.play("diam")
			return
		
		# === LOGIKA UTAMA ===
		# Cek apakah bisa jalan ke arah sekarang?
		if cek_validasi_gerak(arah_sekarang):
			# BISA -> Jalan terus (Jangan ganti index)
			await gerakkan_player(arah_sekarang)
		else:
			# GAK BISA (Mentok/Balik Arah)
			# 1. Cek apakah karena tembok? Jika ya, TABRAK SEKALI.
			if cek_apakah_tembok(arah_sekarang):
				await aksi_nabrak(arah_sekarang)
			
			# 2. [KUNCI SOLUSI]
			# Karena arah ini sudah gagal (mentok), kita CORET arah ini.
			# Kita pindah ke instruksi berikutnya (Index + 1).
			print("Mentok di ", arah_sekarang, " -> Pindah ke perintah berikutnya.")
			indeks_instruksi += 1
			
			# Loop while akan mengulang, dan mengambil arah baru di putaran depan.
		
		await get_tree().create_timer(0.05).timeout 

func handle_reset_command():
	print("🔄 Mereset Game...")
	reset_posisi_player()
	input_area.text = teks_petunjuk
	GlobalAudio.stop_jalan()

# ==========================
# 💥 FUNGSI VISUAL NABRAK
# ==========================
func aksi_nabrak(arah: String):
	if not (arah in ["kanan", "kiri", "atas", "bawah"]): return

	var jarak_x = 121
	var jarak_y = 88
	var vec = Vector2.ZERO
	
	match arah:
		"kanan": vec = Vector2.RIGHT * jarak_x
		"kiri":  vec = Vector2.LEFT * jarak_x
		"atas":  vec = Vector2.UP * jarak_y
		"bawah": vec = Vector2.DOWN * jarak_y
	
	var nama_anim = "diam"
	var flip = (arah == "kiri")
	if arah == "kanan": nama_anim = "jalan_kanan"
	elif arah == "kiri": nama_anim = "jalan_kiri"
	elif arah == "atas": nama_anim = "jalan_atas"
	elif arah == "bawah": nama_anim = "jalan_bawah"
	
	sprite_animasi.flip_h = flip
	sprite_animasi.play(nama_anim)
	
	GlobalAudio.play_nabrak()
	
	var tween = create_tween()
	tween.tween_property(player, "position", player.position + (vec * 0.15), 0.1)
	tween.tween_property(player, "position", player.position, 0.1)
	await tween.finished
	sprite_animasi.play("diam")

# ==========================
# 👁️ SENSOR
# ==========================
func cek_validasi_gerak(arah: String) -> bool:
	if arah == "kanan" and arah_terakhir == "kiri": return false
	if arah == "kiri" and arah_terakhir == "kanan": return false
	if arah == "atas" and arah_terakhir == "bawah": return false
	if arah == "bawah" and arah_terakhir == "atas": return false

	return not cek_apakah_tembok(arah)

func cek_apakah_tembok(arah: String) -> bool:
	var jarak_x = 121
	var jarak_y = 88
	var vec = Vector2.ZERO
	
	match arah:
		"kanan": vec = Vector2.RIGHT * jarak_x
		"kiri":  vec = Vector2.LEFT * jarak_x
		"atas":  vec = Vector2.UP * jarak_y
		"bawah": vec = Vector2.DOWN * jarak_y
		_: return false

	var tabrakan = player.move_and_collide(vec, true)
	return tabrakan != null 

# ==========================
# 🏃 GERAKAN PLAYER
# ==========================
func gerakkan_player(arah: String):
	if game_selesai: return

	var jarak_x = 121
	var jarak_y = 88
	var vec = Vector2.ZERO
	
	match arah:
		"kanan": vec = Vector2.RIGHT * jarak_x
		"kiri":  vec = Vector2.LEFT * jarak_x
		"atas":  vec = Vector2.UP * jarak_y
		"bawah": vec = Vector2.DOWN * jarak_y
		_: return 
	
	var nama_anim = "diam"
	var flip = false
	match arah:
		"kanan": 
			nama_anim = "jalan_kanan"; flip = false
		"kiri": 
			nama_anim = "jalan_kiri"; flip = true
		"atas":  nama_anim = "jalan_atas"
		"bawah": nama_anim = "jalan_bawah"
	
	sprite_animasi.flip_h = flip
	if sprite_animasi.animation != nama_anim:
		sprite_animasi.play(nama_anim)
	
	GlobalAudio.play_jalan()
	arah_terakhir = arah 
	
	var target_pos = player.position + vec
	var tween = create_tween()
	tween.tween_property(player, "position", target_pos, 0.4).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	GlobalAudio.stop_jalan()

# ==========================
# 🛠️ PARSING STRICT
# ==========================
func parsing_prioritas_arah_python_asli() -> Array:
	var hasil = []
	var baris_kode = input_area.text.split("\n")
	
	for i in range(baris_kode.size()):
		var baris_mentah = baris_kode[i]
		var baris_bersih = baris_mentah.strip_edges()
		
		if baris_bersih == "" or baris_bersih.begins_with("#"): continue
		if baris_bersih == "reset()":
			hasil.append("RESET_GAME")
			return hasil
		
		if baris_bersih.begins_with("gerak("):
			if not (baris_mentah.begins_with(" ") or baris_mentah.begins_with("\t")):
				print("❌ Error Indentasi Baris ", i+1)
				continue 
			
			var punya_induk_valid = false
			for j in range(i-1, -1, -1):
				var baris_atas = baris_kode[j].strip_edges()
				if baris_atas == "" or baris_atas.begins_with("#"): continue 
				if baris_atas.ends_with(":"):
					if baris_atas.begins_with("if") or baris_atas.begins_with("elif") or baris_atas.begins_with("else"):
						punya_induk_valid = true
					break 
				else:
					break
			
			if not punya_induk_valid:
				print("❌ Error Baris ", i+1)
				continue 
			
			var isi_mentah = baris_bersih.split("gerak(")[1].split(")")[0].strip_edges()
			var pakai_kutip_satu = isi_mentah.begins_with("'") and isi_mentah.ends_with("'")
			var pakai_kutip_dua  = isi_mentah.begins_with('"') and isi_mentah.ends_with('"')
			
			if pakai_kutip_satu or pakai_kutip_dua:
				var arah_bersih = isi_mentah.substr(1, isi_mentah.length() - 2).to_lower()
				hasil.append(arah_bersih)
			else:
				print("❌ Error Syntax String: ", isi_mentah)
				
	return hasil

# ==========================
# UTILS & UI
# ==========================
func ambil_isi_kurung(teks):
	return teks.split("(")[1].split(")")[0].replace("'", "").replace('"', "").strip_edges()

func setup_warna_kode():
	var h = CodeHighlighter.new()
	h.add_color_region("#", "", Color(0.3, 0.8, 0.3), true)
	h.add_keyword_color("gerak", Color("8be9fd")) 
	h.add_keyword_color("player_gerak", Color("50fa7b")) 
	h.add_keyword_color("if", Color("ff79c6"))
	h.add_keyword_color("elif", Color("ff79c6"))
	h.add_keyword_color("else", Color("ff79c6"))
	h.add_keyword_color("reset", Color(1, 0.5, 0.5))
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
	indeks_instruksi = 0
	sedang_loop = false
	GlobalAudio.stop_jalan()

func atur_interaksi(aktif: bool):
	input_area.editable = aktif 
	var filter = Control.MOUSE_FILTER_STOP if aktif else Control.MOUSE_FILTER_IGNORE
	tombol_jalankan.mouse_filter = filter
	tombol_kembali.mouse_filter = filter
	tombol_petunjuk.mouse_filter = filter
	var a = 1.0 if aktif else 0.5
	tombol_jalankan.modulate.a = a
	tombol_kembali.modulate.a = a
	tombol_petunjuk.modulate.a = a

func _on_player_finish(body):
	if body.name == "karakter" and not game_selesai:
		print("🏆 MENANG!")
		GlobalAudio.stop_jalan()
		GlobalAudio.play_menang()
		game_selesai = true
		sedang_loop = false
		sprite_animasi.play("diam")
		atur_interaksi(false)
		await get_tree().create_timer(0.5).timeout
		ui_finish.visible = true

func _on_lanjut_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_lanjut, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_lanjut, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu.tscn")

func _on_ulangi_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_ulangi, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_ulangi, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	
	ui_finish.visible = false
	game_selesai = false
	atur_interaksi(true)
	reset_posisi_player()
	input_area.text = teks_petunjuk
	
	await get_tree().process_frame
	input_area.grab_focus()
	input_area.caret_blink = false
	input_area.caret_blink = true
	input_area.set_caret_line(input_area.get_line_count() - 1)
	input_area.set_caret_column(input_area.get_line(input_area.get_line_count() - 1).length())

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
	var tween = create_tween()
	tween.tween_property(tombol_kembali, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_kembali, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	sedang_loop = false
	GlobalAudio.stop_jalan()
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/if_else/if_else.tscn")
	
func _on_petunjuk_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_petunjuk, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_petunjuk, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	ui_petunjuk.visible = true
	atur_interaksi(false)  # Matikan tombol lain
	input_area.editable = false   # Matikan ketik

func _on_go_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_go, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_go, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	ui_petunjuk.visible = false
	
	# Nyalakan kembali interaksi (Hanya jika game belum selesai)
	if not game_selesai:
		atur_interaksi(true)
		
		if not sedang_loop:
			input_area.editable = true
			await get_tree().process_frame
			input_area.grab_focus()
			input_area.caret_blink = false
			input_area.caret_blink = true

func _on_hover_entered(b): create_tween().tween_property(b, "scale", Vector2(1.1, 1.1), 0.1)
func _on_hover_exited(b): create_tween().tween_property(b, "scale", Vector2(1.0, 1.0), 0.1)
func _animasi_tombol_masuk():
	for b in [tombol_jalankan, tombol_kembali, tombol_petunjuk]:
		create_tween().tween_property(b, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
