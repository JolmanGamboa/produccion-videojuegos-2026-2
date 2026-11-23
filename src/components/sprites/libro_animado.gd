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
##
## Desde el Laboratorio 12 el componente lleva además los dos shaders:
##
##   · Un contorno en un sprite auxiliar detrás del ejemplar, que aparece cuando
##     el ejemplar se puede abrir y el cursor está encima. Su color lo pone la
##     sala con el del estante, de modo que un único shader sirve para los
##     diecisiete ejemplares sin una textura adicional.
##   · Una ondulación del muestreo durante `registrando`, mientras el gestor
##     escribe el préstamo en disco.
##
## El material del sello se guarda y se retira del sprite en vez de dejarlo
## puesto con la intensidad a cero: así los demás estados no pagan el coste de
## un shader que no hace nada.
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

## Material de la ondulación del sello, asignado desde la escena. Se conserva
## aquí y solo se monta en el sprite durante `registrando`.
@export var sello_material: ShaderMaterial

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var contorno: AnimatedSprite2D = $Contorno

## Estado que se pidió antes de que el nodo estuviera listo. Las tarjetas se
## construyen y se pintan en el mismo fotograma, así que esto llega a pasar.
var _pendiente: String = ""

## Si el ejemplar admite interacción y si el cursor está encima. El contorno
## necesita las dos cosas, y son independientes: el cursor puede entrar en una
## tarjeta cuyo ejemplar está prestado.
var _interactuable: bool = false
var _cursor_encima: bool = false

## Color de contorno pedido antes de que el nodo estuviera listo. La sala arma
## la tarjeta entera y la añade al árbol después, de modo que cuando reparte los
## colores el `_ready()` de este componente todavía no ha corrido.
var _color_pendiente: Color = Color.TRANSPARENT


func _ready() -> void:
	sprite.sprite_frames = MARCOS
	sprite.animation_finished.connect(_on_animation_finished)

	# El contorno usa la misma hoja y reproduce la misma animación, un fotograma
	# por detrás en el orden de dibujo. Si usara otra textura, el borde dejaría
	# de corresponderse con la silueta en cuanto el libro se abriera.
	contorno.sprite_frames = MARCOS

	# Cada ejemplar necesita su propio material: con uno compartido, el color de
	# un estante se lo llevarían también los demás.
	contorno.material = contorno.material.duplicate()

	if _color_pendiente != Color.TRANSPARENT:
		fijar_color_contorno(_color_pendiente)

	# El sprite dibuja desde su esquina, así que se centra a mano dentro del
	# Control: es el precio de meter un Node2D en un contenedor de interfaz.
	_centrar()
	resized.connect(_centrar)

	aplicar_estado(_pendiente if not _pendiente.is_empty() else EventBus.ESTADO_EN_ESTANTE)


## Coloca los dos sprites en el centro del Control que los envuelve.
func _centrar() -> void:
	sprite.position = size / 2.0
	contorno.position = size / 2.0


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
	contorno.play(animacion)

	# La ondulación solo se monta mientras el préstamo se está escribiendo.
	_aplicar_sello(nombre_estado == EventBus.ESTADO_REGISTRANDO)


## Encadena la animación siguiente, si la hay. Es lo que convierte «abrir» en
## «pasar hojas» sin que la pantalla tenga que temporizar nada.
func _on_animation_finished() -> void:
	var actual: String = str(sprite.animation)
	if ENCADENA.has(actual):
		var siguiente: String = str(ENCADENA[actual])
		sprite.play(siguiente)
		contorno.play(siguiente)


# --- Shaders: contorno de interacción y sello ------------------------------

## Declara si el ejemplar admite interacción. Es el equivalente del
## `is_interactable()` del laboratorio, salvo que aquí el dato no se recalcula:
## lo trae la sala, que ya lo usa para habilitar los botones de la tarjeta.
func marcar_interactuable(puede: bool) -> void:
	_interactuable = puede
	_refrescar_contorno()


## Entrada y salida del cursor. La tarjeta las reenvía desde su propio ratón,
## porque este Control las ignora para no robarle las pulsaciones al botón.
func marcar_cursor(encima: bool) -> void:
	_cursor_encima = encima
	_refrescar_contorno()


## Color del contorno. La sala le pasa el del estante, así que el mismo shader
## produce cuatro bordes distintos sin más que cambiar un `uniform`.
func fijar_color_contorno(color: Color) -> void:
	if contorno == null:
		_color_pendiente = color
		return
	(contorno.material as ShaderMaterial).set_shader_parameter("color_contorno", color)


## El contorno pide las dos condiciones a la vez, como en la guía: que el objeto
## se pueda interactuar y que el cursor esté encima.
func _refrescar_contorno() -> void:
	if contorno == null:
		return
	contorno.visible = _interactuable and _cursor_encima


## Monta o retira el material de la ondulación. Retirarlo, en vez de dejarlo con
## la intensidad a cero, evita que los ejemplares que no se están registrando
## paguen un shader que no haría nada.
func _aplicar_sello(activo: bool) -> void:
	if sprite == null or sello_material == null:
		return
	sprite.material = sello_material if activo else null
