from PIL import Image, ImageDraw
import sys, math

CELDA = 32
FRAMES = 8

CREMA      = (239, 230, 218, 255)
TINTA      = ( 74,  42,  17, 255)
CUERO      = (138,  85,  35, 255)

# Estados del plazo, en el registro cálido del tema. El color no es lo único
# que distingue: cambia también cuánto arco queda, que se lee sin color.
ESTADOS = [
    ("al_dia",     (127, 168, 107, 255), 0.85),
    ("por_vencer", (217, 160,  84, 255), 0.50),
    ("urgente",    (201, 106,  52, 255), 0.22),
    ("vencido",    (188,  68,  58, 255), 0.00),
]

CX = CY = 15.5
R_ARO, R_CARA, L_AGUJA = 13, 10, 8


def celda(color, fraccion, i):
    im = Image.new("RGBA", (CELDA, CELDA), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    # Patas y corona, para que la silueta se lea como un reloj y no como un disco.
    d.rectangle([9, 27, 11, 30], fill=color)
    d.rectangle([20, 27, 22, 30], fill=color)
    d.rectangle([14, 0, 17, 3], fill=color)

    # El aro lleva siempre el color del estado, de modo que se lee incluso
    # cuando ya no queda arco que dibujar.
    caja = [CX - R_ARO, CY - R_ARO, CX + R_ARO, CY + R_ARO]
    d.ellipse(caja, fill=CREMA, outline=color, width=2)

    # Arco del plazo restante, en tinta: empieza arriba y avanza en sentido
    # horario. Es el dato que no depende del color, como pide la accesibilidad
    # que el proyecto ya adoptó en el laboratorio 8.
    interior = [CX - R_CARA, CY - R_CARA, CX + R_CARA, CY + R_CARA]
    if fraccion > 0.0:
        d.arc(interior, start=-90, end=-90 + 360 * fraccion, fill=TINTA, width=2)

    # Marcas de las cuatro horas.
    for ang in (0, 90, 180, 270):
        rad = math.radians(ang - 90)
        x, y = CX + math.cos(rad) * (R_CARA - 1), CY + math.sin(rad) * (R_CARA - 1)
        d.point((round(x), round(y)), fill=TINTA)

    # La aguja gira: es lo que anima. El color dice la urgencia, el giro dice
    # que el plazo corre.
    rad = math.radians(i * (360.0 / FRAMES) - 90)
    d.line([CX, CY, CX + math.cos(rad) * L_AGUJA, CY + math.sin(rad) * L_AGUJA],
           fill=TINTA, width=2)
    d.ellipse([CX - 1.5, CY - 1.5, CX + 1.5, CY + 1.5], fill=TINTA)
    return im


hoja = Image.new("RGBA", (CELDA * FRAMES, CELDA * len(ESTADOS)), (0, 0, 0, 0))
for fila, (nombre, color, fraccion) in enumerate(ESTADOS):
    for i in range(FRAMES):
        hoja.paste(celda(color, fraccion, i), (i * CELDA, fila * CELDA))
    print("fila %d -> %s" % (fila, nombre))

hoja.save(sys.argv[1])
print("escrito", sys.argv[1], hoja.size)
