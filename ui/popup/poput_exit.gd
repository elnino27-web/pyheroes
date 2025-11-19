extends Control

# ==========================
# 🔹 Referensi Node
# ==========================
@onready var papan_confirm = $background/papanConfirm
@onready var tombol_keluar = $background/papanConfirm/keluar
@onready var tombol_batal = $background/papanConfirm/batal
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
	papan_confirm.position.y = -200                     # Papan Menu di atas layar
	papan_confirm.scale = Vector2(1, 1)
	
	for tombol in [tombol_batal, tombol_keluar]:
		tombol.scale = Vector2(0, 0)           # Tombol mengecil jadi 0
	
	# Mulai animasi masuk
	animasi_masuk()

	# Hubungkan hover & klik tombol
	for b in [tombol_batal, tombol_keluar]:
		b.connect("mouse_entered", Callable(self, "_on_hover_entered").bind(b))
		b.connect("mouse_exited", Callable(self, "_on_hover_exited").bind(b))
	
	tombol_batal.connect("pressed", Callable(self, "_on_batal_pressed"))
	tombol_keluar.connect("pressed", Callable(self, "_on_keluar_pressed"))

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
func animasi_masuk():
	var tween = get_tree().create_tween()
	
	# Papan Confirm turun dari atas ke posisi semula
	tween.tween_property(papan_confirm, "position:y", papan_confirm.position.y + 350, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Setelah Papan Confirm, munculkan tombol satu per satu
	tween.tween_callback(Callable(self, "_animasi_tombol_masuk"))

func _animasi_tombol_masuk():
	var delay = 0.15
	var tween = get_tree().create_tween()
	
	var tombol_list = [tombol_batal, tombol_keluar]
	for i in range(tombol_list.size()):
		tween.tween_property(tombol_list[i], "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * delay)

func _on_batal_pressed() -> void:
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/index/index.tscn")

func _on_keluar_pressed() -> void:
	click.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
