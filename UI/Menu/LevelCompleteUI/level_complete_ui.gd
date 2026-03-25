extends CanvasLayer

signal next_level_requested
signal exit_requested

@onready var label: Label = $Label
@onready var next_level_button: Button = $HBoxContainer/NextLevelButton
@onready var exit_button: Button = $HBoxContainer/ExitButton
@onready var player: AudioStreamPlayer = $AudioStreamPlayer

var level_complete_music = preload("res://UI/Menu/LevelCompleteUI/Sound/Retro Music - WolfSynth - Tempo Normal - 02.wav")


func _ready():
	hide()
	next_level_button.hide()
	exit_button.hide()


func _process(delta):
	if visible:
		label.visible = int(Time.get_ticks_msec() / 500) % 2 == 0


func show_level_complete():
	show()
	await get_tree().create_timer(1.0).timeout
	show_buttons()
	play_music()


func show_buttons():
	next_level_button.show()
	exit_button.show()
	next_level_button.grab_focus()


func play_music():
	player.stream = level_complete_music
	player.play()


func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_accept"):
		if next_level_button.has_focus():
			_on_next_level_button_pressed()
		elif exit_button.has_focus():
			_on_exit_button_pressed()


func _on_next_level_button_pressed():
	player.stop()
	next_level_requested.emit()


func _on_exit_button_pressed():
	player.stop()
	exit_requested.emit()
