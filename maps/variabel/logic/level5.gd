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

# Referensi Finish & Popup
@onready var finish_area     = $map/FinishArea
@onready var ui_finish       = $UI_Finish
@onready var tombol_lanjut   = $UI_Finish/TextureRect/TombolLanjut
@onready var tombol_ulangi   = $UI_Finish/TextureRect/TombolUlangi 

# ==========================
# 📝 VARIABEL GLOBAL
# ==========================
var posisi_awal = Vector2.ZERO 
var game_selesai = false 

var teks_petunjuk = """# Python Code: """

# ==========================
# 🔹 SETUP AWAL (_ready)
# ==========================
func _ready():
	# 1. FIX TAMPILAN
	input_area.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	input_area.scale = Vector2(1, 1)
	
	posisi_awal = player.position
	setup_warna_kode()
	input_area.text = teks_petunjuk
	
	# 2. UI SETUP
	ui_finish.visible = false
	for tombol in [tombol_jalankan, tombol_kembali, tombol_petunjuk]:
		tombol.scale = Vector2.ZERO
	_animasi_tombol_masuk()

	# 3. KONEKSI SINYAL
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
# 🏆 LOGIKA FINISH & POPUP
# ==========================
func _on_player_finish(body):
	if body.name == "karakter" and not game_selesai:
		print("🏆 MENANG!")
		
		# Panggil Suara Menang (Global)
		GlobalAudio.play_menang()
		
		game_selesai = true
		sprite_animasi.play("diam")
		await get_tree().create_timer(0.5).timeout
		ui_finish.visible = true

func _on_lanjut_pressed():
	# Animasi tombol lanjut
	var tween = create_tween()
	tween.tween_property(tombol_lanjut, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_lanjut, "scale", Vector2(1.0, 1.0), 0.05)
	
	# Panggil fungsi klik (Global)
	GlobalAudio.play_click()
	
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu.tscn")

func _on_ulangi_pressed():
	# Animasi tombol ulangi
	var tween = create_tween()
	tween.tween_property(tombol_ulangi, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_ulangi, "scale", Vector2(1.0, 1.0), 0.05)
	
	GlobalAudio.play_click()
	
	await get_tree().create_timer(0.2).timeout
	
	# 1. Tutup Popup
	ui_finish.visible = false
	
	# 2. Reset Status Game
	game_selesai = false
	
	# 3. Kembalikan Player ke Awal
	reset_posisi_player()
	
	# 4. RESET TEKS KODE
	input_area.text = teks_petunjuk 


# ==========================================
# 🎨 PEWARNAAN KODE
# ==========================================
func setup_warna_kode():
	var highlighter = CodeHighlighter.new()
	highlighter.add_color_region("#", "", Color(0.3, 0.8, 0.3), true) 
	highlighter.add_keyword_color("print", Color("8be9fd")) 
	highlighter.add_keyword_color("reset", Color(1, 0.5, 0.5))
	
	var warna_arah = Color(1, 1, 0)
	highlighter.add_keyword_color("kiri", warna_arah)
	highlighter.add_keyword_color("kanan", warna_arah)
	highlighter.add_keyword_color("atas", warna_arah)
	highlighter.add_keyword_color("bawah", warna_arah)
	
	input_area.syntax_highlighter = highlighter

# ==========================
# 🔸 EFEK TOMBOL UTAMA
# ==========================
func _on_hover_entered(button):
	create_tween().tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)
func _on_hover_exited(button):
	create_tween().tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _animasi_tombol_masuk():
	var tween = create_tween()
	var tombols = [tombol_jalankan, tombol_kembali, tombol_petunjuk]
	for i in range(tombols.size()):
		tween.tween_property(tombols[i], "scale", Vector2.ONE, 0.2)\
			.set_trans(Tween.TRANS_BACK).set_delay(i * 0.1)

func _on_jalankan_pressed():
	if game_selesai: return
	
	var tween = create_tween()
	tween.tween_property(tombol_jalankan, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_jalankan, "scale", Vector2(1.0, 1.0), 0.05)
	
	GlobalAudio.play_click()
	
	reset_posisi_player()
	await get_tree().create_timer(0.2).timeout
	jalankan_kode_user()

func _on_kembali_pressed():
	GlobalAudio.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/variabel/variabel.tscn")

func _on_petunjuk_pressed():
	GlobalAudio.play_click()
	await get_tree().create_timer(0.1).timeout
	input_area.text = teks_petunjuk 

func reset_posisi_player():
	player.position = posisi_awal
	sprite_animasi.play("diam")
	sprite_animasi.flip_h = false

# ==========================
# 🧠 LOGIKA PARSING (STRICT PYTHON)
# ==========================
func jalankan_kode_user():
	if not input_area: return

	var kode_full = input_area.text
	var baris_kode = kode_full.split("\n")
	var memori_variabel = {} 
	
	for baris in baris_kode:
		if game_selesai: break
		
		baris = baris.strip_edges()
		if baris == "" or baris.begins_with("#"): continue
			
		# 1. VARIABEL (Strict Mode)
		if "=" in baris and not baris.begins_with("print"):
			var bagian = baris.split("=")
			if bagian.size() == 2:
				var nama_var = bagian[0].strip_edges()
				var nilai_raw = bagian[1].strip_edges()
				
				var pakai_kutip_satu = nilai_raw.begins_with("'") and nilai_raw.ends_with("'")
				var pakai_kutip_dua  = nilai_raw.begins_with('"') and nilai_raw.ends_with('"')
				
				if pakai_kutip_satu or pakai_kutip_dua:
					var nilai_bersih = nilai_raw.substr(1, nilai_raw.length() - 2).to_lower()
					memori_variabel[nama_var] = nilai_bersih
				else:
					print("ERROR SYNTAX: String harus pakai kutip! -> ", nilai_raw)
		
		# 2. RESET
		elif baris == "reset()":
			reset_posisi_player()
			input_area.text = teks_petunjuk 
			await get_tree().create_timer(0.5).timeout
			
		# 3. PRINT
		elif baris.begins_with("print("):
			var jumlah_ulang = 1
			var teks_bersih = baris
			if "*" in baris:
				var split_kali = baris.split("*")
				teks_bersih = split_kali[0].strip_edges() 
				if split_kali.size() > 1:
					jumlah_ulang = int(split_kali[1])
			
			var isi = teks_bersih.replace("print(", "").replace(")", "").strip_edges()
			var arah_gerak = ""
			
			if memori_variabel.has(isi):
				arah_gerak = memori_variabel[isi]
			else:
				var pakai_kutip_satu = isi.begins_with("'") and isi.ends_with("'")
				var pakai_kutip_dua  = isi.begins_with('"') and isi.ends_with('"')
				
				if pakai_kutip_satu or pakai_kutip_dua:
					arah_gerak = isi.replace("'", "").replace('"', "").to_lower()
				else:
					print("NameError: Variabel '", isi, "' tidak ditemukan.")
					continue 

			for i in range(jumlah_ulang):
				if game_selesai: break 
				await gerakkan_player(arah_gerak)

# ==========================
# 🏃 GERAKAN PLAYER (MULUS / LINEAR)
# ==========================
func gerakkan_player(arah: String):
	if game_selesai: return

	# GRID KHUSUS (Horizontal 121, Vertikal 88)
	var jarak_grid_x = 121
	var jarak_grid_y = 88
	var vector_arah = Vector2.ZERO
	
	match arah:
		"kanan": vector_arah = Vector2.RIGHT * jarak_grid_x
		"kiri":  vector_arah = Vector2.LEFT * jarak_grid_x
		"atas":  vector_arah = Vector2.UP * jarak_grid_y
		"bawah": vector_arah = Vector2.DOWN * jarak_grid_y
		_: return

	var tabrakan = player.move_and_collide(vector_arah, true)
	
	if tabrakan:
		GlobalAudio.play_nabrak()
		update_animasi(arah, false)
		
		var tween = create_tween()
		tween.tween_property(player, "position", player.position + (vector_arah * 0.2), 0.1)
		tween.tween_property(player, "position", player.position, 0.1)
		await tween.finished
	else:
		GlobalAudio.play_jalan()
		update_animasi(arah, true)
		
		var target_pos = player.position + vector_arah
		var tween = create_tween()
		tween.tween_property(player, "position", target_pos, 0.5).set_trans(Tween.TRANS_LINEAR)
		
		await tween.finished
		update_animasi(arah, false)

func update_animasi(arah_sekarang: String, sedang_bergerak: bool):
	if arah_sekarang == "kanan":
		sprite_animasi.flip_h = false
		if sedang_bergerak: sprite_animasi.play("jalan_kanan")
		else: sprite_animasi.play("diam")
	elif arah_sekarang == "kiri":
		sprite_animasi.flip_h = true
		if sedang_bergerak: sprite_animasi.play("jalan_kiri") 
		else: sprite_animasi.play("diam")
	elif arah_sekarang == "atas":
		if sedang_bergerak: sprite_animasi.play("jalan_atas")
		else: sprite_animasi.play("diam")
	elif arah_sekarang == "bawah":
		if sedang_bergerak: sprite_animasi.play("jalan_bawah")
		else: sprite_animasi.play("diam")
