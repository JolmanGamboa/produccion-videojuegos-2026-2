extends Node

## Nodo utilitario "SceneChanger": centraliza la navegación secuencial entre
## pantallas para que los controladores no dupliquen rutas de escena.

const RUTA_MENU: String = "res://src/scenes/main.tscn"
const RUTA_NIVEL_1: String = "res://src/scenes/main_level_1.tscn"


## Navega de regreso al menú principal.
func cambiar_de_escena_menu() -> void:
	get_tree().change_scene_to_file(RUTA_MENU)


## Navega hacia el nivel 1 de simulación.
func cambiar_de_escena_nivel() -> void:
	get_tree().change_scene_to_file(RUTA_NIVEL_1)


## Callback conectado desde main.tscn (BtnSimular) -> avanza al nivel 1.
func _on_button_pressed_main() -> void:
	print("[scene_changer] Navegando a la pantalla de simulación...")
	cambiar_de_escena_nivel()


## Callback conectado desde main_level_1.tscn (BtnVolver) -> regresa al menú.
func _on_button_pressed_main_level_1() -> void:
	print("[scene_changer] Regresando al menú principal...")
	cambiar_de_escena_menu()
