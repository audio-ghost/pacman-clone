extends Node

signal score_changed
signal high_score_changed

const SAVE_PATH := "user://save_data.json"

const DEFAULT_GHOST_SPEED = 70.0

var level := 1
var player_lives := 3
var score := 0
var high_score := 0
var high_score_dirty := false


func _ready():
	print("Game Manager Ready")
	initialize_game()


func initialize_game():
	print("Initialize game...")
	level = 1
	player_lives = 3
	score = 0
	load_game()


func go_to_title():
	save_game()
	initialize_game()
	get_tree().change_scene_to_file("res://UI/TitleScreen/title_screen.tscn")


func start_game():
	get_tree().change_scene_to_file("res://Stages/Maze_01/maze_01.tscn")


func restart_game():
	save_game()
	initialize_game()
	start_game()


func go_to_next_level():
	save_game()
	level += 1
	if player_lives < 3:
		player_lives += 1
	else:
		score += 1000
	start_game()


func player_died():
	player_lives -= 1


func add_score(amount: int):
	score += amount
	score_changed.emit()
	
	if score > high_score:
		high_score_dirty = true
		high_score = score
		high_score_changed.emit()


func save_game():
	if high_score_dirty:
		print("Saving to: ", ProjectSettings.globalize_path(SAVE_PATH))
		var data = {
			"high_score": high_score
		}
		
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify(data))
		file.close()
		
		high_score_dirty = false


func load_game():
	print("Loading game...")
	print("File exists: ", FileAccess.file_exists(SAVE_PATH))
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	
	var data = JSON.parse_string(content)
	
	if data != null and data.has("high_score"):
		high_score = data["high_score"]

func ghost_speed_multiplier() -> float:
	return min(1.0 + (level - 1) * 0.04, 1.3)
