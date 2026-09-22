extends CanvasLayer

@onready var your_score_label: Label = $HBoxContainer/VBoxContainer/YourScoreLabel
@onready var high_score_label: Label = $HBoxContainer/VBoxContainer2/HighScoreLabel
@onready var new_high_score: Label = $NewHighScore

var high_score_beat := false
var blink_time : float = 0.0


func _ready() -> void:
	your_score_label.text = "%06d" % GameManager.score
	high_score_label.text = "%06d" % GameManager.high_score
	new_high_score.visible = false
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.high_score_changed.connect(_on_high_score_changed)


func _on_score_changed():
	your_score_label.text = "%06d" % GameManager.score

func _on_high_score_changed():
	high_score_beat = true
	high_score_label.text = "%06d" % GameManager.high_score


func _process(delta):
	if high_score_beat:
		blink_time += delta
		if blink_time > 0.5:
			blink_time -= 0.5
			new_high_score.visible = not new_high_score.visible
