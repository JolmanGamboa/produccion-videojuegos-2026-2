extends SceneTree

## Herramienta de autor, no forma parte del juego.
##
## Construye src/data/catalogo.tres de una pasada a partir de las tablas de
## abajo. Existe porque cargar diecisiete ejemplares a mano en el Inspector es
## lento y propenso a erratas; a partir de aquí el catálogo es un recurso
## normal y se edita desde el editor como cualquier otro.
##
## Para regenerarlo:
##     godot --headless --path . --script tools/build_catalogo.gd
##
## Ojo: reescribe el archivo entero, así que lo que se haya editado a mano en
## el Inspector se pierde. Si el catálogo ya divergió, edítalo allí y no aquí.

const CATS := [
	["ciencia_ficcion", "Ciencia ficción",
	 "Futuros posibles, mundos imposibles y preguntas que todavía no sabemos responder.",
	 Color(0.42, 0.62, 0.82)],
	["realismo_magico", "Realismo mágico",
	 "Donde lo extraordinario ocurre con la misma naturalidad que la lluvia.",
	 Color(0.80, 0.52, 0.34)],
	["ingenieria_software", "Ingeniería de software",
	 "Oficio, disciplina y las lecciones que alguien ya aprendió por nosotros.",
	 Color(0.47, 0.72, 0.56)],
	["clasicos_universales", "Clásicos universales",
	 "Los libros que siguen contestando preguntas que nadie les hizo.",
	 Color(0.78, 0.63, 0.35)],
]

const LIBROS := [
	["dune", "Dune", "Frank Herbert", 1965, "ciencia_ficcion", 896,
	 "En el planeta desértico Arrakis, única fuente de la especia que permite el viaje interestelar, la casa Atreides queda atrapada en una guerra por el control del recurso más valioso del universo conocido."],
	["neuromante", "Neuromante", "William Gibson", 1984, "ciencia_ficcion", 320,
	 "Un antiguo pirata informático recibe una última oportunidad de volver a conectarse al ciberespacio, a cambio de asaltar una inteligencia artificial que nadie debería despertar."],
	["fundacion", "Fundación", "Isaac Asimov", 1951, "ciencia_ficcion", 280,
	 "Un matemático predice el derrumbe inevitable del Imperio Galáctico y funda una colonia destinada a preservar el conocimiento humano durante la larga edad oscura que viene."],
	["solaris", "Solaris", "Stanisław Lem", 1961, "ciencia_ficcion", 224,
	 "Una estación orbita un océano que piensa. Cuanto más lo estudian los científicos, más claro queda que el objeto de estudio los está estudiando a ellos."],
	["mano_izquierda", "La mano izquierda de la oscuridad", "Ursula K. Le Guin", 1969, "ciencia_ficcion", 304,
	 "Un enviado llega a un planeta helado cuyos habitantes no tienen sexo fijo, y descubre que casi todo lo que creía saber sobre la política venía de una diferencia que allí no existe."],

	["cien_anios", "Cien años de soledad", "Gabriel García Márquez", 1967, "realismo_magico", 471,
	 "La crónica de siete generaciones de la familia Buendía en el pueblo de Macondo, donde los prodigios se registran con la misma calma que los nacimientos y las lluvias."],
	["pedro_paramo", "Pedro Páramo", "Juan Rulfo", 1955, "realismo_magico", 124,
	 "Un hijo llega a Comala buscando al padre que nunca conoció y encuentra un pueblo habitado por murmullos, deudas antiguas y voces que se niegan a callar."],
	["casa_espiritus", "La casa de los espíritus", "Isabel Allende", 1982, "realismo_magico", 433,
	 "Tres generaciones de mujeres de la familia Trueba atraviesan el ascenso y la caída de un país, entre premoniciones, cartas y silencios heredados."],
	["como_agua", "Como agua para chocolate", "Laura Esquivel", 1989, "realismo_magico", 246,
	 "A la hija menor le toca cuidar de su madre y renunciar al matrimonio, así que vuelca en la cocina todo lo que no puede decir, y quien come sus platos siente lo que ella sentía al prepararlos."],

	["pragmatico", "El programador pragmático", "Hunt y Thomas", 1999, "ingenieria_software", 352,
	 "Un compendio de prácticas concretas para escribir código que resista el cambio, desde el principio DRY hasta la automatización disciplinada del trabajo repetitivo."],
	["patrones_diseno", "Patrones de diseño", "Gamma, Helm, Johnson y Vlissides", 1994, "ingenieria_software", 395,
	 "El catálogo clásico de veintitrés soluciones reutilizables a problemas recurrentes del diseño orientado a objetos, entre ellas Observer y Singleton, base de la arquitectura de este proyecto."],
	["refactoring", "Refactoring", "Martin Fowler", 1999, "ingenieria_software", 448,
	 "Un método sistemático para mejorar la estructura interna de un programa sin alterar su comportamiento observable, apoyado en pasos pequeños y verificables."],
	["mes_hombre", "El mítico hombre-mes", "Frederick Brooks", 1975, "ingenieria_software", 322,
	 "Por qué sumar gente a un proyecto retrasado lo retrasa todavía más, y otras verdades incómodas sobre la gestión de equipos que siguen vigentes medio siglo después."],

	["quijote", "Don Quijote de la Mancha", "Miguel de Cervantes", 1605, "clasicos_universales", 1056,
	 "Un hidalgo lee tantos libros de caballerías que decide salir a vivirlos, y el mundo, que no está escrito como sus novelas, se encarga de recordárselo en cada venta y cada camino."],
	["crimen_castigo", "Crimen y castigo", "Fiódor Dostoyevski", 1866, "clasicos_universales", 671,
	 "Un estudiante empobrecido se convence de que ciertas personas están por encima de la ley, comete un asesinato para probarlo y descubre que la condena empieza mucho antes del juicio."],
	["moby_dick", "Moby Dick", "Herman Melville", 1851, "clasicos_universales", 635,
	 "La persecución de una ballena blanca por un capitán que ha confundido su herida con el sentido del mundo, contada por el único tripulante que sobrevive para contarla."],
	["odisea", "La Odisea", "Homero", -700, "clasicos_universales", 416,
	 "El regreso a casa de un hombre que tarda diez años en recorrer lo que debería haber sido un viaje corto, estorbado por dioses, monstruos y su propia astucia."],
]


func _initialize() -> void:
	var catalogo := CatalogoBiblioteca.new()

	var cats: Array[CategoriaData] = []
	for fila: Array in CATS:
		var c := CategoriaData.new()
		c.id = fila[0]
		c.nombre = fila[1]
		c.descripcion = fila[2]
		c.color = fila[3]
		c.icono = load("res://src/assets/ui/icons/cat_%s.png" % fila[0])
		cats.append(c)
	catalogo.categorias = cats

	var libs: Array[LibroData] = []
	for fila: Array in LIBROS:
		var l := LibroData.new()
		l.id = fila[0]
		l.titulo = fila[1]
		l.autor = fila[2]
		l.anio = fila[3]
		l.categoria = fila[4]
		l.paginas = fila[5]
		l.sinopsis = fila[6]
		libs.append(l)
	catalogo.libros = libs

	var err := ResourceSaver.save(catalogo, "res://src/data/catalogo.tres")
	print("categorias=", cats.size(), " libros=", libs.size(), " err=", err)
	quit()
