from PIL import Image
import sys

# Original -> paleta de la Biblioteca Interactiva 2D (ui_theme.tres)
MAPA = {
    (255,255,255): None,          # fondo -> transparente
    (211,220,147): (239,230,218), # hoja clara   -> crema del texto
    (198,198,118): (220,205,182), # hoja media
    (174,166,100): (192,172,142), # hoja sombra
    (157,142, 83): (158,135,104), # hoja sombra profunda
    (109, 82,  1): (138, 85, 35), # cubierta     -> cuero cálido
    (121, 91, 29): (217,160, 84), # filo/título  -> dorado del tema
    ( 88, 62,  1): (107, 63, 26), # cubierta sombra
    ( 65, 38,  1): ( 74, 42, 17), # cubierta oscura
}

src = Image.open(sys.argv[1]).convert('RGB')
w,h = src.size
out = Image.new('RGBA', (w,h), (0,0,0,0))
sp, op = src.load(), out.load()
faltantes = set()
for y in range(h):
    for x in range(w):
        c = sp[x,y]
        if c not in MAPA:
            faltantes.add(c); continue
        d = MAPA[c]
        if d is not None:
            op[x,y] = (d[0], d[1], d[2], 255)
if faltantes:
    print('AVISO colores sin mapear:', faltantes)
out.save(sys.argv[2])
print('escrito', sys.argv[2], out.size)
