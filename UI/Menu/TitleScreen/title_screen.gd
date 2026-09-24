extends Control

@onready var start_label: Label = $StartLabel
@onready var high_score_label: Label = $HBoxContainer/HighScoreLabel
@onready var pacman: AnimatedSprite2D = $"Attract Layer/Pacman"
@onready var ghosts := $"Attract Layer/Ghosts".get_children()
@onready var player: AudioStreamPlayer = $AudioStreamPlayer
@onready var blink_timer: Timer = $BlinkTimer

var music = preload("res://UI/Menu/TitleScreen/Sound/Retro Music - ABMU - ChipWave 01.wav")

var attract_timer := 0.0
var phase := 0
var speed = 100


func _ready():
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	high_score_label.text = "%06d" % GameManager.high_score
	player.stream = music
	player.play()


func _process(delta: float) -> void:
	attract_timer += delta
	if phase == 0 and attract_timer > 3:
		start_chase_sequence()
	elif phase == 1 and attract_timer > 13:
		start_frightened_sequence()
	elif phase == 2 and attract_timer > 30:
		reset_animation_sequence()

	if phase == 1:
		pacman.position.x += speed * delta
		for ghost in ghosts:
			ghost.position.x += speed * delta

	elif phase == 2:
		pacman.position.x -= speed * delta
		for ghost in ghosts:
			ghost.position.x -= speed * delta


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ACCEPT"):
		GameManager.start_game()


func start_chase_sequence():
	phase = 1
	pacman.position = Vector2(-40, 300)
	pacman.rotation = Vector2.RIGHT.angle()
	
	var x_position = -120
	for ghost in ghosts:
		ghost.position = Vector2(x_position, 300)
		x_position -= 40
		ghost.setup_default_animations()


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


func reset_animation_sequence():
	phase = 0
	attract_timer = 0


func _on_blink_timer_timeout() -> void:
	start_label.visible = not start_label.visible
