# Exportación Web y publicación en itch.io

Guía de los ajustes con los que este proyecto se exporta a navegador. Resume lo
que pide la Parte 3 de la Guía de Laboratorio 7 y deja constancia de por qué
cada opción queda como queda.

## 1. Requisitos previos en el proyecto

Estos ya están configurados en `project.godot` y no hay que tocarlos:

| Ajuste | Valor | Por qué |
| --- | --- | --- |
| `renderer/rendering_method` | `gl_compatibility` | Es el único backend que compila a WebGL 2; Forward+ no exporta a navegador. |
| `window/stretch/mode` | `canvas_items` | La interfaz se reescala con el lienzo en vez de recortarse. |
| `window/stretch/aspect` | `expand` | Permite relaciones de aspecto distintas sin bandas negras. |
| `gui/theme/custom` | `biblioteca_theme.tres` | El tema viaja dentro del paquete exportado. |

## 2. Plantillas de exportación

**Editor → Gestionar plantillas de exportación → Descargar y instalar.**
Sin ellas el preset Web aparece con un aviso en rojo y el botón de exportar
queda deshabilitado. La descarga es de una sola vez por versión de Godot.

## 3. Preset Web

**Proyecto → Exportar… → Añadir… → Web**, con estas opciones:

| Opción | Valor | Por qué |
| --- | --- | --- |
| Export Path | `build/web/index.html` | El archivo **debe** llamarse `index.html`: es el que itch.io busca en la raíz del ZIP. |
| Extensions Support | desactivado | No se usa GDExtension. |
| **Thread Support** | **desactivado** | Es la opción que desactiva las cabeceras de aislamiento de origen (COOP/COEP). Con ella activada el juego exige `SharedArrayBuffer` y queda en pantalla negra en itch.io salvo que se habilite el soporte correspondiente en la página. |
| Progressive Web App | desactivado | Innecesario para la entrega y añade archivos al ZIP. |
| Export With Debug | desactivado | Es la "opción de depuración" de la guía: se exporta en modo release. |

La carpeta `build/` ya está ignorada por `.gitignore`, de modo que los
artefactos de exportación no entran al repositorio.

## 4. Prueba local antes de publicar

Godot sirve la versión Web con **Ejecutar en navegador** (el icono del globo en
la esquina superior derecha). Abrir el `index.html` con doble clic **no
funciona**: el navegador bloquea las peticiones `file://` y la pantalla queda
en negro.

Pruebas a realizar en el navegador:

1. Recorrer vestíbulo → sala de lectura → sacar un ejemplar.
2. Devolverlo desde Préstamos activos y comprobar que se gana un pase.
3. Canjear el pase sobre otro préstamo.
4. **Cerrar la pestaña, volver a abrirla** y comprobar que los préstamos siguen
   ahí y que el pase canjeado no reapareció.

## 5. Dónde vive el guardado

`user://save_data.json` resuelve a destinos distintos según la plataforma:

| Plataforma | Ubicación |
| --- | --- |
| Escritorio | Carpeta de datos del usuario (**Proyecto → Abrir carpeta de datos del usuario**). |
| Navegador | IndexedDB, bajo el origen de la página. |

Esto importa para la prueba: en el navegador el guardado queda atado al origen,
así que una ventana de incógnito arranca sin datos y borrar los datos del sitio
equivale a borrar la partida. Por eso el panel de préstamos incluye el botón
**Vaciar el registro guardado**: es la única forma cómoda de repetir la prueba
de persistencia desde la versión Web.

## 6. Publicación en itch.io

1. Comprimir **el contenido** de `build/web/` en un ZIP, con `index.html` en la
   raíz del archivo y no dentro de una subcarpeta.
2. En itch.io: **Create new project** → *Kind of project*: **HTML**.
3. Subir el ZIP y marcar **This file will be played in the browser**.
4. Fijar el tamaño del lienzo en **1152 × 648**, que es el viewport del
   proyecto.
5. Dejar *Visibility & access* en **Draft** y copiar la **URL secreta**.
6. Abrir esa URL en una ventana de incógnito, sin sesión iniciada, y repetir la
   prueba de persistencia del punto 4.
7. Registrar la URL en `DEVLOG.md`.
