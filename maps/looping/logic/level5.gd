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

var memori_variabel = {} 

var teks_petunjuk = """# Python Code:

# for i in range(3):
# 	gerak('arah')

# i = 0
# while i < 2:
# 	gerak('arah')
# 	i += 1

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
	
	sprite_animasi.play("diam")

# ==========================
# 🧠 LOGIKA INTERPRETER
# ==========================
func jalankan_kode_user():
	game_selesai = false 
	sedang_loop = true
	memori_variabel.clear()
	
	var semua_baris = input_area.text.split("\n")
	
	await eksekusi_blok_kode(semua_baris)
	
	sedang_loop = false
	GlobalAudio.stop_jalan()
	if not game_selesai:
		sprite_animasi.play("diam")

func eksekusi_blok_kode(baris_kode: Array):
	var i = 0
	while i < baris_kode.size():
		if not sedang_loop or game_selesai: return
		
		var baris_mentah = baris_kode[i]
		var baris = baris_mentah.strip_edges()
		
		if baris == "" or baris.begins_with("#"):
			i += 1
			continue
		
		if baris == "reset()":
			handle_reset_command()
			return
		
		# === 1. WHILE LOOP (STRICT CHECK) ===
		if baris.begins_with("while "):
			# Cek 1: Harus diakhiri ":" (Tanpa karakter sampah)
			if not baris.ends_with(":"):
				print("⚠️ Typo Syntax While (Missing :) -> Skip Loop, Jalankan bawahnya.")
				i += 1; continue

			# Cek 2: Angka batas harus valid (Anti 2fds)
			var kondisi_raw = baris.trim_prefix("while ").trim_suffix(":").strip_edges()
			if "<" in kondisi_raw:
				var angka_str = kondisi_raw.split("<")[1].strip_edges()
				if not angka_str.is_valid_int():
					# Cek apakah itu variabel?
					if not memori_variabel.has(angka_str):
						print("⚠️ Typo Angka While (Bukan Int) -> Skip Loop.")
						i += 1; continue
			
			# Jika lolos, baru jalankan loop
			var hasil_loop = ambil_blok_loop(baris_kode, i)
			var blok_loop = hasil_loop[0]
			var index_baru = hasil_loop[1]
			
			var safety = 0
			while cek_kondisi_while(baris) and safety < 50:
				if not sedang_loop or game_selesai: break
				await eksekusi_blok_kode(blok_loop)
				safety += 1
			
			i = index_baru
			continue

		# === 2. FOR LOOP (STRICT CHECK) ===
		if baris.begins_with("for "):
			# Cek 1: Struktur Wajib "for ... in range(...):"
			# PENTING: Harus diakhiri "):" (Tidak boleh ada sampah di belakang)
			if not (baris.contains(" in range(") and baris.ends_with("):")):
				print("⚠️ Typo Syntax For (Sampah di akhir/Salah format) -> Skip Loop, Jalankan bawahnya.")
				i += 1; continue
			
			var hasil_loop = ambil_blok_loop(baris_kode, i)
			var blok_loop = hasil_loop[0]
			var index_baru = hasil_loop[1]
			
			# Cek 2: Isi range harus angka murni
			var split_range = baris.split("range(")
			var sisi_kanan = split_range[1] # "2):"
			var angka_str = sisi_kanan.left(sisi_kanan.length() - 2).strip_edges() # Ambil "2"
			
			if not angka_str.is_valid_int():
				print("⚠️ Typo Angka Range -> Skip Loop.")
				i += 1; continue
			
			var jumlah = int(angka_str)
			for putaran in range(jumlah):
				if not sedang_loop: break
				await eksekusi_blok_kode(blok_loop)
			
			i = index_baru
			continue

		# === 3. VARIABEL & INCREMENT ===
		if "+=" in baris:
			proses_increment(baris)
			i += 1
			continue

		if "=" in baris and not ("gerak" in baris) and not ("while" in baris) and not ("+=" in baris):
			proses_variabel(baris)
			i += 1
			continue

		# === 4. GERAK ===
		if baris.begins_with("gerak"):
			await eksekusi_satu_baris_gerak(baris)
			i += 1
			continue
			
		i += 1

# ==========================================
# 🛠️ FUNGSI GERAK (STRICT & MULTIPLY)
# ==========================================
func eksekusi_satu_baris_gerak(baris: String):
	var jumlah_kali = 1
	var perintah_utama = baris
	
	if "*" in baris:
		var split_bintang = baris.split("*")
		perintah_utama = split_bintang[0].strip_edges()
		var angka_str = split_bintang[1].strip_edges()
		if angka_str.is_valid_int():
			jumlah_kali = int(angka_str)
		else:
			print("❌ Error Angka Perkalian")
			return

	if not perintah_utama.ends_with(")"):
		print("❌ Error Syntax: Kurang ')' -> ", baris)
		return
	
	if perintah_utama.begins_with("gerak("):
		var isi = perintah_utama.split("gerak(")[1].split(")")[0].strip_edges()
		var pakai_kutip = (isi.begins_with("'") and isi.ends_with("'")) or (isi.begins_with('"') and isi.ends_with('"'))
		
		if pakai_kutip:
			var arah = isi.substr(1, isi.length() - 2).to_lower()
			
			if arah in ["kanan", "kiri", "atas", "bawah"]:
				for k in range(jumlah_kali):
					if not sedang_loop or game_selesai: break
					
					if not cek_apakah_tembok(arah):
						await gerakkan_player(arah)
					else:
						await aksi_nabrak(arah)
						# Tidak break agar efek bonk berulang jika perkalian
						
			elif arah == "diam":
				await get_tree().create_timer(0.5).timeout
		else:
			print("❌ Error: Harus string (pakai kutip) -> ", isi)

# ==========================
# 🏃 GERAKAN & FISIKA (MULUS)
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
	var flip = (arah == "kiri")
	if arah == "kanan": nama_anim = "jalan_kanan"
	elif arah == "kiri": nama_anim = "jalan_kiri"
	elif arah == "atas": nama_anim = "jalan_atas"
	elif arah == "bawah": nama_anim = "jalan_bawah"
	
	sprite_animasi.flip_h = flip
	if sprite_animasi.animation != nama_anim:
		sprite_animasi.play(nama_anim)
	
	GlobalAudio.play_jalan()
	
	var target_pos = player.position + vec
	var tween = create_tween()
	tween.tween_property(player, "position", target_pos, 0.5).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	GlobalAudio.stop_jalan()
	
	# Hapus jeda diam agar mulus

func cek_apakah_tembok(arah: String) -> bool:
	var jarak_x = 121; var jarak_y = 88; var vec = Vector2.ZERO
	match arah:
		"kanan": vec = Vector2.RIGHT * jarak_x
		"kiri":  vec = Vector2.LEFT * jarak_x
		"atas":  vec = Vector2.UP * jarak_y
		"bawah": vec = Vector2.DOWN * jarak_y
	return player.move_and_collide(vec, true) != null

func aksi_nabrak(arah: String):
	var jarak_x = 121; var jarak_y = 88; var vec = Vector2.ZERO
	match arah:
		"kanan": vec = Vector2.RIGHT * jarak_x
		"kiri":  vec = Vector2.LEFT * jarak_x
		"atas":  vec = Vector2.UP * jarak_y
		"bawah": vec = Vector2.DOWN * jarak_y
	
	GlobalAudio.play_nabrak()
	var tween = create_tween()
	tween.tween_property(player, "position", player.position + (vec * 0.15), 0.1)
	tween.tween_property(player, "position", player.position, 0.1)
	await tween.finished

# ==========================
# UTILS & UI
# ==========================
func ambil_blok_loop(semua_baris, index_mulai):
	var blok = []
	var j = index_mulai + 1
	while j < semua_baris.size():
		var baris_bawah = semua_baris[j]
		if baris_bawah.begins_with(" ") or baris_bawah.begins_with("\t"):
			blok.append(baris_bawah)
			j += 1
		else:
			break
	return [blok, j]

func proses_variabel(baris):
	var bagian = baris.split("=")
	var nama = bagian[0].strip_edges()
	var nilai = int(bagian[1].strip_edges())
	memori_variabel[nama] = nilai

func proses_increment(baris):
	var bagian = baris.split("+=")
	var nama = bagian[0].strip_edges()
	var tambah = int(bagian[1].strip_edges())
	if memori_variabel.has(nama):
		memori_variabel[nama] += tambah

func cek_kondisi_while(header) -> bool:
	var kondisi = header.replace("while ", "").replace(":", "").strip_edges()
	if "<" in kondisi:
		var bagian = kondisi.split("<")
		var nama = bagian[0].strip_edges()
		var batas = int(bagian[1].strip_edges())
		if memori_variabel.has(nama):
			return memori_variabel[nama] < batas
	return false

func handle_reset_command():
	reset_posisi_player()
	input_area.text = teks_petunjuk
	GlobalAudio.stop_jalan()

func reset_posisi_player():
	player.position = posisi_awal
	sprite_animasi.play("diam")
	sprite_animasi.flip_h = false
	sedang_loop = false
	memori_variabel.clear()
	GlobalAudio.stop_jalan()
	game_selesai = false

func setup_warna_kode():
	var h = CodeHighlighter.new()
	h.add_color_region("#", "", Color(0.3, 0.8, 0.3), true)
	h.add_keyword_color("for", Color("ff79c6"))
	h.add_keyword_color("while", Color("ff79c6"))
	h.add_keyword_color("in", Color("ff79c6"))
	h.add_keyword_color("range", Color("8be9fd"))
	h.add_keyword_color("gerak", Color("8be9fd"))
	h.add_keyword_color("reset", Color(1, 0.5, 0.5))
	var c = Color(1,1,0)
	h.add_keyword_color("kiri", c); h.add_keyword_color("kanan", c)
	h.add_keyword_color("atas", c); h.add_keyword_color("bawah", c)
	input_area.syntax_highlighter = h

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
	GlobalAudio.play_click()
	sedang_loop = false
	GlobalAudio.stop_jalan()
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/looping/looping.tscn")
func _on_petunjuk_pressed():
	GlobalAudio.play_click()
	await get_tree().create_timer(0.1).timeout
	input_area.text = teks_petunjuk
func _on_hover_entered(b): create_tween().tween_property(b, "scale", Vector2(1.1, 1.1), 0.1)
func _on_hover_exited(b): create_tween().tween_property(b, "scale", Vector2(1.0, 1.0), 0.1)
func _animasi_tombol_masuk():
	for b in [tombol_jalankan, tombol_kembali, tombol_petunjuk]:
		create_tween().tween_property(b, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
