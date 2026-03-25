extends CanvasLayer

signal restart_requested
signal exit_requested

@onready var label: Label = $Label
@onready var restart_button: Button = $HBoxContainer/RestartButton
@onready var exit_button: Button = $HBoxContainer/ExitButton
@onready var player: AudioStreamPlayer = $AudioStreamPlayer

var game_over_music = preload("res://UI/Menu/GameOverUI/Sound/Retro Music Loop - PV8 - NES Style 01.wav")

func _ready():
	hide()
	restart_button.hide()
	exit_button.hide()


func _process(delta):
	if visible:
		label.visible = int(Time.get_ticks_msec() / 500) % 2 == 0


func show_game_over():
	show()
	await get_tree().create_timer(1.0).timeout
	show_buttons()
	play_music()


func show_buttons():
	restart_button.show()
	exit_button.show()
	restart_button.grab_focus()


func play_music():
	player.stream = game_over_music
	player.play()


func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_accept"):
		if restart_button.has_focus():
			_on_restart_button_pressed()
		elif exit_button.has_focus():
			_on_exit_button_pressed()


func _on_restart_button_pressed():
	player.stop()
	restart_requested.emit()


func _on_exit_button_pressed():
	player.stop()
	exit_requested.emit()
