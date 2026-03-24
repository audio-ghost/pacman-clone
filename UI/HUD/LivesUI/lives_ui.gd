extends CanvasLayer

@onready var icons = [
	$PlayerLife1,
	$PlayerLife2,
	$PlayerLife3
]

func _ready():
	for icon in icons:
		icon.play("default")
		icon.frame = 0


func set_lives(count: int):
	for i in range(icons.size()):
		icons[i].visible = i < count


func lose_life(current_lives: int):
	var index = current_lives
	
	if index < icons.size():
		var icon = icons[index]
		icon.play("die")
		await icon.animation_finished
		icon.visible = false
