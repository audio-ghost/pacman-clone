extends ColorRect

@export var background_color: Color = Color(0.02, 0.02, 0.08)


func _ready():
	color = background_color
