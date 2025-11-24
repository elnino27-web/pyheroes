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
# 📝 VARIABEL GLOBAL & STATE MACHINE
# ==========================
var posisi_awal = Vector2.ZERO 
var game_selesai = false 
var sedang_eksekusi = false 
var memori_variabel = {} 

var execution_state = 0
const STATE_CODE_READY = 0       
const STATE_INPUT_NEEDED = 1     
const STATE_EXECUTION_READY = 2  

var input_prompts = []           
var collected_inputs = {}        
var original_code = ""           

var teks_petunjuk = """# Python Code:

# Minta input dan cetak
arah1 = input('Masukkan arah')
print(arah1)
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
	original_code = teks_petunjuk
	
	ui_finish.visible = false
	ui_petunjuk.visible = false
	atur_interaksi_tombol(true) 
	
	for tombol in [tombol_jalankan, tombol_kembali, tombol_petunjuk]:
		tombol.scale = Vector2.ZERO
	_animasi_tombol_masuk()

	# KONEKSI SINYAL
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
# 🧠 LOGIKA UTAMA (STATE MACHINE)
# ==========================
func jalankan_kode_user():
	if game_selesai or sedang_eksekusi: return
	
	match execution_state:
		STATE_CODE_READY:
			await proses_tahap_input_collection()
		
		STATE_INPUT_NEEDED:
			await proses_tahap_input_simpan_dan_siap_eksekusi()
		
		STATE_EXECUTION_READY:
			await proses_tahap_eksekusi()
			
# ---------------------------------
# TAHAP 1: Cari baris input()
# ---------------------------------
func proses_tahap_input_collection():
	original_code = input_area.text
	input_prompts.clear()
	
	var semua_baris = original_code.split("\n")
	
	for baris_mentah in semua_baris:
		var baris = baris_mentah.strip_edges()
		
		# [BARU] Cek Reset Manual via Kode
		if baris == "reset()":
			handle_reset_command()
			return

		if "input(" in baris and "=" in baris:
			var var_name = baris.split("=")[0].strip_edges()
			var prompt_text = ""
			if "input('" in baris:
				prompt_text = baris.split("input('")[1].split("')")[0]
			elif 'input("' in baris:
				prompt_text = baris.split('input("')[1].split('")')[0]
			
			if var_name:
				input_prompts.append({"var_name": var_name, "prompt": prompt_text})
	
	if input_prompts.size() > 0:
		execution_state = STATE_INPUT_NEEDED
		tampilkan_ui_input_prompt()
	else:
		# Jika tidak ada input, langsung eksekusi
		execution_state = STATE_EXECUTION_READY
		await proses_tahap_eksekusi()

# ---------------------------------
# TAHAP 2: Simpan Input User
# ---------------------------------
func proses_tahap_input_simpan_dan_siap_eksekusi():
	var input_user_lines = input_area.text.split("\n")
	collected_inputs.clear()
	var valid_input = true
	
	for i in range(input_prompts.size()):
		var prompt_data = input_prompts[i]
		var var_name = prompt_data.var_name
		var value_found = false
		var search_key = "(" + var_name + "):"
		
		for line in input_user_lines:
			if search_key in line:
				var parts = line.split(search_key)
				if parts.size() > 1:
					var raw_answer = parts[1].strip_edges()
					
					if (raw_answer.begins_with("'") and raw_answer.ends_with("'")) or (raw_answer.begins_with('"') and raw_answer.ends_with('"')):
						var clean_value = raw_answer.substr(1, raw_answer.length() - 2)
						collected_inputs[var_name] = clean_value.to_lower()
						value_found = true
					elif raw_answer == "":
						print("❌ Input Kosong untuk: " + var_name)
						valid_input = false
					else:
						print("❌ Error Input: " + raw_answer + " harus pakai kutip ('arah')")
						valid_input = false
				break
		
		if not value_found and valid_input:
			valid_input = false

	if not valid_input:
		execution_state = STATE_INPUT_NEEDED
		return
		
	execution_state = STATE_EXECUTION_READY
	tampilkan_ui_eksekusi_code()

# ---------------------------------
# TAHAP 3: Eksekusi Kode
# ---------------------------------
func proses_tahap_eksekusi():
	game_selesai = false 
	sedang_eksekusi = true
	memori_variabel.clear()
	
	for key in collected_inputs.keys():
		memori_variabel[key] = collected_inputs[key]

	var semua_baris = input_area.text.split("\n")
	var start_print_index = -1
	
	for i in range(semua_baris.size()):
		if "# --- PERINTAH ---" in semua_baris[i]:
			start_print_index = i + 1
			break
	
	if start_print_index != -1:
		var kode_eksekusi = semua_baris.slice(start_print_index)
		await eksekusi_blok_kode(kode_eksekusi)
	
	sedang_eksekusi = false
	GlobalAudio.stop_jalan()
	
	# Reset UI (Kembali ke Editor Mode)
	execution_state = STATE_CODE_READY
	input_area.text = original_code 
	input_area.editable = true
	
	if not game_selesai:
		atur_interaksi_tombol(true) 
		sprite_animasi.play("diam")
		
		# Fix Kursor
		await get_tree().process_frame
		input_area.grab_focus()
		input_area.caret_blink = false
		input_area.caret_blink = true
		input_area.set_caret_line(input_area.get_line_count() - 1)
		input_area.set_caret_column(input_area.get_line(input_area.get_line_count() - 1).length())
	else:
		atur_interaksi_tombol(false)

# ---------------------------------
# UI Helper Functions
# ---------------------------------
func tampilkan_ui_input_prompt():
	var new_text = "# --- MASUKKAN NILAI ARAH ---\n"
	for data in input_prompts:
		new_text += data.prompt + " (" + data.var_name + "): \n"
	
	input_area.text = new_text
	input_area.modulate = Color(0.8, 1.0, 0.8) 
	input_area.editable = true
	
	await get_tree().process_frame
	input_area.grab_focus()
	var target_line = 1 
	
	if target_line < input_area.get_line_count():
		input_area.set_caret_line(target_line)
		var panjang_teks = input_area.get_line(target_line).length()
		input_area.set_caret_column(panjang_teks)

func tampilkan_ui_eksekusi_code():
	var new_text = "# --- NILAI VARIABLE ---\n"
	for var_name in collected_inputs.keys():
		var value = collected_inputs[var_name]
		new_text += var_name + " = '" + value + "'\n"
	
	new_text += "\n# --- PERINTAH ---\n"
	var semua_baris = original_code.split("\n")
	var start_print = false
	for line in semua_baris:
		if "input(" in line:
			start_print = true 
			continue
		if start_print and line.strip_edges() != "":
			new_text += line + "\n"
	
	input_area.text = new_text.strip_edges()
	input_area.modulate = Color(1.0, 1.0, 1.0) 
	input_area.editable = false 

# ---------------------------------
# PARSER LINEAR
# ---------------------------------
func eksekusi_blok_kode(baris_kode: Array):
	for i in range(baris_kode.size()):
		if not sedang_eksekusi or game_selesai: return
		var baris = baris_kode[i].strip_edges()
		if baris == "" or baris.begins_with("#"): continue
		
		if baris == "reset()":
			handle_reset_command()
			return

		if "=" in baris and not "print" in baris:
			var parts = baris.split("=")
			var nama = parts[0].strip_edges()
			var isi = parts[1].strip_edges()
			if (isi.begins_with("'") and isi.ends_with("'")) or (isi.begins_with('"') and isi.ends_with('"')):
				memori_variabel[nama] = isi.substr(1, isi.length()-2).to_lower()
			else:
				print("❌ Error: Nilai variabel harus string.")
			continue
		
		if baris.begins_with("print"):
			await eksekusi_print(baris)

func eksekusi_print(baris: String):
	var jumlah_kali = 1
	var perintah_utama = baris
	if "*" in baris:
		var s = baris.split("*")
		perintah_utama = s[0].strip_edges()
		if s[1].strip_edges().is_valid_int(): jumlah_kali = int(s[1])

	if not perintah_utama.ends_with(")"):
		print("❌ Error Syntax: Kurang ')' -> ", baris)
		return
	
	if perintah_utama.begins_with("print("):
		var isi_raw = perintah_utama.split("print(")[1].split(")")[0].strip_edges()
		var nama_variabel = isi_raw
		
		if memori_variabel.has(nama_variabel):
			var arah = memori_variabel[nama_variabel]
			
			if arah in ["kanan", "kiri", "atas", "bawah"]:
				for k in range(jumlah_kali):
					if not sedang_eksekusi or game_selesai: break
					
					if not cek_apakah_tembok(arah):
						await gerakkan_player(arah)
					else:
						await aksi_nabrak(arah)
			else:
				print("❌ Error: Nilai variabel bukan arah valid.")
		else:
			var pakai_kutip = (isi_raw.begins_with("'") or isi_raw.begins_with('"'))
			if pakai_kutip:
				print("❌ Error: Dilarang print string langsung! Gunakan variabel.")
			else:
				print("❌ Error: Variabel " + nama_variabel + " tidak ditemukan.")

# ---------------------------------
# PHYSICS & SIGNALS
# ---------------------------------
func gerakkan_player(arah: String):
	if game_selesai: return
	var vec = Vector2.ZERO
	match arah:
		"kanan": vec = Vector2.RIGHT * 121
		"kiri":  vec = Vector2.LEFT * 121
		"atas":  vec = Vector2.UP * 88
		"bawah": vec = Vector2.DOWN * 88
		_: return 
	
	var flip = (arah == "kiri")
	var nama_anim = "jalan_kanan" if arah == "kanan" else "jalan_kiri" if arah == "kiri" else "jalan_atas" if arah == "atas" else "jalan_bawah"
	sprite_animasi.flip_h = flip
	if sprite_animasi.animation != nama_anim: sprite_animasi.play(nama_anim)
	
	GlobalAudio.play_jalan()
	var tween = create_tween()
	tween.tween_property(player, "position", player.position + vec, 0.5).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	GlobalAudio.stop_jalan()

func cek_apakah_tembok(arah: String) -> bool:
	var vec = Vector2.ZERO
	match arah:
		"kanan": vec = Vector2.RIGHT * 121
		"kiri":  vec = Vector2.LEFT * 121
		"atas":  vec = Vector2.UP * 88
		"bawah": vec = Vector2.DOWN * 88
	return player.move_and_collide(vec, true) != null

func aksi_nabrak(arah: String):
	var vec = Vector2.ZERO
	match arah:
		"kanan": vec = Vector2.RIGHT * 121
		"kiri":  vec = Vector2.LEFT * 121
		"atas":  vec = Vector2.UP * 88
		"bawah": vec = Vector2.DOWN * 88
	GlobalAudio.play_nabrak()
	var tween = create_tween()
	tween.tween_property(player, "position", player.position + (vec * 0.15), 0.1)
	tween.tween_property(player, "position", player.position, 0.1)
	await tween.finished

func setup_warna_kode():
	var h = CodeHighlighter.new()
	h.add_color_region("#", "", Color(0.3, 0.8, 0.3), true)
	h.add_keyword_color("input", Color("8be9fd"))
	h.add_keyword_color("print", Color("8be9fd"))
	h.add_keyword_color("reset", Color(1, 0.5, 0.5))
	input_area.syntax_highlighter = h

func atur_interaksi_tombol(aktif: bool):
	var f = Control.MOUSE_FILTER_STOP if aktif else Control.MOUSE_FILTER_IGNORE
	tombol_jalankan.mouse_filter = f
	tombol_kembali.mouse_filter = f
	tombol_petunjuk.mouse_filter = f
	var a = 1.0 if aktif else 0.5
	tombol_jalankan.modulate.a = a
	tombol_kembali.modulate.a = a
	tombol_petunjuk.modulate.a = a

# [FUNGSI RESET]
func handle_reset_command():
	reset_posisi_player()
	# Reset Text Area ke Default
	input_area.text = teks_petunjuk
	original_code = teks_petunjuk
	GlobalAudio.stop_jalan()
	GlobalAudio.play_click()

func reset_posisi_player():
	player.position = posisi_awal
	sprite_animasi.play("diam")
	memori_variabel.clear()
	collected_inputs.clear()
	input_prompts.clear()
	execution_state = STATE_CODE_READY
	input_area.modulate = Color(1, 1, 1)
	input_area.editable = true
	GlobalAudio.stop_jalan()
	game_selesai = false
	sedang_eksekusi = false
	atur_interaksi_tombol(true)

func _on_player_finish(body):
	if body.name == "karakter" and not game_selesai:
		print("🏆 MENANG!")
		GlobalAudio.stop_jalan()
		GlobalAudio.play_menang()
		game_selesai = true
		sedang_eksekusi = false
		sprite_animasi.play("diam")
		atur_interaksi_tombol(false) 
		input_area.editable = false
		await get_tree().create_timer(0.5).timeout
		ui_finish.visible = true

func _on_jalankan_pressed():
	if execution_state == STATE_EXECUTION_READY: atur_interaksi_tombol(false)
	var tween = create_tween()
	tween.tween_property(tombol_jalankan, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_jalankan, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	
	if execution_state == STATE_CODE_READY:
		reset_posisi_player()
		await get_tree().create_timer(0.2).timeout
		jalankan_kode_user()
	elif execution_state == STATE_INPUT_NEEDED:
		await get_tree().create_timer(0.2).timeout
		jalankan_kode_user()
	elif execution_state == STATE_EXECUTION_READY:
		await get_tree().create_timer(0.2).timeout
		jalankan_kode_user()
	
	if execution_state == STATE_CODE_READY and not game_selesai: 
		atur_interaksi_tombol(true)

func _on_lanjut_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_lanjut, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_lanjut, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://maps/inOut/view/level3.tscn")

func _on_ulangi_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_ulangi, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_ulangi, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	
	ui_finish.visible = false
	game_selesai = false
	
	# Reset Total
	reset_posisi_player()
	input_area.text = teks_petunjuk
	original_code = teks_petunjuk
	
	await get_tree().process_frame
	input_area.grab_focus()
	input_area.caret_blink = false
	input_area.caret_blink = true
	input_area.set_caret_line(input_area.get_line_count() - 1)
	input_area.set_caret_column(input_area.get_line(input_area.get_line_count() - 1).length())
	
	sprite_animasi.play("diam")

func _on_kembali_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_kembali, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_kembali, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	sedang_eksekusi = false
	GlobalAudio.stop_jalan()
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/inOut/inOut.tscn")

func _on_petunjuk_pressed():
	var tween = create_tween()
	tween.tween_property(tombol_petunjuk, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(tombol_petunjuk, "scale", Vector2(1.0, 1.0), 0.05)
	GlobalAudio.play_click()
	await get_tree().create_timer(0.2).timeout
	ui_petunjuk.visible = true
	atur_interaksi_tombol(false)  # Matikan tombol lain
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
		atur_interaksi_tombol(true)
		# Kembalikan edit text hanya jika sedang coding (bukan eksekusi)
		if execution_state != STATE_EXECUTION_READY:
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
