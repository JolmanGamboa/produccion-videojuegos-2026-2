extends Control

## ============================================================================
## MainApp — Orquestador central de la Biblioteca Interactiva
## ============================================================================
## Escena principal del proyecto (`res://src/core/main_app.tscn`). Es el único
## nodo con autoridad para instanciar paneles, inyectarlos en el contenedor
## responsivo `SceneContainer` y liberarlos de la memoria RAM.
##
## Responsabilidades:
##   1. Suscribirse de forma diferida a `EventBus.navigation_requested`.
##   2. Administrar la pila lógica `navigation_history`, apilando con append()
##      y desapilando con pop_back() según el parámetro `discard_previous`.
##   3. Liberar la escena previa con `queue_free()` y limpiar su referencia
##      lógica para prevenir fugas de memoria (memory leaks).
##   4. Pedir al `GlobalManager` que reemita su estado, de modo que el panel
##      entrante se sincronice sin consultarlo directamente.
## ----------------------------------------------------------------------------

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var scene_container: Control = $SceneContainer

## Referencia a la escena actualmente montada en el árbol visual.
var current_scene: Node = null

## Pila de historial: secuencia de pantallas visitadas por el usuario.
var navigation_history: Array[String] = []


func _ready() -> void:
	# CONNECT_DEFERRED: el callback se ejecuta al final del frame, nunca dentro
	# de la propia emisión de la señal. Así el panel que solicita la navegación
	# termina de procesar su evento antes de que su nodo sea liberado.
	EventBus.navigation_requested.connect(_on_navigation_requested, CONNECT_DEFERRED)

	print("[main_app] Orquestador suscrito al bus global. Cargando vestíbulo...")
	_cargar_escena(EventBus.RUTA_MENU, false)


# --- Suscriptor del bus global ----------------------------------------------

## Único punto del sistema que conmuta paneles.
func _on_navigation_requested(target_scene: String, discard_previous: bool) -> void:
	print("[main_app] Evento de navegación recibido -> " + target_scene)
	_cargar_escena(target_scene, discard_previous)


# --- Gestión del ciclo de vida y del historial ------------------------------

## Actualiza la pila, libera el panel activo y monta el solicitado.
func _cargar_escena(target_scene: String, discard_previous: bool) -> void:
	# 1. Administración de la pila de historial.
	if discard_previous:
		if not navigation_history.is_empty():
			navigation_history.pop_back()
	else:
		navigation_history.append(target_scene)

	# 2. Liberación explícita de la memoria RAM del panel anterior.
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# 3. Carga y validación del recurso empaquetado.
	var escena_empaquetada: PackedScene = load(target_scene) as PackedScene
	if escena_empaquetada == null:
		push_error("[main_app] Ruta de escena inválida: " + target_scene)
		return

	# 4. Instanciación e inyección en el contenedor responsivo.
	current_scene = escena_empaquetada.instantiate()
	scene_container.add_child(current_scene)

	# 5. Sincronización del panel entrante con el estado global vigente.
	GlobalManager.emitir_estado_actual()

	print("[main_app] navigation_history: " + str(navigation_history))
