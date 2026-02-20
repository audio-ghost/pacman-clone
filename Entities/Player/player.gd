extends CharacterBody2D

const TILE_SIZE = 16
const SPEED = 80.0

var current_direction := Vector2.ZERO
var desired_direction := Vector2.ZERO

var target_position: Vector2

@onready var maze = get_parent().get_node("TileMapLayer")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	var cell = maze.local_to_map(position)
	position = maze.map_to_local(cell)
	target_position = position

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_up"):
		desired_direction = Vector2.UP
	elif Input.is_action_just_pressed("ui_down"):
		desired_direction = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_left"):
		desired_direction = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		desired_direction = Vector2.RIGHT
		
func is_at_tile_center() -> bool:
	print("positionX:", position.x, "positionY:", position.y)
	var remainder_x = fmod(position.x, TILE_SIZE)
	var remainder_y = fmod(position.y, TILE_SIZE)
	return abs(remainder_x) < 0.1 and abs(remainder_y) < 0.1

func can_move(dir: Vector2) -> bool:
	var next_pos = target_position + dir * TILE_SIZE
	var cell = maze.local_to_map(next_pos)
	var source_id = maze.get_cell_source_id(cell)
	# -1 means empty
	if source_id == -1:
		return true
	# Any tile present blocks movement
	return false

func _physics_process(delta):
	if position.distance_to(target_position) < 1:
		position = target_position
		if desired_direction != Vector2.ZERO and can_move(desired_direction):
			current_direction = desired_direction
			if current_direction != Vector2.ZERO:
				animated_sprite_2d.rotation = current_direction.angle()
		if not can_move(current_direction):
			current_direction = Vector2.ZERO
		if current_direction != Vector2.ZERO:
			target_position += current_direction * TILE_SIZE
	
	if position != target_position:
		var step = SPEED * delta
		var distance = position.distance_to(target_position)

		if step >= distance:
			position = target_position
		else:
			position += (target_position - position).normalized() * step
	else:
		velocity = Vector2.ZERO
