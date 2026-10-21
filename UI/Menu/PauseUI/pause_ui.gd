extends CanvasLayer

signal resume_requested
signal exit_requested

@onready var label: Label = $Label
@onready var resume_focus_indicator: Label = $VBoxContainer/HBoxContainer/ResumeFocusIndicator
@onready var resume_button: Button = $VBoxContainer/HBoxContainer/ResumeButton
@onready var exit_focus_indicator: Label = $VBoxContainer/HBoxContainer2/ExitFocusIndicator
@onready var exit_button: Button = $VBoxContainer/HBoxContainer2/ExitButton

var blink_time : float = 0.0


func _ready():
	hide_pause_overlay()
	resume_focus_indicator.modulate.a = 0.0
	exit_focus_indicator.modulate.a = 0.0


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


func _on_resume_button_focus_entered():
	resume_focus_indicator.modulate.a = 1.0


func _on_resume_button_focus_exited():
	resume_focus_indicator.modulate.a = 0.0


func _on_resume_button_pressed():
	resume_requested.emit()


func _on_exit_button_focus_entered():
	exit_focus_indicator.modulate.a = 1.0


func _on_exit_button_focus_exited():
	exit_focus_indicator.modulate.a = 0.0


func _on_exit_button_pressed():
	exit_requested.emit()
