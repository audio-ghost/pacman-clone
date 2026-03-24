extends Node2D

@onready var label: Label = $Label


func setup(text: String):
	label.text = text
	animate()


func animate():
	var tween = create_tween()
	
	# Move up
	tween.tween_property(self, "position:y", position.y -40, 2.0)
	
	# Fade out
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	
	# Cleanup
	tween.tween_callback(queue_free)
