"""Añade un margen transparente alrededor de cada celda de una hoja de sprites.

Por qué existe
--------------
El shader de contorno del Laboratorio 12 decide si un píxel transparente linda
con la silueta consultando sus ocho vecinos. En una hoja empaquetada sin margen,
esos vecinos son píxeles del fotograma de al lado, de modo que el contorno de un
fotograma se dibuja con la silueta del siguiente: aparecen trazos fantasma en los
bordes.

Separar cada celda con un par de píxeles transparentes resuelve las dos cosas a
la vez: el muestreo vecino cae en vacío en lugar de en la celda contigua, y el
contorno tiene sitio donde dibujarse sin salirse del recorte.

Uso
---
    python3 tools/build_sprite_margen.py <entrada> <salida> <ancho> <alto> <columnas> <filas> [margen]

El tamaño de celda del recurso SpriteFrames pasa a ser (ancho + 2*margen) por
(alto + 2*margen); `tools/build_sprite_frames.gd` lo declara en sus constantes.
"""

from PIL import Image
import sys


def main() -> None:
    entrada, salida = sys.argv[1], sys.argv[2]
    ancho, alto = int(sys.argv[3]), int(sys.argv[4])
    columnas, filas = int(sys.argv[5]), int(sys.argv[6])
    margen = int(sys.argv[7]) if len(sys.argv) > 7 else 2

    origen = Image.open(entrada).convert("RGBA")
    esperado = (columnas * ancho, filas * alto)
    if origen.size != esperado:
        raise SystemExit("La hoja mide %s y la rejilla declarada exige %s" % (origen.size, esperado))

    celda_ancho = ancho + 2 * margen
    celda_alto = alto + 2 * margen
    destino = Image.new("RGBA", (columnas * celda_ancho, filas * celda_alto), (0, 0, 0, 0))

    for fila in range(filas):
        for columna in range(columnas):
            recorte = origen.crop((
                columna * ancho,
                fila * alto,
                columna * ancho + ancho,
                fila * alto + alto,
            ))
            destino.paste(recorte, (
                columna * celda_ancho + margen,
                fila * celda_alto + margen,
            ))

    destino.save(salida)
    print("escrito %s %s · celda %dx%d con %d px de margen" % (
        salida, destino.size, celda_ancho, celda_alto, margen))


if __name__ == "__main__":
    main()
