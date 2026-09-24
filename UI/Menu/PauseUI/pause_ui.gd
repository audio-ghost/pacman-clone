extends CanvasLayer

signal resume_requested
signal exit_requested

@onready var label: Label = $Label
@onready var resume_button: Button = $HBoxContainer/ResumeButton
@onready var exit_button: Button = $HBoxContainer/ExitButton

var blink_time : float = 0.0


func _ready():
	hide_pause_overlay()


func _process(delta):
	if visible:
		blink_time += delta
		if blink_time > 0.5:
			blink_time -= 0.5
			label.visible = not label.visible


func hide_pause_overlay():
	hide()
	resume_button.hide()
	exit_button.hide()


func show_pause_overlay():
	show()
	show_buttons()


func show_buttons():
	resume_button.show()
	exit_button.show()
	resume_button.grab_focus()


func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ACCEPT"):
		if resume_button.has_focus():
			_on_resume_button_pressed()
		elif exit_button.has_focus():
			_on_exit_button_pressed()
	elif event.is_action_pressed("PAUSE"):
		_on_resume_button_pressed()
		get_viewport().set_input_as_handled()


func _on_resume_button_pressed():
	resume_requested.emit()


func _on_exit_button_pressed():
	exit_requested.emit()
