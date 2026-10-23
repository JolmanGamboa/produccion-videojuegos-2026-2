class_name CatalogoBiblioteca
extends Resource

## ============================================================================
## CatalogoBiblioteca — la colección oficial de la biblioteca
## ============================================================================
## Recurso contenedor que reúne los estantes y los ejemplares. `GlobalManager`
## lo carga con `preload()` y lo expone como único punto de acceso, de modo que
## ninguna pantalla construye su contenido a mano.
##
## Las consultas viven aquí y no en el gestor porque son preguntas sobre los
## datos, no sobre el estado de la sesión.
## ----------------------------------------------------------------------------

@export var categorias: Array[CategoriaData] = []
@export var libros: Array[LibroData] = []


## Ejemplares que pertenecen a un estante, en el orden del catálogo.
func libros_de(categoria_id: String) -> Array[LibroData]:
	var encontrados: Array[LibroData] = []
	for libro: LibroData in libros:
		if libro.categoria == categoria_id:
			encontrados.append(libro)
	return encontrados


## Devuelve el ejemplar con ese identificador, o `null` si no está en catálogo.
func buscar_libro(libro_id: String) -> LibroData:
	for libro: LibroData in libros:
		if libro.id == libro_id:
			return libro
	return null


## Devuelve el estante con ese identificador, o `null` si no existe.
func buscar_categoria(categoria_id: String) -> CategoriaData:
	for categoria: CategoriaData in categorias:
		if categoria.id == categoria_id:
			return categoria
	return null


## Cuántos ejemplares tiene un estante. Lo usa la tarjeta de la categoría.
func contar_libros(categoria_id: String) -> int:
	return libros_de(categoria_id).size()
