extends CanvasLayer

signal restart_requested
signal exit_requested

@onready var label: Label = $Label
@onready var restart_focus_indicator: Label = $VBoxContainer/HBoxContainer/RestartFocusIndicator
@onready var restart_button: Button = $VBoxContainer/HBoxContainer/RestartButton
@onready var exit_focus_indicator: Label = $VBoxContainer/HBoxContainer2/ExitFocusIndicator
@onready var exit_button: Button = $VBoxContainer/HBoxContainer2/ExitButton
@onready var player: AudioStreamPlayer = $AudioStreamPlayer

var game_over_music = preload("res://UI/Menu/GameOverUI/Sound/Retro Music Loop - PV8 - NES Style 01.wav")

var blink_time : float = 0.0


func _ready():
	hide()
	restart_button.hide()
	exit_button.hide()
	restart_focus_indicator.modulate.a = 0.0
	exit_focus_indicator.modulate.a = 0.0


func _process(delta):
	if visible:
		blink_time += delta
		if blink_time > 0.5:
			blink_time -= 0.5
			label.visible = not label.visible


func show_game_over():
	show()
	await get_tree().create_timer(1.0).timeout
	show_buttons()
	play_music()


func show_buttons():
	restart_button.show()
	exit_button.show()
	restart_button.grab_focus()
	restart_focus_indicator.modulate.a = 1.0


func play_music():
	player.stream = game_over_music
	player.play()


func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ACCEPT"):
		if restart_button.has_focus():
			_on_restart_button_pressed()
		elif exit_button.has_focus():
			_on_exit_button_pressed()


func _on_restart_button_focus_entered():
	restart_focus_indicator.modulate.a = 1.0


func _on_restart_button_focus_exited():
	restart_focus_indicator.modulate.a = 0.0


func _on_restart_button_pressed():
	player.stop()
	restart_requested.emit()


func _on_exit_button_focus_entered():
	exit_focus_indicator.modulate.a = 1.0


func _on_exit_button_focus_exited():
	exit_focus_indicator.modulate.a = 0.0


func _on_exit_button_pressed():
	player.stop()
	exit_requested.emit()
