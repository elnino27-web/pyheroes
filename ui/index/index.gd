extends Control

@onready var logo = $background/logo
@onready var tombol_bermain = $background/bermain
@onready var tombol_petunjuk = $background/petunjuk
@onready var tombol_keluar = $background/keluar
@onready var mobil = $background/mobil
@onready var mobil2 = $background/mobil2
@onready var mobil3 = $background/mobil3

var kecepatan = 100
var arah = Vector2.RIGHT

# ==========================
# 🔹 Gerakan Mobil Looping
# ==========================
func _process(delta):
	for m in [mobil, mobil2, mobil3]:
		m.position += arah * kecepatan * delta
		if m.position.x > 1000:
			m.position.x = -m.texture.get_size().x

# ==========================
# 🔹 Animasi Awal (Intro)
# ==========================
func _ready():
	# Sembunyikan dulu posisi awal
	logo.position.y = -200                     # Logo di atas layar
	logo.scale = Vector2(1, 1)
	
	for tombol in [tombol_bermain, tombol_petunjuk, tombol_keluar]:
		tombol.scale = Vector2(0, 0)           # Tombol mengecil jadi 0
	
	# Mulai animasi masuk
	animasi_masuk()

	# Hubungkan hover & klik tombol
	for b in [logo, tombol_bermain, tombol_petunjuk, tombol_keluar]:
		b.connect("mouse_entered", Callable(self, "_on_hover_entered").bind(b))
		b.connect("mouse_exited", Callable(self, "_on_hover_exited").bind(b))
	
	tombol_bermain.connect("pressed", Callable(self, "_on_bermain_pressed"))
	tombol_petunjuk.connect("pressed", Callable(self, "_on_petunjuk_pressed"))
	tombol_keluar.connect("pressed", Callable(self, "_on_keluar_pressed"))

# ==========================
# 🔸 Efek Hover
# ==========================
func _on_hover_entered(button):
	var tween = get_tree().create_tween()
	if button == logo:
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_hover_exited(button):
	var tween = get_tree().create_tween()
	tween.tween_property(button, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

# ==========================
# 🌟 Animasi Masuk (Intro)
# ==========================
func animasi_masuk():
	var tween = get_tree().create_tween()
	
	# Logo turun dari atas ke posisi semula
	tween.tween_property(logo, "position:y", logo.position.y + 270, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Setelah logo selesai, munculkan tombol satu per satu
	tween.tween_callback(Callable(self, "_animasi_tombol_masuk"))

func _animasi_tombol_masuk():
	var delay = 0.15
	var tween = get_tree().create_tween()
	
	var tombol_list = [tombol_bermain, tombol_petunjuk, tombol_keluar]
	for i in range(tombol_list.size()):
		tween.tween_property(tombol_list[i], "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * delay)

# ==========================
# 🔸 Aksi Tombol
# ==========================
func _on_bermain_pressed():
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu.tscn")

func _on_petunjuk_pressed():
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	print("Menampilkan petunjuk...")

func _on_keluar_pressed():
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/popup/poput_exit.tscn")
