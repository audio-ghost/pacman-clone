extends Node2D

@onready var label: Label = $Label


func setup(points: int):
	label.text = str(points)
	if points >= 1000:
		label.modulate = Color.RED
		label.scale = Vector2(1.8, 1.8)
	elif points >= 600:
		label.modulate = Color.ORANGE
		label.scale = Vector2(1.5, 1.5)
	elif points >= 300:
		label.modulate = Color.YELLOW
		label.scale = Vector2(1.3, 1.3)
	animate()


func animate():
	var tween = create_tween()
	
	# Move up
	tween.tween_property(self, "position:y", position.y -40, 2.0)
	
	# Fade out
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	
	# Cleanup
	tween.tween_callback(queue_free)
