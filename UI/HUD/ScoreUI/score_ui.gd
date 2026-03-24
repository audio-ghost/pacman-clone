extends CanvasLayer

@onready var your_score_label: Label = $HBoxContainer/VBoxContainer/YourScoreLabel
@onready var high_score_label: Label = $HBoxContainer/VBoxContainer2/HighScoreLabel
@onready var new_high_score: Label = $NewHighScore

var high_score_beat := false

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
		new_high_score.visible = int(Time.get_ticks_msec() / 500) % 2 == 0
