extends Control

@onready var start_label: Label = $StartLabel
@onready var pacman: AnimatedSprite2D = $"Attract Layer/Pacman"
@onready var ghosts := $"Attract Layer/Ghosts".get_children()

var attract_timer := 0.0
var phase := 0
var speed = 100


func _process(delta: float) -> void:
	start_label.visible = int(Time.get_ticks_msec() / 500) % 2 == 0
	
	attract_timer += delta
	if phase == 0 and attract_timer > 3:
		start_chase_sequence()
	elif phase == 1 and attract_timer > 13:
		start_frightened_sequence()

	if phase == 1:
		pacman.position.x += speed * delta
		for ghost in ghosts:
			ghost.position.x += speed * delta

	elif phase == 2:
		pacman.position.x -= speed * delta
		for ghost in ghosts:
			ghost.position.x -= speed * delta


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		GameManager.start_game()


func start_chase_sequence():
	phase = 1
	pacman.position = Vector2(-40, 300)
	pacman.rotation = Vector2.RIGHT.angle()
	
	var x_position = -120
	for ghost in ghosts:
		ghost.position = Vector2(x_position, 300)
		x_position -= 40


func start_frightened_sequence():
	phase = 2
	var x_position = 520
	for ghost in ghosts:
		ghost.position = Vector2(x_position, 300)
		x_position += 40
		ghost.setup_scared_animations()
	
	x_position += 40
	pacman.position = Vector2(x_position, 300)
	pacman.rotation = Vector2.LEFT.angle()
