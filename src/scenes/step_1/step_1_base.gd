extends Control

## ============================================================================
## step_1_base.gd — Sala de lectura (Paso 1 del recorrido)
## ============================================================================
## Entorno interactivo heredado del Laboratorio 1, ahora completamente
## desacoplado del menú: la vuelta al vestíbulo se publica en el bus global.
##
## Cada botón representa un libro del estante activo. Al "abrirlo" se despliega
## su ficha (título, autor, año y sinopsis). El estante y el tamaño de letra se
## reciben del `EventBus` mediante `parameter_changed`.
## ----------------------------------------------------------------------------

# --- Catálogo de estantes temáticos (datos separados de la presentación) ----
const ESTANTES: Dictionary = {
	"ciencia_ficcion": {
		"nombre": "Estante A — Ciencia ficción",
		"libros": [
			{
				"titulo": "Dune",
				"autor": "Frank Herbert",
				"anio": 1965,
				"sinopsis": "En el planeta desértico Arrakis, la única fuente de la especia que permite el viaje interestelar, la casa Atreides queda atrapada en una guerra por el control del recurso más valioso del universo."
			},
			{
				"titulo": "Neuromante",
				"autor": "William Gibson",
				"anio": 1984,
				"sinopsis": "Un antiguo pirata informático recibe una última oportunidad de volver a conectarse al ciberespacio, a cambio de asaltar una inteligencia artificial que nadie debería despertar."
			},
			{
				"titulo": "Fundación",
				"autor": "Isaac Asimov",
				"anio": 1951,
				"sinopsis": "Un matemático predice el derrumbe inevitable del Imperio Galáctico y funda una colonia destinada a preservar el conocimiento humano durante la larga edad oscura que viene."
			}
		]
	},
	"realismo_magico": {
		"nombre": "Estante B — Realismo mágico",
		"libros": [
			{
				"titulo": "Cien años de soledad",
				"autor": "Gabriel García Márquez",
				"anio": 1967,
				"sinopsis": "La crónica de siete generaciones de la familia Buendía en el pueblo de Macondo, donde lo extraordinario ocurre con la misma naturalidad que la lluvia."
			},
			{
				"titulo": "Pedro Páramo",
				"autor": "Juan Rulfo",
				"anio": 1955,
				"sinopsis": "Un hijo llega a Comala buscando al padre que nunca conoció y descubre un pueblo habitado por murmullos, deudas antiguas y voces que se niegan a callar."
			},
			{
				"titulo": "La casa de los espíritus",
				"autor": "Isabel Allende",
				"anio": 1982,
				"sinopsis": "Tres generaciones de mujeres de la familia Trueba atraviesan el ascenso y la caída de un país, entre premoniciones, cartas y silencios heredados."
			}
		]
	},
	"ingenieria_software": {
		"nombre": "Estante C — Ingeniería de software",
		"libros": [
			{
				"titulo": "El programador pragmático",
				"autor": "Hunt y Thomas",
				"anio": 1999,
				"sinopsis": "Un compendio de prácticas concretas para escribir código que resista el cambio, desde el principio DRY hasta la automatización disciplinada del trabajo repetitivo."
			},
			{
				"titulo": "Patrones de diseño",
				"autor": "Gamma, Helm, Johnson y Vlissides",
				"anio": 1994,
				"sinopsis": "El catálogo clásico de veintitrés soluciones reutilizables a problemas recurrentes de diseño orientado a objetos, entre ellas Observer y Singleton, base de este laboratorio."
			},
			{
				"titulo": "Refactoring",
				"autor": "Martin Fowler",
				"anio": 1999,
				"sinopsis": "Un método sistemático para mejorar la estructura interna de un programa sin alterar su comportamiento observable, apoyado en pasos pequeños y verificables."
			}
		]
	}
}

const ESTANTE_POR_DEFECTO: String = "ciencia_ficcion"
const TAMANO_TEXTO_POR_DEFECTO: int = 16

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var lbl_estante: Label = $MarginContainer/VBoxContainer/LblEstante
@onready var lbl_libro: Label = $MarginContainer/VBoxContainer/FichaLibro/MarginFicha/VBoxFicha/LblLibro
@onready var lbl_sinopsis: Label = $MarginContainer/VBoxContainer/FichaLibro/MarginFicha/VBoxFicha/LblSinopsis
@onready var btn_libro_1: Button = $MarginContainer/VBoxContainer/GridContainer/BtnLibro1
@onready var btn_libro_2: Button = $MarginContainer/VBoxContainer/GridContainer/BtnLibro2
@onready var btn_libro_3: Button = $MarginContainer/VBoxContainer/GridContainer/BtnLibro3
@onready var btn_volver: Button = $MarginContainer/VBoxContainer/BtnVolver

## Clave del estante que se está consultando.
var _estante_actual: String = ESTANTE_POR_DEFECTO


func _ready() -> void:
	print("[step_1_base] Sala de lectura montada.")

	# Reactividad local parametrizada: los tres botones comparten un único
	# callback cohesivo que recibe el índice del libro mediante bind().
	btn_libro_1.pressed.connect(_on_libro_seleccionado.bind(0))
	btn_libro_2.pressed.connect(_on_libro_seleccionado.bind(1))
	btn_libro_3.pressed.connect(_on_libro_seleccionado.bind(2))
	btn_volver.pressed.connect(_on_btn_volver_pressed)

	# Suscripción al bus para reaccionar en caliente a la configuración.
	EventBus.parameter_changed.connect(aplicar_parametro)

	_refrescar_estante()
	_limpiar_ficha()


# --- Interacción local ------------------------------------------------------

## Despliega la ficha del libro seleccionado dentro del estante activo.
func _on_libro_seleccionado(indice: int) -> void:
	var libros: Array = ESTANTES[_estante_actual]["libros"]
	if indice < 0 or indice >= libros.size():
		return

	var libro: Dictionary = libros[indice]
	lbl_libro.text = "%s — %s (%d)" % [libro["titulo"], libro["autor"], libro["anio"]]
	lbl_sinopsis.text = libro["sinopsis"]
	print("[step_1_base] Libro abierto: " + str(libro["titulo"]))


## Publica el regreso al vestíbulo sin conocer la ruta del menú por su nombre.
func _on_btn_volver_pressed() -> void:
	EventBus.navigation_requested.emit(EventBus.RUTA_MENU)


# --- Contrato con el bus / MainApp ------------------------------------------

## Aplica un parámetro global. La invocan tanto `EventBus.parameter_changed`
## como `MainApp` al reinyectar el estado guardado en un panel nuevo.
func aplicar_parametro(param_name: String, value: Variant) -> void:
	match param_name:
		EventBus.PARAM_ESTANTE:
			if ESTANTES.has(value):
				_estante_actual = str(value)
				_refrescar_estante()
				_limpiar_ficha()
		EventBus.PARAM_TAMANO_TEXTO:
			var tamano: int = int(value)
			lbl_sinopsis.add_theme_font_size_override("font_size", tamano)


# --- Presentación -----------------------------------------------------------

## Reetiqueta el encabezado y los lomos de los libros del estante activo.
func _refrescar_estante() -> void:
	var estante: Dictionary = ESTANTES[_estante_actual]
	var libros: Array = estante["libros"]

	lbl_estante.text = str(estante["nombre"])
	btn_libro_1.text = str(libros[0]["titulo"])
	btn_libro_2.text = str(libros[1]["titulo"])
	btn_libro_3.text = str(libros[2]["titulo"])


## Restablece la ficha a su estado vacío.
func _limpiar_ficha() -> void:
	lbl_libro.text = "Ningún libro abierto"
	lbl_sinopsis.text = "Selecciona un libro del estante para leer su descripción."
