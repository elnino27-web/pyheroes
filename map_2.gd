extends Node2D

const kecepatan = 300
var arah = "diam"

@onready var karakter: CharacterBody2D = $karakter  # pastikan child bernama "player"
var target: Vector2 = Vector2.ZERO
var accel: float = 2000.0
func _physics_process(delta):
	gerak_karakter(delta)

func gerak_karakter(delta):
	# reset target tiap frame
	target = Vector2.ZERO

	# baca input (hold-to-move)
	if Input.is_action_pressed("kanan"):
		arah = "kanan"
		arah_karakter(true)
		target.x = kecepatan
	elif Input.is_action_pressed("kiri"):
		arah = "kiri"
		arah_karakter(true)
		target.x = -kecepatan
	elif Input.is_action_pressed("atas"):
		arah = "atas"
		arah_karakter(true)
		target.y = -kecepatan
	elif Input.is_action_pressed("bawah"):
		arah = "bawah"
		arah_karakter(true)
		target.y = kecepatan
	else:
		arah_karakter(false)
		# jangan set player.velocity = Vector2.ZERO di sini:
		# biarkan smoothing menurunkan velocity secara halus

	# **PENTING**: smoothing harus selalu dijalankan setiap frame
	karakter.velocity = karakter.velocity.move_toward(target, accel * delta)

	# jalankan physics pada player; berikan up_direction agar stabil (Vector2.UP)
	karakter.move_and_slide()

func arah_karakter(gerak):
	var arah_sekarang = arah
	var animasi = karakter.get_node("karaktermap2") as AnimatedSprite2D

	if arah_sekarang == "kanan":
		animasi.flip_h = false
		if gerak:
			animasi.play("jalan_kanan")
		else:
			animasi.play("diam")
	if arah_sekarang == "kiri":
		animasi.flip_h = true
		if gerak:
			animasi.play("jalan_kiri")
		else:
			animasi.play("diam")
	if arah_sekarang == "atas":
		if gerak:
			animasi.play("jalan_atas")
		else:
			animasi.play("diam")
	if arah_sekarang == "bawah":
		if gerak:
			animasi.play("jalan_bawah")
		else:
			animasi.play("diam")
