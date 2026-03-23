extends Node2D

const GhostMode = GameConstants.GhostMode

@onready var player: CharacterBody2D = $Player
@onready var ghosts := $Ghosts.get_children()

@onready var lives_ui: CanvasLayer = $LivesUI
@onready var game_over_ui: CanvasLayer = $GameOverUI

var ghost_mode: GhostMode = GhostMode.SCATTER

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
var player_lives := 3


func _ready():
	player.died.connect(_on_player_died)
	game_over_ui.restart_requested.connect(_on_restart_requested)
	game_over_ui.exit_requested.connect(_on_exit_requested)
	lives_ui.set_lives(player_lives)


func _process(delta: float) -> void:
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
	for ghost in ghosts:
		ghost.enter_frightened(8.0)


func _on_player_died():
	player_lives -= 1
	
	lives_ui.lose_life(player_lives)
	
	if player_lives > 0:
		await get_tree().create_timer(2.0).timeout
		reset_level()
	else:
		game_over()


func reset_level():
	player.is_dead = false
	player.reset_to_start()
	
	for ghost in ghosts:
		ghost.reset_to_start(true)


func game_over():
	await get_tree().create_timer(1.0).timeout
	game_over_ui.show_game_over()


func _on_restart_requested():
	GameManager.restart_game()


func _on_exit_requested():
	GameManager.go_to_title()
