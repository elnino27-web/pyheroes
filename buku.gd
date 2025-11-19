extends Area2D

func _on_body_masuk(body: Node2D) -> void:
	print("dapat permata : " + body.name)
	if (body.name == "Player") :
		queue_free()
		pass 
	pass
