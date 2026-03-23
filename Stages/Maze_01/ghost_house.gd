extends Node2D

@export var release_delay := 3.0

var ghosts_in_queue: Array = []
var can_release := true

func register_ghost(ghost):
	ghosts_in_queue.append(ghost)

func _process(_delta):
	if can_release and ghosts_in_queue.size() > 0:
		release_next()

func release_next():
	can_release = false

	var ghost = ghosts_in_queue.pop_front()
	ghost.state = ghost.GhostState.EXITING

	await get_tree().create_timer(release_delay).timeout

	can_release = true
