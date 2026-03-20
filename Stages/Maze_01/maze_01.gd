extends Node2D

const GhostMode = GameConstants.GhostMode

@onready var player: CharacterBody2D = $Player
@onready var ghosts := $Ghosts.get_children()

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

func _ready():
	player.died.connect(_on_player_died)


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
	await get_tree().create_timer(1.0).timeout
	reset_level()


func reset_level():
	player.is_dead = false
	player.reset_to_start()
	
	for ghost in ghosts:
		ghost.reset_to_start(true)
