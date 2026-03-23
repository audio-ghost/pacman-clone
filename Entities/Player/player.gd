extends CharacterBody2D

const TILE_SIZE = 16
const SPEED = 80.0
const MAZE_WIDTH = 30

var current_direction := Vector2.ZERO
var desired_direction := Vector2.ZERO
var target_position: Vector2
var visual_centered := false
var pellets_remaining := 0
var start_position: Vector2
var is_dead := false

@onready var maze = get_parent().get_node("MazeTileMap")
@onready var house_door = get_parent().get_node("DoorTileMap")
@onready var pellets = get_parent().get_node("PelletTileMap")
@onready var power_pellets = get_parent().get_node("PowerPelletTileMap")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

signal pellet_eaten
signal power_pellet_eaten
signal died
signal level_complete


func _ready() -> void:
	var cell = maze.local_to_map(position)
	position = maze.map_to_local(cell)
	target_position = position
	sprite.position.x -= TILE_SIZE / 2.0
	start_position = position
	
	pellets_remaining = count_remaining_pellets()
	
	add_to_group(GameConstants.GROUP_PLAYER)


func count_remaining_pellets() -> int:
	var total = 0
	for cell_pos in pellets.get_used_cells():
		if pellets.get_cell_source_id(cell_pos) != -1:
			total += 1
	
	for cell_pos in power_pellets.get_used_cells():
		if power_pellets.get_cell_source_id(cell_pos) != -1:
			total += 1
	
	return total


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_up"):
		desired_direction = Vector2.UP
	elif Input.is_action_just_pressed("ui_down"):
		desired_direction = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_left"):
		desired_direction = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		desired_direction = Vector2.RIGHT


func can_move(dir: Vector2) -> bool:
	var next_pos = target_position + dir * TILE_SIZE
	var cell = maze.local_to_map(next_pos)
	var source_id = maze.get_cell_source_id(cell)
	# First, check main maze layer (walls)
	if source_id != -1:
		return false  # blocked by wall
	# Now check door layer
	var door_source_id = house_door.get_cell_source_id(cell)
	if door_source_id != -1:
		return false  # blocked otherwise

	return true


func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		return
	if position.distance_to(target_position) < 1:
		position = target_position
		eat_pellet()
		handle_screen_wrap()
		if desired_direction != Vector2.ZERO and can_move(desired_direction):
			current_direction = desired_direction
			if current_direction != Vector2.ZERO:
				sprite.rotation = current_direction.angle()
				if not visual_centered:
					visual_centered = true
					var tween = create_tween()
					tween.tween_property(sprite, "position:x", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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


func eat_pellet():
	var cell = pellets.local_to_map(position)
	if pellets.get_cell_tile_data(cell) != null:
		pellets.erase_cell(cell)
		pellets_remaining -= 1
		GameManager.add_score(10)
		emit_signal("pellet_eaten")
	
	cell = power_pellets.local_to_map(position)
	if power_pellets.get_cell_tile_data(cell) != null:
		power_pellets.erase_cell(cell)
		pellets_remaining -= 1
		GameManager.add_score(50)
		emit_signal("power_pellet_eaten")
			
	if pellets_remaining <= 0:
		level_complete.emit()


func handle_screen_wrap():
	var cell = maze.local_to_map(position)

	if cell.x < 0:
		cell.x = MAZE_WIDTH - 1
	elif cell.x >= MAZE_WIDTH:
		cell.x = 0
	else:
		return

	position = maze.map_to_local(cell)
	target_position = position


func die():
	if is_dead:
		return
	
	is_dead = true
	died.emit()
	
	sprite.animation = "Die"
	sprite.play()


func reset_to_start():
	position = start_position
	target_position = position
	current_direction = Vector2.ZERO
	desired_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	
	sprite.animation = "Default"
	sprite.play()
