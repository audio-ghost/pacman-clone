extends Node2D

enum GhostColor {
	RED,
	BLUE,
	YELLOW,
	PINK
} 

@export var ghost_color : GhostColor = GhostColor.RED

var float_time := 0.0
var float_phase := randf() * TAU

var float_amplitude := 2.0
var float_speed := 1.0

var base_body_pos: Vector2
var base_face_pos: Vector2

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var face_sprite: AnimatedSprite2D = $FaceSprite

func _ready():
	base_body_pos = body_sprite.position
	base_face_pos = face_sprite.position

	setup_default_animations()


func setup_default_animations():
	match ghost_color:
		GhostColor.RED:
			body_sprite.play("default_red")
			face_sprite.play("face_5")
		GhostColor.BLUE:
			body_sprite.play("default_blue")
			face_sprite.play("face_8")
		GhostColor.YELLOW:
			body_sprite.play("default_yellow")
			face_sprite.play("face_6")
		GhostColor.PINK:
			body_sprite.play("default_pink")
			face_sprite.play("face_3")


func setup_scared_animations():
	body_sprite.play("scared_blue")
	face_sprite.hide()


func _process(delta):
	float_time += delta

	var float_y = sin(float_time * float_speed * TAU + float_phase) * float_amplitude

	body_sprite.position.y = base_body_pos.y + float_y
	face_sprite.position.y = base_face_pos.y + float_y
