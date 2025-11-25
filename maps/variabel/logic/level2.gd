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

var teks_petunjuk = """# Python Code: 

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
	
	# Pastikan interaksi nyala di awal
	atur_interaksi(true)
	
	# Animasi Tombol Masuk
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
# 🔒 FUNGSI KUNCI INTERAKSI (UPDATE FINAL)
# ==========================
func atur_interaksi(aktif: bool):
	# 1. Matikan Input Teks
	input_area.editable = aktif 
	
	# 2. Atur Mouse Filter (Kunci agar tidak ada hover)
	var filter_mouse = Control.MOUSE_FILTER_STOP if aktif else Control.MOUSE_FILTER_IGNORE
	
	tombol_jalankan.mouse_filter = filter_mouse
	tombol_kembali.mouse_filter = filter_mouse
	tombol_petunjuk.mouse_filter = filter_mouse
	
	# 3. Efek Visual (Transparan jika mati)
	var alpha = 1.0 if aktif else 0.5
	tombol_jalankan.modulate.a = alpha
	tombol_kembali.modulate.a = alpha
	tombol_petunjuk.modulate.a = alpha

# ==========================
# 🧠 LOGIKA PARSING
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
			
		# 1. VARIABLE
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
					print("❌ Error: Nilai string harus pakai kutip! -> ", nilai_raw)
		
		# 2. RESET
		elif baris == "reset()":
			reset_posisi_player()
			input_area.text = teks_petunjuk 
			await get_tree().create_timer(0.5).timeout
			
		# 3. PRINT (Strict Variable)
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
			
			var is_string_langsung = (isi.begins_with("'") and isi.ends_with("'")) or \
									 (isi.begins_with('"') and isi.ends_with('"'))
			
			if is_string_langsung:
				print("❌ DILARANG: Jangan print string langsung! Gunakan variabel.")
				continue 
			
			if memori_variabel.has(isi):
				arah_gerak = memori_variabel[isi]
			else:
				print("❌ NameError: Variabel '", isi, "' tidak ditemukan.")
				continue 

			for i in range(jumlah_ulang):
				if game_selesai: break 
				await gerakkan_player(arah_gerak)

# ==========================
# 🏃 GERAKAN PLAYER
# ==========================
func gerakkan_player(arah: String):
	if game_selesai: return

	var jarak_x = 123.7
	var jarak_y = 90
	var vec = Vector2.ZERO
	
	match arah:
		"kanan": vec = Vector2.RIGHT * jarak_x
		"kiri":  vec = Vector2.LEFT * jarak_x
		"atas":  vec = Vector2.UP * jarak_y
		"bawah": vec = Vector2.DOWN * jarak_y
		_: return 

	var tabrakan = player.move_and_collide(vec, true)
	
	if tabrakan:
		GlobalAudio.play_nabrak()
		update_animasi(arah, false)
		var tween = create_tween()
		tween.tween_property(player, "position", player.position + (vec * 0.2), 0.1)
		tween.tween_property(player, "position", player.position, 0.1)
		await tween.finished
	else:
		GlobalAudio.play_jalan()
		update_animasi(arah, true)
		var target_pos = player.position + vec
		var tween = create_tween()
		tween.tween_property(player, "position", target_pos, 0.5).set_trans(Tween.TRANS_LINEAR)
		await tween.finished
		GlobalAudio.stop_jalan()
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

# ==========================
# UTILS & UI
# ==========================
func setup_warna_kode():
	var h = CodeHighlighter.new()
	h.add_color_region("#", "", Color(0.3, 0.8, 0.3), true) 
	h.add_keyword_color("print", Color("8be9fd")) 
	h.add_keyword_color("reset", Color(1, 0.5, 0.5))
	var c = Color(1, 1, 0)
	h.add_keyword_color("kiri", c); h.add_keyword_color("kanan", c)
	h.add_keyword_color("atas", c); h.add_keyword_color("bawah", c)
	input_area.syntax_highlighter = h

func reset_posisi_player():
	player.position = posisi_awal
	sprite_animasi.play("diam")
	sprite_animasi.flip_h = false
	GlobalAudio.stop_jalan() 

func _on_player_finish(body):
	if body.name == "karakter" and not game_selesai:
		print("🏆 MENANG!")
		GlobalAudio.stop_jalan()
		GlobalAudio.play_menang()
		game_selesai = true
		sprite_animasi.play("diam")
		
		# KUNCI INTERAKSI (BEKU TOTAL)
		atur_interaksi(false)
		
		await get_tree().create_timer(0.5).timeout
		ui_finish.visible = true

func _on_lanjut_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_lanjut, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_lanjut, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://maps/variabel/view/level3.tscn")

func _on_ulangi_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_ulangi, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_ulangi, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	
	ui_finish.visible = false
	game_selesai = false
	
	# BUKA KUNCI (NORMAL KEMBALI)
	atur_interaksi(true)
	
	reset_posisi_player()
	input_area.text = teks_petunjuk
	
	# Bangunkan Kursor
	await get_tree().process_frame
	input_area.grab_focus()
	input_area.caret_blink = false
	input_area.caret_blink = true
	input_area.set_caret_line(input_area.get_line_count() - 1)
	input_area.set_caret_column(input_area.get_line(input_area.get_line_count() - 1).length())

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
	var tween = create_tween()
	tween.tween_property(tombol_kembali, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_kembali, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	game_selesai = false
	GlobalAudio.stop_jalan()
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/variabel/variabel.tscn")
	
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
		
		if not game_selesai:
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
