extends CharacterBody2D

signal ghost_eaten(position)

const GhostMode = GameConstants.GhostMode
const GhostState = GameConstants.GhostState
const Personality = GameConstants.Personality
const ScatterPoint = GameConstants.ScatterPoint

const TILE_SIZE = 16
const DEFAULT_SPEED = 70.0
const MAZE_WIDTH = 30
const MAZE_TOP = 8
const MAZE_BOTTOM = 37
const AMBUSH_TILES_AHEAD = 4

var ghost_speed := 0.0
var frightened_timer := 0.0
var chameleon_personality: Personality

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
var house_inside_tile := Vector2(16, 20)

@export var personality: Personality = Personality.CHASER
@export var scatter_point: ScatterPoint = ScatterPoint.TOP_LEFT
var state: GhostState = GhostState.IN_HOUSE

var float_amplitude: float = 3.0
var float_speed: float = 1.0
var float_phase: float = 0.0
var float_time: float = 0.0
var start_position: Vector2

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var face_sprite: AnimatedSprite2D = $FaceSprite
@onready var hitbox: Area2D = $Hitbox

@onready var maze_map = get_parent().get_parent().get_node("MazeTileMap")
@onready var house_door = get_parent().get_parent().get_node("DoorTileMap")
@onready var pacman = get_parent().get_parent().get_node("Player")
@onready var house = get_parent().get_parent().get_node("GhostHouse")
@onready var house_area = get_parent().get_parent().get_node("GhostHouse/HouseArea")
@onready var house_exit_point = get_parent().get_parent().get_node("HouseExitPoint")
@onready var restart_point = get_parent().get_parent().get_node("RestartPoint")

@onready var patrol_timer: Timer

var ghost_mode: GhostMode = GhostMode.SCATTER

func _ready():
	var cell = maze_map.local_to_map(position)
	position = maze_map.map_to_local(cell)
	target_position = position
	ghost_speed = level_adjusted_default_speed()
	start_position = position
	
	body_base_position = body_sprite.position
	face_base_position = face_sprite.position
	float_phase = randf() * TAU
	
	hitbox.body_entered.connect(_on_body_entered)
	house.register_ghost(self)
	house_exit_point.body_entered.connect(_on_house_exit_point_entered)
	restart_point.body_entered.connect(_on_restart_point_entered)
	setup_ghost_by_personality()


func level_adjusted_default_speed() -> float:
	return DEFAULT_SPEED * GameManager.ghost_speed_multiplier()

func setup_ghost_by_personality():
	# Convert enum to string for animation/texture paths
	body_sprite.animation = get_body_animation_name()
	body_sprite.play()
	body_sprite.visible = true
	face_sprite.animation = get_face_animation_name()
	face_sprite.play()
	face_sprite.visible = true
	
	var match_personality = personality
	if match_personality == Personality.CHAMELEON:
		chameleon_personality = get_random_personality()
		match_personality = chameleon_personality
	match match_personality:
		Personality.CHASER:
			ghost_speed = level_adjusted_default_speed()
		Personality.AMBUSHER:
			ghost_speed = level_adjusted_default_speed()
		Personality.RANDOM:
			ghost_speed = level_adjusted_default_speed() * 0.8
		Personality.PATROL:
			ghost_speed = level_adjusted_default_speed() * 0.7
			choose_new_patrol_target()
			patrol_timer = Timer.new()
			patrol_timer.wait_time = 10.0
			patrol_timer.one_shot = false
			patrol_timer.timeout.connect(choose_new_patrol_target)
			add_child(patrol_timer)
			patrol_timer.start()
		Personality.HUNTER:
			ghost_speed = level_adjusted_default_speed() * 0.7
		Personality.STATUE:
			ghost_speed = level_adjusted_default_speed() * 0.4
		Personality.CHAMELEON:
			ghost_speed = level_adjusted_default_speed()
		Personality.SCAREDYCAT:
			ghost_speed = level_adjusted_default_speed()


func get_random_personality():
	var options = [
		Personality.CHASER,
		Personality.AMBUSHER,
		Personality.RANDOM,
		Personality.PATROL
	]
	chameleon_personality = options.pick_random()


func get_body_animation_name() -> String:
	match personality:
		Personality.CHASER: return "default_red"
		Personality.AMBUSHER: return "default_blue"
		Personality.RANDOM: return "default_pink"
		Personality.PATROL: return "default_yellow"
		Personality.HUNTER: return "default_orange"
		Personality.STATUE: return "default_grey"
		Personality.CHAMELEON: return "default_green"
		Personality.SCAREDYCAT: return "default_purple"
	return "default_blue"


func get_face_animation_name() -> String:
	var options = ["face_1", "face_2", "face_3", "face_4", "face_5", "face_6", "face_7", "face_8"]
	return options.pick_random()


func _physics_process(delta):
	if position.distance_to(target_position) < 1:
		position = target_position
		choose_direction()
		update_face_position()
		target_position += current_direction * TILE_SIZE

	if state == GhostState.FRIGHTENED:
		update_frightened_flash()
		frightened_timer -= delta
		if frightened_timer <= 0:
			exit_frightened()

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


func update_frightened_flash():
	# TODO - Replace with alternating between white and blue frightened animations
	if frightened_timer < 3.0:
		@warning_ignore("integer_division")
		body_sprite.visible = int(Time.get_ticks_msec() / 200) % 2 == 0
	else:
		body_sprite.visible = true


func update_face_position():
	if state == GhostState.FRIGHTENED:
		return
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
			choose_target_direction(maze_map.map_to_local(house_outside_tile))
		GhostState.ACTIVE:
			if ghost_mode == GhostMode.SCATTER:
				choose_target_direction(maze_map.map_to_local(get_scatter_target()))
			else:
				var match_personality = personality
				if match_personality == Personality.CHAMELEON:
					match_personality = chameleon_personality
				match personality:
					Personality.RANDOM:
						choose_random_direction()
					Personality.CHASER:
						choose_target_direction(pacman.position)
					Personality.AMBUSHER:
						choose_target_direction(get_ambush_target())
					Personality.PATROL:
						choose_target_direction(maze_map.map_to_local(patrol_target))
		GhostState.FRIGHTENED:
			choose_flee_direction(pacman.position)
		GhostState.EATEN:
			choose_target_direction(maze_map.map_to_local(house_inside_tile))


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
	var pacman_tile = maze_map.local_to_map(pacman.position)
	if pacman.current_direction == Vector2.ZERO:
		return maze_map.map_to_local(pacman_tile)
	var direction := Vector2i(pacman.current_direction)
	var target_tile = pacman_tile + direction * AMBUSH_TILES_AHEAD
	# If target tile outside of maze bounds, return pacman's position
	if target_tile.x < 0 or target_tile.x >= MAZE_WIDTH or target_tile.y < MAZE_TOP or target_tile.y >= MAZE_BOTTOM:
		return maze_map.map_to_local(pacman_tile)
	return maze_map.map_to_local(target_tile)


func get_scatter_target():
	match scatter_point:
		ScatterPoint.TOP_LEFT:
			return Vector2i(3, 9)
		ScatterPoint.TOP_RIGHT:
			return Vector2i(28, 9)
		ScatterPoint.BOTTOM_LEFT:
			return Vector2i(3, 33)
		ScatterPoint.BOTTOM_RIGHT:
			return Vector2i(28, 33)


func choose_flee_direction(target: Vector2):
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
		
		if distance > shortest_distance:
			shortest_distance = distance
			best_direction = dir
	
	current_direction = best_direction


func can_move(dir: Vector2) -> bool:
	var next_pos = target_position + dir * TILE_SIZE
	var cell = maze_map.local_to_map(next_pos)
	var source_id = maze_map.get_cell_source_id(cell)
	
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
	if not body.is_in_group(GameConstants.GROUP_PLAYER):
		return
	
	if body.is_dead:
		return
	
	if state == GhostState.FRIGHTENED:
		enter_eaten()
	elif state == GhostState.EATEN:
		pass
	else:
		body.die()


func _on_house_exit_point_entered(body):
	if body == self and state == GhostState.EXITING:
		state = GhostState.ACTIVE


func _on_restart_point_entered(body):
	if body == self and state == GhostState.EATEN:
		reset_to_start(false)


func enter_frightened(duration: float):
	if state != GhostState.ACTIVE and state != GhostState.FRIGHTENED:
		return
	
	state = GhostState.FRIGHTENED
	frightened_timer = duration
	ghost_speed = level_adjusted_default_speed() * 0.5
	reverse_direction()
	set_frightened_sprite()


func set_frightened_sprite():
	body_sprite.animation = "scared_blue"
	body_sprite.play()
	face_sprite.visible = false


func exit_frightened():
	state = GhostState.ACTIVE
	reverse_direction()
	setup_ghost_by_personality()


func enter_eaten():
	state = GhostState.EATEN
	set_eaten_sprite()
	reverse_direction()
	ghost_speed = level_adjusted_default_speed() * 1.5
	ghost_eaten.emit(position)


func set_eaten_sprite():
	body_sprite.animation = "eaten"
	body_sprite.set_frame_and_progress(randi() % 8, 0)
	body_sprite.pause()
	body_sprite.visible = true
	face_sprite.visible = false


func reverse_direction():
	current_direction = -current_direction


func set_mode(mode):
	if state != GhostState.ACTIVE:
		return
	ghost_mode = mode


func reset_to_start(include_position: bool):
	state = GhostState.IN_HOUSE
	if include_position:
		position = start_position
		target_position = position
		current_direction = Vector2.ZERO
	
	house.register_ghost(self)
	setup_ghost_by_personality()
	frightened_timer = 0
