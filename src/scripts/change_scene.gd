extends Node

# Método para navegar de regreso al menú principal
func cambiar_de_escena_menu() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main.tscn")

# Método para navegar hacia el nivel 1 de simulación
func cambiar_de_escena_nivel() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main_level_1.tscn")

func _on_button_pressed_main() -> void:
	cambiar_de_escena_menu()

func _on_button_pressed_main_level_1() -> void:
	cambiar_de_escena_menu()
