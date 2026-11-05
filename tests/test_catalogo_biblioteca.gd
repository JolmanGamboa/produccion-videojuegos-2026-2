## ============================================================================
## test_catalogo_biblioteca.gd — Reto autónomo: consultas sobre el catálogo
## ============================================================================
## Segunda suite unitaria, la del reto autónomo del paso 3.4. Prueba las cuatro
## consultas de `CatalogoBiblioteca` con casos normales, negativos y límite.
##
## Son las funciones de las que depende todo lo auto-poblado del proyecto: si
## `libros_de()` devolviera un ejemplar de otro estante, la sala mostraría libros
## que no corresponden y ninguna pantalla se daría cuenta, porque todas confían
## en que el catálogo responde bien. Probarlas aquí es más barato que descubrirlo
## abriendo estantes a mano.
##
## Se prueba contra el catálogo real (`catalogo.tres`) y no contra uno inventado,
## porque parte de lo que interesa verificar es que el recurso publicado está
## bien formado: que no haya ejemplares sin estante ni estantes vacíos.
## ----------------------------------------------------------------------------

class_name TestCatalogoBiblioteca
extends GdUnitTestSuite

const CATALOGO: CatalogoBiblioteca = preload("res://src/data/catalogo.tres")


# --- Caso normal -------------------------------------------------------------

func test_el_catalogo_publicado_tiene_estantes_y_ejemplares() -> void:
	assert_object(CATALOGO).is_not_null()
	assert_int(CATALOGO.categorias.size()).is_greater(0)
	assert_int(CATALOGO.libros.size()).is_greater(0)


func test_buscar_libro_devuelve_el_recurso_del_ejemplar() -> void:
	var libro: LibroData = CATALOGO.buscar_libro("dune")

	assert_object(libro).is_not_null()
	assert_object(libro).is_instanceof(LibroData)
	assert_str(libro.id).is_equal("dune")
	assert_str(libro.titulo).is_not_empty()
	assert_str(libro.autor).is_not_empty()


func test_libros_de_solo_devuelve_los_de_ese_estante() -> void:
	# La garantía que la sala de lectura da por hecha al poblarse.
	for categoria: CategoriaData in CATALOGO.categorias:
		var del_estante: Array[LibroData] = CATALOGO.libros_de(categoria.id)
		assert_int(del_estante.size()).is_greater(0)
		for libro: LibroData in del_estante:
			assert_str(libro.categoria).is_equal(categoria.id)


# --- Casos negativos ---------------------------------------------------------

func test_buscar_libro_devuelve_null_fuera_de_catalogo() -> void:
	assert_object(CATALOGO.buscar_libro("ejemplar_inexistente")).is_null()


func test_buscar_categoria_devuelve_null_fuera_de_catalogo() -> void:
	assert_object(CATALOGO.buscar_categoria("estante_inexistente")).is_null()


func test_las_consultas_toleran_el_identificador_vacio() -> void:
	# Caso límite: el estado arranca con `categoria_activa` en cadena vacía, así
	# que esta consulta se hace de verdad en el primer arranque.
	assert_object(CATALOGO.buscar_libro("")).is_null()
	assert_object(CATALOGO.buscar_categoria("")).is_null()
	assert_bool(CATALOGO.libros_de("").is_empty()).is_true()
	assert_int(CATALOGO.contar_libros("")).is_equal(0)


# --- Coherencia del recurso --------------------------------------------------

func test_contar_libros_coincide_con_la_consulta() -> void:
	for categoria: CategoriaData in CATALOGO.categorias:
		assert_int(CATALOGO.contar_libros(categoria.id)) \
			.is_equal(CATALOGO.libros_de(categoria.id).size())


func test_ningun_ejemplar_quedo_sin_estante() -> void:
	# Un ejemplar cuya categoría no exista no aparecería en ninguna pantalla:
	# estaría en el catálogo y sería invisible para el lector.
	for libro: LibroData in CATALOGO.libros:
		assert_object(CATALOGO.buscar_categoria(libro.categoria)).is_not_null()


func test_los_identificadores_de_los_ejemplares_son_unicos() -> void:
	# Los identificadores son la clave del registro guardado: uno repetido haría
	# que dos ejemplares compartieran el mismo préstamo.
	var vistos: Dictionary = {}
	for libro: LibroData in CATALOGO.libros:
		assert_bool(vistos.has(libro.id)).is_false()
		vistos[libro.id] = true

	assert_int(vistos.size()).is_equal(CATALOGO.libros.size())
