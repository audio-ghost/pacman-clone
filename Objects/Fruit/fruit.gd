extends Area2D

var fruit_regions = {
	"cherry": Rect2(0, 0, 16, 16),
	"strawberry": Rect2(16, 0, 16, 16),
	"orange": Rect2(32, 0, 16, 16),
	"apple": Rect2(48, 0, 16, 16),
}

@export var point_value := 100

signal collected(points, position)

@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var options = ["cherry", "strawberry", "orange", "apple"]
	set_fruit_type(options.pick_random())
	
	scale = Vector2.ZERO
	pop_in()


func _on_body_entered(body):
	if body.is_in_group(GameConstants.GROUP_PLAYER):
		collected.emit(point_value, position)
		queue_free()


func set_fruit_type(type: String):
	var atlas = AtlasTexture.new()
	atlas.atlas = preload("res://Objects/Fruit/Art/Items.png")
	atlas.region = fruit_regions[type]
	
	sprite_2d.texture = atlas


func pop_in():
	var tween = create_tween()
	# Scale up past 1 (bounce)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	# Settle back to 1
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
