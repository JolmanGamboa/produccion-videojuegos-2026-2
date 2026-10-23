class_name LibroData
extends Resource

## ============================================================================
## LibroData — un ejemplar del catálogo
## ============================================================================
## Sustituye al diccionario constante que vivía dentro de `GlobalManager`.
## Sumar un ejemplar ya no es editar código: es crear un recurso y añadirlo a
## la colección del catálogo.
## ----------------------------------------------------------------------------

## Identificador estable del ejemplar. Es la clave con la que se registra el
## préstamo y con la que se guarda en disco: cambiarlo invalida los guardados.
@export var id: String = ""

@export var titulo: String = ""
@export var autor: String = ""
@export var anio: int = 0

## Identificador de la categoría a la que pertenece, que debe coincidir con el
## `id` de alguna `CategoriaData` del catálogo.
@export var categoria: String = ""

## Extensión del ejemplar. Es el atributo que el comprobante usa para sugerir
## un plazo: un libro largo se lee mejor con más días.
@export var paginas: int = 0

@export_multiline var sinopsis: String = ""

## Portada opcional. Si está vacía, la ficha se dibuja solo con texto.
@export var portada: Texture2D
