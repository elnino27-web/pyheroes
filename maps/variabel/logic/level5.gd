extends Node

# ==========================
# 🔹 Referensi Node
# ==========================
@onready var tombol_jalankan = $map/run
@onready var tombol_kembali = $map/back
@onready var tombol_petunjuk = $map/tips

# ==========================
# 🔹 Animasi Awal (Intro)
# ==========================
func _ready():
	for tombol in [tombol_jalankan, tombol_kembali, tombol_petunjuk]:
		tombol.scale = Vector2(0, 0)           # Tombol mengecil jadi 0
	
	# Mulai animasi masuk
	_animasi_tombol_masuk()

	# Hubungkan hover & klik tombol
	for b in [tombol_jalankan, tombol_kembali, tombol_petunjuk]:
		b.connect("mouse_entered", Callable(self, "_on_hover_entered").bind(b))
		b.connect("mouse_exited", Callable(self, "_on_hover_exited").bind(b))
	
	tombol_jalankan.connect("pressed", Callable(self, "_on_jalankan_pressed"))
	tombol_kembali.connect("pressed", Callable(self, "_on_kembali_pressed"))
	tombol_petunjuk.connect("pressed", Callable(self, "_on_petunjuk_pressed"))

# ==========================
# 🔸 Efek Hover
# ==========================
func _on_hover_entered(button):
	var tween = get_tree().create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_hover_exited(button):
	var tween = get_tree().create_tween()
	tween.tween_property(button, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

# ==========================
# 🌟 Animasi Masuk (Intro)
# ==========================
func _animasi_tombol_masuk():
	var delay = 0.15
	var tween = get_tree().create_tween()
	
	var tombol_list = [tombol_jalankan, tombol_kembali, tombol_petunjuk]
	for i in range(tombol_list.size()):
		tween.tween_property(tombol_list[i], "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * delay)

func _on_jalankan_pressed() -> void:
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	print("run kode")

func _on_kembali_pressed() -> void:
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu_latihan/variabel/variabel.tscn")
