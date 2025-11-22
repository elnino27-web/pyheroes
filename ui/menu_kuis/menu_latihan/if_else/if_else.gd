extends Control

# ==========================
# 🔹 Referensi Node
# ==========================
@onready var papan_menu = $background/papanMenu
@onready var papan_ifelse = $background/papanMenu/papanIfelse
@onready var tombol_level1 = $background/papanMenu/level1
@onready var tombol_level2 = $background/papanMenu/level2
@onready var tombol_level3 = $background/papanMenu/level3
@onready var tombol_level4 = $background/papanMenu/level4
@onready var tombol_level5 = $background/papanMenu/level5
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
	
	papan_ifelse.position.y = -200
	papan_ifelse.scale = Vector2(1, 1)
	
	for tombol in [tombol_level1, tombol_level2, tombol_level3, tombol_level4, tombol_level5, tombol_kembali]:
		tombol.scale = Vector2(0, 0)           # Tombol mengecil jadi 0
	
	# Mulai animasi masuk
	animasi_masuk()

	# Hubungkan hover & klik tombol
	for b in [tombol_level1, tombol_level2, tombol_level3, tombol_level4, tombol_level5, tombol_kembali]:
		b.connect("mouse_entered", Callable(self, "_on_hover_entered").bind(b))
		b.connect("mouse_exited", Callable(self, "_on_hover_exited").bind(b))
	
	tombol_level1.connect("pressed", Callable(self, "_on_level1_pressed"))
	tombol_level2.connect("pressed", Callable(self, "_on_level2_pressed"))
	tombol_level3.connect("pressed", Callable(self, "_on_level3_pressed"))
	tombol_level4.connect("pressed", Callable(self, "_on_level4_pressed"))
	tombol_level5.connect("pressed", Callable(self, "_on_level5_pressed"))
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
	tween.tween_property(papan_ifelse, "position:y", papan_ifelse.position.y + 210, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Setelah Papan Menu dan Materi selesai, munculkan tombol satu per satu
	tween.tween_callback(Callable(self, "_animasi_tombol_masuk"))

func _animasi_tombol_masuk():
	var delay = 0.15
	var tween = get_tree().create_tween()
	
	var tombol_list = [tombol_level1, tombol_level2, tombol_level3, tombol_level4, tombol_level5, tombol_kembali]
	for i in range(tombol_list.size()):
		tween.tween_property(tombol_list[i], "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * delay)

func _on_level1_pressed() -> void:
	GlobalAudio.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://maps/ifElse/view/level1.tscn")

func _on_level2_pressed() -> void:
	GlobalAudio.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://maps/ifElse/view/level2.tscn")

func _on_level3_pressed() -> void:
	GlobalAudio.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://maps/ifElse/view/level3.tscn")

func _on_level4_pressed() -> void:
	GlobalAudio.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://maps/ifElse/view/level4.tscn")

func _on_level5_pressed() -> void:
	GlobalAudio.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://maps/ifElse/view/level5.tscn")

func _on_kembali_pressed() -> void:
	GlobalAudio.play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://ui/menu_kuis/menu.tscn")
