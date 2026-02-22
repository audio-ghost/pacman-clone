extends CharacterBody2D

enum BodyColor { BLUE, GREEN, GREY, ORANGE, PINK, PURPLE, RED, YELLOW }
enum FaceStyle { FACE_1, FACE_2, FACE_3, FACE_4, FACE_5, FACE_6, FACE_7, FACE_8 }
enum Personality { CHASER, AMBUSHER, RANDOM, SLOW }
enum GhostState { IN_HOUSE, EXITING, ACTIVE, SCARED, EATEN }

const TILE_SIZE = 16
const DEFAULT_SPEED = 70.0
const MAZE_WIDTH = 30
const MAZE_TOP = 8
const MAZE_BOTTOM = 37
const AMBUSH_TILES_AHEAD = 4

var ghost_speed := 0.0

var patrol_target: Vector2i
var patrol_points = [
	Vector2i(8, 12),
	Vector2i(23, 12),
	Vector2i(8, 30),
	Vector2i(23, 30)
]

var current_direction := Vector2.ZERO
var target_position: Vector2
var body_base_position: Vector2
var face_base_position: Vector2

var house_outside_tile := Vector2(16, 18)

@export var body_color: BodyColor = BodyColor.RED
@export var face_style: FaceStyle = FaceStyle.FACE_1
@export var personality: Personality = Personality.CHASER
var state: GhostState = GhostState.IN_HOUSE

var float_amplitude: float = 3.0
var float_speed: float = 1.0
var float_phase: float = 0.0
var float_time: float = 0.0

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var face_sprite: AnimatedSprite2D = $FaceSprite
@onready var hitbox: Area2D = $Hitbox

@onready var maze = get_parent().get_node("MazeTileMap")
@onready var house_door = get_parent().get_node("DoorTileMap")
@onready var pacman = get_parent().get_node("Player")
@onready var house = get_parent().get_node("GhostHouse")
@onready var house_area = get_parent().get_node("GhostHouse/HouseArea")

@onready var patrol_timer := Timer.new()

func _ready():
	house_outside_tile = maze.map_to_local(Vector2(16, 18))
	var cell = maze.local_to_map(position)
	position = maze.map_to_local(cell)
	target_position = position
	ghost_speed = DEFAULT_SPEED
	
	body_base_position = body_sprite.position
	face_base_position = face_sprite.position
	float_phase = randf() * TAU
	
	# Convert enum to string for animation/texture paths
	body_sprite.animation = get_body_animation_name()
	body_sprite.play()
	face_sprite.animation = get_face_animation_name()
	face_sprite.play()
	
	hitbox.body_entered.connect(_on_body_entered)
	house.register_ghost(self)
	house_area.body_exited.connect(_on_house_exited)
	if personality == Personality.RANDOM:
		ghost_speed = DEFAULT_SPEED * 0.8
	if personality == Personality.SLOW:
		ghost_speed = DEFAULT_SPEED * 0.6
		choose_new_patrol_target()
		patrol_timer.wait_time = 10.0
		patrol_timer.one_shot = false
		patrol_timer.timeout.connect(choose_new_patrol_target)
		add_child(patrol_timer)
		patrol_timer.start()

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
	
	if state == GhostState.EXITING and position == house_outside_tile:
		state = GhostState.ACTIVE

	if position != target_position:
		var direction = (target_position - position).normalized()
		velocity = direction * ghost_speed
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
	match state:
		GhostState.IN_HOUSE:
			in_house_patrol()
		GhostState.EXITING:
			choose_target_direction(house_outside_tile)
		GhostState.ACTIVE:
			match personality:
				Personality.RANDOM:
					choose_random_direction()
				Personality.CHASER:
					choose_target_direction(pacman.position)
				Personality.AMBUSHER:
					choose_target_direction(get_ambush_target())
				Personality.SLOW:
					choose_target_direction(maze.map_to_local(patrol_target))

func in_house_patrol():
	var options = [Vector2.LEFT, Vector2.RIGHT]
	options = options.filter(can_move)
	
	options.erase(-current_direction)
	if options.is_empty():
		current_direction = -current_direction
		return
	
	current_direction = options[randi() % options.size()]

func choose_random_direction():
	var options = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	options = options.filter(can_move)
	
	options.erase(-current_direction)
	if options.is_empty():
		current_direction = -current_direction
		return
	
	current_direction = options[randi() % options.size()]


func choose_target_direction(target: Vector2):
	var options = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	options = options.filter(can_move)
	
	# Prevents immediate reversal unless stuck
	options.erase(-current_direction)
	if options.is_empty():
		current_direction = -current_direction
		return
	
	var best_direction = options[0]
	var shortest_distance = INF
	
	for dir in options:
		var next_pos = target_position + dir * TILE_SIZE
		var distance = next_pos.distance_to(target)
		
		if distance < shortest_distance:
			shortest_distance = distance
			best_direction = dir
	
	current_direction = best_direction

func get_ambush_target() -> Vector2:
	var pacman_tile = maze.local_to_map(pacman.position)
	if pacman.current_direction == Vector2.ZERO:
		return maze.map_to_local(pacman_tile)
	var direction := Vector2i(pacman.current_direction)
	var target_tile = pacman_tile + direction * AMBUSH_TILES_AHEAD
	# If target tile outside of maze bounds, return pacman's position
	if target_tile.x < 0 or target_tile.x >= MAZE_WIDTH or target_tile.y < MAZE_TOP or target_tile.y >= MAZE_BOTTOM:
		return maze.map_to_local(pacman_tile)
	return maze.map_to_local(target_tile)
	
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
		# Only allow ghosts in certain states to pass
		if state in [GhostState.EXITING, GhostState.EATEN]:
			return true
		return false  # blocked otherwise
	return true

func choose_new_patrol_target():
	patrol_target = patrol_points.pick_random()

func _on_body_entered(body):
	if body.name == "Player":
		print("Pacman Caught!")
		
func _on_house_exited(body):
	if body == self and state == GhostState.EXITING:
		state = GhostState.ACTIVE
