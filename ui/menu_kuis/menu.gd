extends Control

# ==========================
# 🔹 Referensi Node
# ==========================
@onready var papan_menu = $background/papanMenu
@onready var papan_materi = $background/papanMenu/papanMateri
@onready var tombol_variabel = $background/papanMenu/variabel
@onready var tombol_ifelse = $background/papanMenu/ifelse
@onready var tombol_looping = $background/papanMenu/looping
@onready var tombol_inout = $background/papanMenu/inout
@onready var tombol_kembali = $background/papanMenu/kembali
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
	papan_menu.position.y = -200                     # Papan Menu di atas layar
	papan_menu.scale = Vector2(1, 1)
	
	papan_materi.position.y = -200                     # Papan Materi di atas layar
	papan_materi.scale = Vector2(1, 1)
	
	for tombol in [tombol_variabel, tombol_ifelse, tombol_looping, tombol_inout, tombol_kembali]:
		tombol.scale = Vector2(0, 0)           # Tombol mengecil jadi 0
	
	# Mulai animasi masuk
	animasi_masuk()

	# Hubungkan hover & klik tombol
	for b in [tombol_variabel, tombol_ifelse, tombol_looping, tombol_inout, tombol_kembali]:
		b.connect("mouse_entered", Callable(self, "_on_hover_entered").bind(b))
		b.connect("mouse_exited", Callable(self, "_on_hover_exited").bind(b))
	
	tombol_variabel.connect("pressed", Callable(self, "_on_variabel_pressed"))
	tombol_ifelse.connect("pressed", Callable(self, "_on_ifelse_pressed"))
	tombol_looping.connect("pressed", Callable(self, "_on_looping_pressed"))
	tombol_inout.connect("pressed", Callable(self, "_on_inout_pressed"))
	tombol_kembali.connect("pressed", Callable(self, "_on_kembali_pressed"))

# ==========================
# 🔸 Efek Hover
# ==========================
func _on_hover_entered(button):
	var tween = get_tree().create_tween()
	if button == tombol_kembali:
		tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_hover_exited(button):
	var tween = get_tree().create_tween()
	tween.tween_property(button, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

# ==========================
# 🌟 Animasi Masuk (Intro)
# ==========================
func animasi_masuk():
	var tween = get_tree().create_tween()
	
	# Papan Menu turun dari atas ke posisi semula
	tween.tween_property(papan_menu, "position:y", papan_menu.position.y + 250, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(papan_materi, "position:y", papan_materi.position.y + 210, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Setelah Papan Menu dan Materi selesai, munculkan tombol satu per satu
	tween.tween_callback(Callable(self, "_animasi_tombol_masuk"))

func _animasi_tombol_masuk():
	var delay = 0.15
	var tween = get_tree().create_tween()
	
	var tombol_list = [tombol_variabel, tombol_ifelse, tombol_looping, tombol_inout, tombol_kembali]
	for i in range(tombol_list.size()):
		tween.tween_property(tombol_list[i], "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * delay)

func _on_variabel_pressed() -> void:
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/variabel/variabel.tscn")

func _on_ifelse_pressed() -> void:
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/if_else/if_else.tscn")

func _on_looping_pressed() -> void:
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/looping/looping.tscn")

func _on_inout_pressed() -> void:
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/input_output/input_output.tscn")

func _on_kembali_pressed() -> void:
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/index/index.tscn")
