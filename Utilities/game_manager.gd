extends Node

func go_to_title():
	get_tree().change_scene_to_file("res://UI/TitleScreen/title_screen.tscn")

func start_game():
	get_tree().change_scene_to_file("res://Stages/Maze_01/maze_01.tscn")

func restart_game():
	start_game()
