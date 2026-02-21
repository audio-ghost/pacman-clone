extends CharacterBody2D

# Body color options
enum BodyColor { BLUE, GREEN, GREY, ORANGE, PINK, PURPLE, RED, YELLOW }

# Face options
enum FaceStyle { FACE_1, FACE_2, FACE_3, FACE_4, FACE_5, FACE_6, FACE_7, FACE_8 }

# Ghost personality options
enum Personality { CHASER, AMBUSHER, RANDOM, SLOW }

const TILE_SIZE = 16
const SPEED = 70.0

var current_direction := Vector2.ZERO
var target_position: Vector2
var body_base_position: Vector2
var face_base_position: Vector2

@export var body_color: BodyColor = BodyColor.RED
@export var face_style: FaceStyle = FaceStyle.FACE_1
@export var personality: Personality = Personality.CHASER
var float_amplitude: float = 2.0
var float_speed: float = 1.0
var float_phase: float = 0.0
var float_time: float = 0.0

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var face_sprite: AnimatedSprite2D = $FaceSprite
@onready var hitbox: Area2D = $Hitbox

@onready var maze = get_parent().get_node("MazeTileMap")

func _ready():
	var cell = maze.local_to_map(position)
	position = maze.map_to_local(cell)
	target_position = position
	
	body_base_position = body_sprite.position
	face_base_position = face_sprite.position
	float_phase = randf() * TAU
	
	# Convert enum to string for animation/texture paths
	body_sprite.animation = get_body_animation_name()
	body_sprite.play()
	face_sprite.animation = get_face_animation_name()
	face_sprite.play()
	
	hitbox.body_entered.connect(_on_body_entered)

func get_body_animation_name() -> String:
	match body_color:
		BodyColor.BLUE: return "default_blue"
		BodyColor.GREEN: return "default_green"
		BodyColor.GREY: return "default_grey"
		BodyColor.ORANGE: return "default_orange"
		BodyColor.PINK: return "default_pink"
		BodyColor.PURPLE: return "default_purple"
		BodyColor.RED: return "default_red"
		BodyColor.YELLOW: return "default_yellow"
	return "default_blue"
	
func get_face_animation_name() -> String:
	match face_style:
		FaceStyle.FACE_1: return "face_1"
		FaceStyle.FACE_2: return "face_2"
		FaceStyle.FACE_3: return "face_3"
		FaceStyle.FACE_4: return "face_4"
		FaceStyle.FACE_5: return "face_5"
		FaceStyle.FACE_6: return "face_6"
		FaceStyle.FACE_7: return "face_7"
		FaceStyle.FACE_8: return "face_8"
	return "face_1"

func _physics_process(_delta):
	if position.distance_to(target_position) < 1:
		position = target_position
		choose_direction()
		update_face_position()
		target_position += current_direction * TILE_SIZE

	if position != target_position:
		var direction = (target_position - position).normalized()
		velocity = direction * SPEED
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		
func _process(delta):
	float_time += delta
	# Calculate vertical float offset
	var float_y = sin(float_time * float_speed * TAU + float_phase) * float_amplitude
	# Apply to both body and face sprites
	body_sprite.position.y = body_base_position.y + float_y
	face_sprite.position.y = face_base_position.y + float_y

func update_face_position():
	var x_offset := 0
	match current_direction:
		Vector2.LEFT:
			x_offset = -2
			face_sprite.visible = true
		Vector2.RIGHT:
			x_offset = 2
			face_sprite.visible = true
		Vector2.DOWN:
			x_offset = 0
			face_sprite.visible = true
		Vector2.UP:
			x_offset = 0
			face_sprite.visible = false
	face_sprite.position.x = face_base_position.x + x_offset

func choose_direction():
	# Simple random choice for now
	var options = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	options = options.filter(can_move)
	if options.size() > 0:
		current_direction = options[randi() % options.size()]
	else:
		current_direction = -current_direction  # reverse if stuck

func can_move(dir: Vector2) -> bool:
	var next_pos = target_position + dir * TILE_SIZE
	var cell = maze.local_to_map(next_pos)
	var source_id = maze.get_cell_source_id(cell)
	# -1 means empty
	if source_id == -1:
		return true
	# Any tile present blocks movement
	return false

func _on_body_entered(body):
	if body.name == "Player":
		print("Pacman Caught!")
