extends Node2D

var in_goal = false

func _on_body_entered(body):
	if body.name == "Goal":
		in_goal = true
		get_tree().call_group("UI", "show_message", "GOAL! Kamu menang!")
