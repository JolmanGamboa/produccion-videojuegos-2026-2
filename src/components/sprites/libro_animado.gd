class_name LibroAnimado
extends Control

## ============================================================================
## libro_animado.gd — El ejemplar como sprite dirigido por la máquina de estados
## ============================================================================
## Componente reutilizable, hermano de `ButtonNav`: envuelve un
## `AnimatedSprite2D` dentro de un `Control` para que se pueda colocar en los
## contenedores de la interfaz, que no admiten nodos `Node2D` sueltos.
##
## Lo que hace es traducir el estado del ciclo del ejemplar —el mismo vocabulario
## que el `EventBus` publica desde el Laboratorio 6— a la animación que le
## corresponde:
##
##     en_estante     → cerrado          (quieto en el estante)
##     en_consulta    → abriendo → pasando_hojas (en bucle)
##     en_comprobante → pasando_hojas    (sigue abierto mientras se tramita)
##     registrando    → cerrando
##     prestado       → de_canto         (sale de la sala)
##
## No se suscribe al bus por su cuenta. La sala construye una tarjeta por
## ejemplar y solo una está abierta a la vez, así que suscribir cada sprite
## pondría tantos oyentes en el bus como libros tenga el estante para que todos
## menos uno ignoraran el evento. La pantalla, que ya sabe cuál está en consulta,
## le dice a cada uno qué estado le toca.
## ----------------------------------------------------------------------------

const MARCOS: SpriteFrames = preload("res://src/assets/sprites/libro_biblioteca.tres")

## Qué animación corresponde a cada estado del ciclo. Tenerlo como tabla, y no
## como una cadena de `if`, es la misma decisión que la tabla de transiciones
## de la FSM: el mapa se lee de un vistazo y añadir un estado es añadir una
## línea.
const ANIMACION_DE_ESTADO: Dictionary = {
	EventBus.ESTADO_EN_ESTANTE: "cerrado",
	EventBus.ESTADO_EN_CONSULTA: "abriendo",
	EventBus.ESTADO_EN_COMPROBANTE: "pasando_hojas",
	EventBus.ESTADO_REGISTRANDO: "cerrando",
	EventBus.ESTADO_PRESTADO: "de_canto",
}

## Animación que sigue a otra cuando termina. Abrir el libro desemboca en pasar
## hojas, que es el bucle en el que se queda mientras el lector lee la ficha.
const ENCADENA: Dictionary = {
	"abriendo": "pasando_hojas",
}

@onready var sprite: AnimatedSprite2D = $Sprite

## Estado que se pidió antes de que el nodo estuviera listo. Las tarjetas se
## construyen y se pintan en el mismo fotograma, así que esto llega a pasar.
var _pendiente: String = ""


func _ready() -> void:
	sprite.sprite_frames = MARCOS
	sprite.animation_finished.connect(_on_animation_finished)

	# El sprite dibuja desde su esquina, así que se centra a mano dentro del
	# Control: es el precio de meter un Node2D en un contenedor de interfaz.
	sprite.position = size / 2.0
	resized.connect(func() -> void: sprite.position = size / 2.0)

	aplicar_estado(_pendiente if not _pendiente.is_empty() else EventBus.ESTADO_EN_ESTANTE)


## Pone el sprite en el estado del ciclo que se le indique. Es idempotente:
## repetir el estado vigente no reinicia la animación, de modo que la sala puede
## llamarlo en cada repintado sin que el libro parpadee.
func aplicar_estado(nombre_estado: String) -> void:
	if not ANIMACION_DE_ESTADO.has(nombre_estado):
		return

	if sprite == null:
		_pendiente = nombre_estado
		return

	var animacion: String = str(ANIMACION_DE_ESTADO[nombre_estado])

	# Si ya está en la animación pedida, o en la que esa animación encadena, no
	# hay nada que hacer.
	if sprite.animation == animacion:
		return
	if ENCADENA.has(animacion) and sprite.animation == str(ENCADENA[animacion]):
		return

	sprite.play(animacion)


## Encadena la animación siguiente, si la hay. Es lo que convierte «abrir» en
## «pasar hojas» sin que la pantalla tenga que temporizar nada.
func _on_animation_finished() -> void:
	var actual: String = str(sprite.animation)
	if ENCADENA.has(actual):
		sprite.play(str(ENCADENA[actual]))
