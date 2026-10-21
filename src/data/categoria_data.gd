class_name CategoriaData
extends Resource

## ============================================================================
## CategoriaData — un estante temático de la biblioteca
## ============================================================================
## Cada categoría es un recurso independiente. Agregar un estante nuevo es
## crear otro recurso y soltarlo en el catálogo: ninguna pantalla se entera,
## porque todas se construyen leyendo la colección.
## ----------------------------------------------------------------------------

## Identificador estable. Es lo que se guarda en disco y lo que relaciona a los
## ejemplares con su estante, así que no debe cambiar una vez publicado.
@export var id: String = ""

## Nombre visible del estante.
@export var nombre: String = ""

## Una línea sobre qué se encuentra en él. La muestra la tarjeta.
@export_multiline var descripcion: String = ""

## Icono del estante, dibujado en la tarjeta junto al nombre.
@export var icono: Texture2D

## Color de acento de la categoría. Refuerza la identidad del estante sin ser
## el único portador de información: el nombre y el icono dicen lo mismo.
@export var color: Color = Color(0.752941, 0.541176, 0.243137)
