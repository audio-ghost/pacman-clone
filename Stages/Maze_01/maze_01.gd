extends Node2D

const GhostMode = GameConstants.GhostMode

@onready var player: CharacterBody2D = $Player
@onready var ghosts := $Ghosts.get_children()

@onready var maze_tile_map: TileMapLayer = $MazeTileMap
@onready var pellets: TileMapLayer = $PelletTileMap
@onready var power_pellets: TileMapLayer = $PowerPelletTileMap

@onready var score_ui: CanvasLayer = $ScoreUI
@onready var lives_ui: CanvasLayer = $LivesUI
@onready var pause_ui: CanvasLayer = $PauseUI
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var level_complete_ui: CanvasLayer = $LevelCompleteUI

@export var fruit_scene: PackedScene
@export var floating_text_scene: PackedScene

var ghost_mode: GhostMode = GhostMode.SCATTER

var ghost_score_values = [200, 400, 800, 1600]
var ghost_combo_index := 0

var mode_durations = [
	7.0,
	20.0,
	7.0,
	20.0,
	5.0,
	20.0,
	5.0
]

var total_pellets := 0
var pellets_remaining := 0
var fruit_spawned_1 := false
var fruit_spawned_2 := false

var mode_index := 0
var mode_timer := 0.0
var frightened_timer: SceneTreeTimer


func _ready():
	pellets_remaining = count_remaining_pellets()
	total_pellets = pellets_remaining
	
	player.moved_to_cell.connect(_on_player_moved)
	player.died.connect(_on_player_died)
	pause_ui.resume_requested.connect(_on_resume_requested)
	pause_ui.exit_requested.connect(_on_exit_requested)
	game_over_ui.restart_requested.connect(_on_restart_requested)
	game_over_ui.exit_requested.connect(_on_exit_requested)
	level_complete_ui.next_level_requested.connect(_on_next_level_requested)
	level_complete_ui.exit_requested.connect(_on_exit_requested)
	lives_ui.set_lives(GameManager.player_lives)
	for ghost in ghosts:
		ghost.ghost_eaten.connect(_on_ghost_eaten)
	
	get_tree().paused = false


func count_remaining_pellets() -> int:
	var total = 0
	for cell_pos in pellets.get_used_cells():
		if pellets.get_cell_source_id(cell_pos) != -1:
			total += 1
	
	for cell_pos in power_pellets.get_used_cells():
		if power_pellets.get_cell_source_id(cell_pos) != -1:
			total += 1
	
	return total


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if pause_ui.visible:
			return
		pause_game()
	if mode_index >= mode_durations.size():
		return
	
	mode_timer += delta
	
	if mode_timer >= mode_durations[mode_index]:
		mode_timer = 0
		mode_index += 1
		
		switch_mode()


func switch_mode():
	if ghost_mode == GhostMode.SCATTER:
		ghost_mode = GhostMode.CHASE
	else:
		ghost_mode = GhostMode.SCATTER
	for ghost in ghosts:
		ghost.set_mode(ghost_mode)


func _on_player_moved(cell: Vector2i):
	#var cell = pellets.local_to_map(position)
	if pellets.get_cell_tile_data(cell) != null:
		pellets.erase_cell(cell)
		pellets_remaining -= 1
		GameManager.add_score(10)
	#cell = power_pellets.local_to_map(position)
	if power_pellets.get_cell_tile_data(cell) != null:
		power_pellets.erase_cell(cell)
		pellets_remaining -= 1
		GameManager.add_score(50)
		power_pellet_eaten()
	
	var percent_remaining = float(pellets_remaining) / total_pellets
	if not fruit_spawned_1 and percent_remaining <= 0.7:
		spawn_fruit()
		fruit_spawned_1 = true
	if not fruit_spawned_2 and percent_remaining <= 0.3:
		spawn_fruit()
		fruit_spawned_2 = true
	
	if pellets_remaining <= 0:
		level_complete()


func power_pellet_eaten() -> void:
	_reset_ghost_combo_index()
	for ghost in ghosts:
		ghost.enter_frightened(8.0)
	if frightened_timer:
		frightened_timer.timeout.disconnect(_reset_ghost_combo_index)

	frightened_timer = get_tree().create_timer(8.0)
	frightened_timer.timeout.connect(_reset_ghost_combo_index)


func spawn_fruit():
	var fruit = fruit_scene.instantiate()
	
	var spawn_cell = Vector2i(16,23)
	fruit.position = maze_tile_map.map_to_local(spawn_cell)
	fruit.point_value = GameManager.get_fruit_score()
	
	add_child(fruit)
	
	fruit.collected.connect(_on_fruit_collected)
	
	get_tree().create_timer(10.0).timeout.connect(fruit.queue_free)


func _on_fruit_collected(points: int):
	GameManager.add_score(points)
	spawn_floating_text(points, player.position)


func spawn_floating_text(points: int, world_pos: Vector2):
	var text  = floating_text_scene.instantiate()
	text.position = world_pos
	add_child(text)
	
	text.setup(str(points))


func _reset_ghost_combo_index():
	ghost_combo_index = 0


func _on_ghost_eaten():
	var value = ghost_score_values[min(ghost_combo_index, ghost_score_values.size() -1)]
	GameManager.add_score(value)
	spawn_floating_text(value, player.position)
	
	ghost_combo_index += 1


func _on_player_died():
	GameManager.player_died()
	
	lives_ui.lose_life(GameManager.player_lives)
	
	if GameManager.player_lives > 0:
		await get_tree().create_timer(2.0).timeout
		reset_level()
	else:
		game_over()


func level_complete():
	get_tree().paused = true
	GameManager.save_game()
	level_complete_ui.show_level_complete()


func reset_level():
	player.is_dead = false
	player.reset_to_start()
	
	for ghost in ghosts:
		ghost.reset_to_start(true)


func game_over():
	GameManager.save_game()
	await get_tree().create_timer(1.0).timeout
	game_over_ui.show_game_over()


func pause_game():
	if player.is_dead:
		return
	if game_over_ui.visible:
		return
	get_tree().paused = true
	pause_ui.show_pause_overlay()


func _on_resume_requested():
	pause_ui.hide_pause_overlay()
	get_tree().paused = false


func _on_restart_requested():
	GameManager.restart_game()


func _on_next_level_requested():
	GameManager.go_to_next_level()


func _on_exit_requested():
	get_tree().paused = false
	GameManager.go_to_title()
