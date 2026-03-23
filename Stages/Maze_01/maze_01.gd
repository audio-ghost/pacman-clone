extends Node2D

const GhostMode = GameConstants.GhostMode

@onready var player: CharacterBody2D = $Player
@onready var ghosts := $Ghosts.get_children()

@onready var score_ui: CanvasLayer = $ScoreUI
@onready var lives_ui: CanvasLayer = $LivesUI
@onready var pause_ui: CanvasLayer = $PauseUI
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var level_complete_ui: CanvasLayer = $LevelCompleteUI

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

var mode_index := 0
var mode_timer := 0.0
var frightened_timer: SceneTreeTimer


func _ready():
	player.died.connect(_on_player_died)
	player.level_complete.connect(_on_level_complete)
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


func _on_player_power_pellet_eaten() -> void:
	_reset_ghost_combo_index()
	for ghost in ghosts:
		ghost.enter_frightened(8.0)
	if frightened_timer:
		frightened_timer.timeout.disconnect(_reset_ghost_combo_index)

	frightened_timer = get_tree().create_timer(8.0)
	frightened_timer.timeout.connect(_reset_ghost_combo_index)


func _reset_ghost_combo_index():
	ghost_combo_index = 0


func _on_ghost_eaten():
	var value = ghost_score_values[min(ghost_combo_index, ghost_score_values.size() -1)]
	GameManager.add_score(value)
	
	ghost_combo_index += 1


func _on_player_died():
	GameManager.player_died()
	
	lives_ui.lose_life(GameManager.player_lives)
	
	if GameManager.player_lives > 0:
		await get_tree().create_timer(2.0).timeout
		reset_level()
	else:
		game_over()


func _on_level_complete():
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
