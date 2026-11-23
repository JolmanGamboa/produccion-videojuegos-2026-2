# DEVLOG — Bitácora de desarrollo

Registro cronológico de decisiones técnicas, obstáculos y aprendizajes del
proyecto integrador de Producción de Videojuegos 2026-2.

---

## Entrada 001 — Configuración del entorno e interacción local inicial

**Sprint:** 1 — Fundamentos y arquitectura (semanas 1 y 2)
**Laboratorio:** 1 — Configuración del entorno, arquitectura base e interacción local
**Estado:** Completado

### Objetivo de la sesión

Dejar operativo un entorno portátil de Godot 4.x, definir la arquitectura de
directorios del proyecto e implementar la primera capa de interacción reactiva
local entre nodos de interfaz.

### Trabajo realizado

1. **Entorno y renderizado.** Se configuró el proyecto con el renderizador
   `Compatibility` (`renderer/rendering_method="gl_compatibility"` en
   `project.godot`). Se eligió por encima de Forward+ porque es el único camino
   que garantiza la exportación posterior a HTML5 sin depender de controladores
   Vulkan.

2. **Arquitectura de directorios.** Se creó la jerarquía bajo `src/`
   (`assets/audio`, `assets/textures`, `assets/ui`, `components`, `scenes`,
   `scripts`), dejando la raíz de `res://` limpia. Toda la nomenclatura de
   archivos y carpetas respeta `snake_case`.

3. **Interfaces responsivas.** Se construyeron `main.tscn` y `main_level_1.tscn`
   con nodo raíz `Control` en anclas *Full Rect*. El layout se resuelve con
   `MarginContainer` → `VBoxContainer`, y en el nivel 1 se añadió un
   `GridContainer` de 2 columnas. No se usó ninguna coordenada absoluta.

4. **Lógica de interacción.** Se implementaron `main.gd` y `main_level_1.gd` con
   tipado estático estricto, captura en caché con `@onready` y conexión de
   señales por código. `BtnSalir` invoca `get_tree().quit()`; los botones de
   ingredientes se conectan mediante `.bind()` a un único callback
   `_on_ingrediente_selected(nombre, costo)`.

5. **Control de versiones.** Se inicializó el repositorio con `.gitignore` que
   excluye `.godot/`, `*.translation` y `export_presets.cfg`, y se registró el
   avance en commits atómicos bajo *Conventional Commits*.

### Obstáculos encontrados

- **Escena `main.tscn` corrupta.** La primera versión guardada quedó con un nodo
  raíz sin tipo declarado y una conexión de señal apuntando a un botón
  inexistente, lo que impedía instanciar la escena. Se reconstruyó la jerarquía
  completa desde cero con el nodo raíz `Control`.
- **Navegación cruzada incorrecta.** Ambos botones de navegación terminaban en el
  mismo destino porque las conexiones de señal estaban mal asignadas. Se rehízo el
  cableado adoptando una convención explícita: cada callback de `change_scene.gd`
  se nombra por la escena **donde reside el botón**, no por el destino. Así,
  `_on_button_pressed_main` (BtnSimular, en `main.tscn`) avanza al nivel 1 y
  `_on_button_pressed_main_level_1` (BtnVolver, en `main_level_1.tscn`) regresa al
  menú.
- **Interfaz amontonada en la esquina.** Al posicionar los controles con offsets
  en píxeles, la interfaz se rompía al redimensionar la ventana. Se sustituyó por
  contenedores lógicos y anclas.

### Decisiones técnicas

- Centralizar las rutas de escena como constantes dentro de `SceneChanger` en
  lugar de escribirlas literalmente en cada controlador, para reducir el costo de
  refactorización cuando el proyecto crezca.
- Usar `.bind()` con un callback unificado en lugar de una función por botón:
  al añadir nuevos ingredientes solo se agrega una línea de conexión, sin
  duplicar lógica.

### Próximos pasos

- Extraer el botón de ingrediente a una micro-escena reutilizable en
  `src/components/`.
- Introducir señales personalizadas (`signal`) para desacoplar la capa de datos
  de la capa de presentación.
- Configurar el preset de exportación a HTML5 y validar el renderizado en
  navegador.

---

## Entrada 002 — Refactorización a arquitectura modular con Event Bus

**Sprint:** 1 — Fundamentos y arquitectura (semanas 2 y 3)
**Laboratorio:** 2 — Escenas, nodos y navegación desacoplada
**Estado:** Completado

El objetivo de esta sesión fue eliminar el acoplamiento por rutas absolutas que
arrastraba el Laboratorio 1 y darle al proyecto una identidad concreta: una
**Biblioteca Interactiva 2D** de estantes temáticos. Se disolvió la carpeta
global `src/scripts/` y se aplicó co-localización estricta: cada panel vive con
su controlador en su propio módulo (`src/scenes/menu/`, `step_1/`, `config/`,
`credits/`), y la lógica transversal quedó en `src/core/`. La navegación pasó de
`get_tree().change_scene_to_file()` a la publicación de `navigation_requested`
en un Autoload `EventBus`, con `MainApp` como único suscriptor autorizado a
tocar el árbol; la justificación formal quedó en el ADR 0001. El obstáculo real
no fue técnico sino de diseño: al principio dejé que cada panel resolviera su
propio destino, lo que reproducía el acoplamiento anterior con otra sintaxis; la
corrección fue mover el catálogo de rutas al bus y aceptar que los paneles solo
publican intenciones, nunca decisiones. La liberación de memoria se centralizó
en un único método con `queue_free()` y anulación explícita de la referencia,
verificable en el *Debugger* por el conteo de nodos. Aprendizaje central: el
desacoplamiento no consiste en esconder las rutas, sino en trasladar la
**autoridad** de conmutar escenas a un solo punto del sistema.

### Próximos pasos

- Extraer el botón de libro a una micro-escena reutilizable en `src/components/`
  y generar los estantes por iteración sobre datos, no por nodos fijos.
- Mover el catálogo de libros a un recurso externo (`.json` o `Resource`
  personalizado) para separar por completo datos y presentación.
- Sustituir los botones planos por estanterías 2D con `Sprite2D` y navegación
  por *hover*, camino al prototipo visual del proyecto final.

---

## Entrada 003 — Consolidación del canal de eventos y registro de la estructura

**Sprint:** 1 — Fundamentos y arquitectura
**Laboratorio:** 3 — Navegación desacoplada (verificación y cierre)
**Estado:** Completado

Esta sesión no agregó funcionalidad nueva: se dedicó a verificar que el
desacoplamiento introducido en el laboratorio anterior resistiera el crecimiento
del sistema y a documentar formalmente la organización física del proyecto. Se
auditó con el Depurador que cada transición de panel liberara efectivamente el
nodo saliente, comprobando el conteo en el Árbol de escenas remoto, y se revisó
que ninguna escena conservara referencias a rutas de otras escenas. El hallazgo
relevante fue que el criterio de organización por tipo de archivo (`scenes/`
frente a `scripts/`) ya no describía la arquitectura real del sistema, por lo
que se decidió agrupar por dominio funcional y dejarlo asentado en el ADR-002.
La dificultad fue de criterio más que de código: distinguir qué pertenece a
`core/` por ser transversal y qué pertenece a un módulo por ser específico de
una pantalla. La regla adoptada es simple y verificable: algo sube a `core/`
solo cuando lo consume más de un módulo.

---

## Entrada 004 — Registro de préstamos, componentes reutilizables y cierre del Sprint 1

**Sprint:** 1 — Entrega integradora (Sprint Review 1)
**Laboratorio:** 4 — GlobalManager, ButtonNav e historial de navegación
**Estado:** Completado

El laboratorio final del sprint atacó las dos deudas que quedaban vivas. La
primera era que los datos de la simulación vivían dentro del panel que los
mostraba, de modo que `queue_free()` los destruía junto con la interfaz: el dato
tenía la vida útil de un nodo visual, cuando un préstamo de biblioteca debe
seguir vigente aunque el lector cierre la sala. Se creó `GlobalManager` como
Autoload con un `Dictionary` que mapea cada ejemplar con su plazo, y se le dio
el monopolio del cálculo; la sala de lectura quedó reducida a emitir intenciones
(`base_selected`, `item_added`) y a escuchar el resultado. Los tres plazos
—diario, quincenal y mensual— se definieron como constantes del dominio, junto
con el catálogo de ejemplares, de forma que cambiar una duración es editar una
línea. La segunda deuda era la repetición del botón de regreso en cada pantalla,
resuelta con el componente `ButtonNav` parametrizado desde el Inspector, que
permitió eliminar por completo `config_panel.gd` y `credits_panel.gd`.

El obstáculo real apareció al montar un panel nuevo: nacía vacío porque nunca
había escuchado la última notificación del gestor. La tentación fue que el panel
consultara a `GlobalManager` en su `_ready()`, pero eso habría reintroducido
justo la dependencia que el bus eliminó; la solución fue que `MainApp` pida al
gestor reemitir su estado tras instanciar la escena, de modo que la
sincronización viaje por el mismo canal reactivo. Esa decisión se validó sola
al construir la pantalla de Préstamos activos: no hubo que tocar el gestor ni la
sala de lectura, bastó con suscribirse a `loans_updated` y dibujar el
diccionario recibido. La pila `navigation_history` cerró el trabajo haciendo
explícito, y auditable en consola, un flujo que hasta ahora era implícito.

### Balance del Sprint 1

El proyecto pasó de un prototipo con navegación acoplada por rutas absolutas a
un sistema con tres separaciones claras: la interfaz muestra, el bus comunica y
el gestor decide. La lección transversal de los cuatro laboratorios es que
desacoplar no consiste en esconder dependencias tras una indirección, sino en
trasladar la **autoridad** a un único punto responsable de cada cosa.

### Próximos pasos (Sprint 2)

- Mover el catálogo de ejemplares a un recurso externo, separando datos de
  código.
- Recuperar los estantes temáticos del Laboratorio 2 y generarlos por iteración
  sobre datos en lugar de nodos fijos.
- Sustituir los botones planos por estanterías 2D con `Sprite2D` y navegación
  por *hover*, primer paso del prototipo visual del producto final.

---

## Entrada 005 — Máquina de estados del ciclo del ejemplar y animaciones Tween

**Sprint:** 2 — Mecánicas y comportamiento
**Laboratorio:** 6 — FSM y animaciones programáticas
**Fecha:** 01/10/2026
**Estado:** Completado

Se modeló el **ciclo del ejemplar** con una máquina de estados alojada en
`GlobalManager`: `en_estante` (ningún libro abierto), `en_consulta` (ficha
visible, admite plazo), `registrando` (el mostrador sella el préstamo y todo
queda congelado) y `prestado` (confirma y cierra el ciclo). Las transiciones
permitidas viven en la tabla `TRANSICIONES` y todas pasan por
`_cambiar_estado()`, que rechaza cualquier salto ausente y lo registra en
consola. La dificultad principal fue que elegir dos veces un plazo registraba el
mismo ejemplar otra vez: se resolvió haciendo que la entrada a `registrando` sea
una transición, de modo que la segunda solicitud se descarta sola. La segunda
dificultad fue el ritmo: al principio la animación terminaba después del cambio
de estado y dejaba la ficha atenuada; se le dio duración real al estado
`registrando` y la interfaz anima dentro de esa ventana. También se movió el
ejemplar en consulta al estado global, para que salir a Préstamos activos y
volver no pierda la consulta abierta. El `Tween` encoge y atenúa la ficha
mientras el préstamo se sella, y el veredicto entra con un destello verde o
rojo; durante esa animación el estante y las devoluciones quedan bloqueados.

**Próximos pasos:** marcar en el estante los ejemplares ya prestados, estudiar
un estado `vencido` cuando el plazo se cumpla, y preparar el Vertical Slice y la
exportación Web del Laboratorio 7.

### Retrospectiva

- **¿Qué ventaja obtuve al modelar el comportamiento mediante estados?** Que los
  estados imposibles dejaron de ser alcanzables: la tabla de transiciones es la
  especificación y el código no puede contradecirla.
- **¿Qué transición fue más difícil?** `registrando → prestado`, porque es la
  única que ejecuta la regla de negocio (escribir el préstamo y recalcular) y
  había que garantizar que ocurriera exactamente una vez.
- **¿Qué aporta el Tween?** Vuelve visible algo que antes solo pasaba en la
  lógica: el lector ve la ficha salir hacia el mostrador y entiende por qué,
  durante ese instante, los botones no responden.
- **¿Qué cambiaría si el componente incorporara nuevos estados?** Nada
  estructural: se agrega el estado al `enum` y sus transiciones a la tabla. El
  costo está en las pantallas, que deben saber representarlo.

---

## Entrada 006 — Vertical Slice: persistencia, refinamiento visual y versión Web

**Sprint:** 2 — Mecánicas y comportamiento (Sprint Review 2)
**Laboratorio:** 7 — Vertical Slice, persistencia y publicación Web
**Fecha:** 17/10/2026
**Estado:** Completado

### Actividades realizadas

Se cerró el ciclo que venía abierto desde el Sprint 1: el estado de la
biblioteca ya no muere con el proceso. `GlobalManager` estrena `guardar_datos()`
y `cargar_datos()` —las funciones que la guía llama `save_coupons()` y
`load_coupons()`— escribiendo `user://save_data.json` con `FileAccess` y `JSON`.
La carga ocurre en `_ready()` antes del primer cálculo y el guardado tras cada
cambio del registro, no al salir.

Sobre esa base se montó la mecánica de recompensa adaptada al dominio de la
biblioteca: **devolver un ejemplar entrega un pase de lectura**, y ese pase se
**canjea** para ampliar siete días el plazo de otro préstamo vigente. Es el
ciclo obtener → guardar → consumir que pide el laboratorio, con la ventaja de
que ambos extremos cuelgan de acciones que el proyecto ya tenía. El panel de
préstamos muestra los pases disponibles con su origen y añade a cada fila un
botón de ampliación.

El refinamiento visual se resolvió con un recurso `Theme` único
(`src/assets/ui/biblioteca_theme.tres`) registrado como tema por defecto del
proyecto: botones con sus cuatro estados, paneles, colores de texto y
variaciones tipográficas para títulos, subtítulos, fichas y destacados. Las
pantallas dejaron de llevar tamaños de fuente sueltos y el vestíbulo, la
configuración y los créditos limitan el ancho de su columna y la centran, de
modo que los controles ya no se estiran de borde a borde.

### Desafíos encontrados y soluciones aplicadas

**Dos fallas heredadas del Laboratorio 6 aparecieron al recorrer el flujo
completo.** La primera: salir de la sala con un ejemplar en consulta y regresar
dejaba la ficha vacía mientras los botones de plazo seguían habilitados, de modo
que elegir uno publicaba `item_added("")` y el mostrador respondía que el
ejemplar no pertenecía al catálogo. La causa era que el ejemplar abierto vivía
como variable local de la pantalla, y la pantalla se destruye al navegar. Se
promovió ese dato al estado global y se añadió la señal `consultation_changed`,
que el gestor reemite al montarse cualquier panel. La segunda: un lomo ya
prestado se podía abrir, elegir plazo y esperar el registro completo para
recibir solo entonces el rechazo; ahora la sala escucha `loans_updated` y marca
esos lomos como prestados antes de que el lector lo intente.

**JSON no conserva tipos ni garantiza que el archivo siga siendo válido.** Un
guardado editado a mano, truncado o de una versión anterior del esquema habría
entrado al estado sin que nada lo detuviera. La carga pasó a reconstruir cada
préstamo y cada pase contra el catálogo y la tabla de plazos, descartando lo que
no valide, y a comprobar un campo `version`; ante un archivo ilegible se arranca
con la sala vacía. El total de días, en cambio, se dejó fuera del guardado a
propósito: es un valor derivado y se recalcula al cargar, así no puede quedar
desincronizado del registro.

**Repetir la prueba de persistencia era incómodo.** En escritorio obligaba a
borrar `save_data.json` a mano; en el navegador, donde el archivo vive en
IndexedDB, directamente no había forma. Se añadió al panel de préstamos un botón
que vacía el registro y reescribe el archivo, con la guarda de rechazarlo si hay
una consulta o un registro en curso.

### Publicación

- **URL secreta de itch.io:** _(pendiente de registrar tras la publicación)_
- Ajustes del preset Web documentados en [`doc/web-export.md`](doc/web-export.md).

### Estado final del Vertical Slice

El recorrido completo funciona de extremo a extremo: vestíbulo → sala de lectura
→ consulta de la ficha → elección de plazo → registro animado del préstamo →
panel de préstamos → devolución que entrega un pase → canje del pase sobre otro
préstamo. Todo ello sobrevive a cerrar y reabrir el proyecto, y un pase
consumido no reaparece. Las cinco pantallas comparten tipografía, botones,
paneles y paleta.

### Retrospectiva

- **¿Qué cambio técnico fue más importante para convertir el prototipo en un
  Vertical Slice?** La persistencia, pero no por el archivo en sí: por lo que
  obligó a decidir. Guardar el estado exige responder qué es dato y qué es
  valor derivado, y esa separación es la que hace que el proyecto se comporte
  como un producto y no como una demostración.
- **¿Qué problema encontró al implementar la persistencia y cómo lo
  solucionó?** Que al cargar, el sistema confiaba en el archivo. Se resolvió
  reconstruyendo cada registro contra el catálogo y la tabla de plazos en vez
  de asignarlo tal cual, y versionando el esquema.
- **¿Qué mejora visual tuvo mayor impacto?** Limitar el ancho de la columna en
  las pantallas de texto. El tema unificado ordena, pero lo que más se nota es
  que los botones dejaron de medir mil píxeles de ancho.
- **¿Qué diferencia encontró entre ejecutar el proyecto en Godot y ejecutarlo
  como versión Web?** Que `user://` cambia de destino sin avisar: en escritorio
  es una carpeta que se puede abrir e inspeccionar, y en el navegador es
  IndexedDB atado al origen de la página. El código es el mismo, pero probar la
  persistencia no lo es: una ventana de incógnito arranca siempre vacía.
- **¿Qué debería mejorarse en el siguiente Sprint?** Mover el catálogo a un
  recurso externo, que sigue siendo una constante dentro del gestor, y agregar
  el estado `VENCIDO` para que el plazo signifique algo más que un número.

---

## Entrada 007 — Diseño de interfaces, experiencia de usuario y accesibilidad

**Sprint:** 3 — Experiencia de usuario e interfaces
**Laboratorio:** 8 — UI, UX y accesibilidad hacia la Versión Beta
**Fecha:** 20/10/2026
**Estado:** Completado en la parte de implementación; la evaluación con usuario
real queda pendiente de registrar en `USER_FEEDBACK.md`.

### Actividades realizadas

El recurso de tema pasó a llamarse `ui_theme.tres` y, además de seguir siendo el
tema por defecto del proyecto, quedó asignado a la propiedad `Theme` del nodo
raíz de las seis escenas con interfaz, de modo que la herencia se ve desde el
Inspector y no depende solo de la configuración del proyecto. Define los cuatro
estados del botón con `StyleBoxFlat` —Normal, Hover, Pressed y Disabled— más el
estado de foco.

El vestíbulo estrena un `TextureRect` con una vista de la sala (estanterías,
escalera y mesa de lectura) con `z_index` en −1 y `Mouse Filter` en *Ignore*, y
once iconos de línea acompañan a las acciones recurrentes: libro, tarjeta,
deslizadores, persona y salida en el menú; flecha para volver, aspa para cerrar,
papelera para vaciar, reloj con signo más para ampliar y flecha de retorno para
devolver.

Registrar un préstamo —la acción crítica del flujo— terminaba con una línea de
texto fácil de pasar por alto. Ahora levanta `PrestamoSuccessPopup`, un panel
oculto por defecto con velo, título, el detalle de lo que salió de la sala y dos
salidas: seguir en la sala o ir a Préstamos activos mediante una instancia de
`ButtonNav`.

### Desafíos y soluciones

- **Desafío:** el `TextureRect` de fondo se interponía entre el ratón y los
  botones del menú.
  **Solución:** `Mouse Filter` en *Ignore*, de modo que decora sin participar en
  la entrada.

- **Desafío:** con `z_index` en −1, el fondo dejó de verse por completo. La
  causa no estaba en el vestíbulo sino en `MainApp`, que tiene un `ColorRect`
  opaco a pantalla completa como telón de toda la aplicación: al estar en z 0 y
  el fondo en z −1, el fondo se dibujaba *antes* y el telón lo tapaba. El
  enunciado sugiere el z negativo dando por hecho que el menú es la escena raíz,
  cosa que aquí no ocurre porque todas las pantallas se inyectan dentro del
  orquestador.
  **Solución:** declarar las capas en vez de darlas por supuestas. El telón
  global bajó a −2, la decoración de pantalla se queda en −1 y la interfaz en 0.

- **Desafío:** con una imagen detrás, el texto del menú podía perder contraste.
  **Solución:** se midió el píxel más claro de la franja central que ocupa la
  columna de botones (#3A2C19) y se calculó el contraste contra cada color de
  texto: 10.94:1 el cuerpo, 8.14:1 el título y 5.56:1 el subtítulo. Todos por
  encima del 4.5:1 de WCAG AA, así que no hizo falta añadir un velo.

- **Desafío:** Configuración y Créditos no tienen script desde el Laboratorio 4,
  así que no podían reclamar el foco del teclado al montarse.
  **Solución:** `ButtonNav` estrena la propiedad exportada `initial_focus`, con
  lo que esos paneles siguen siendo navegables sin ratón sin recuperar un
  controlador.

### Mejoras de accesibilidad implementadas

1. **Contraste del botón deshabilitado, de 3.07:1 a 4.53:1.** WCAG exime a los
   controles inactivos, pero en este proyecto un botón apagado *comunica*: dice
   que un ejemplar está prestado o que no quedan pases. Si comunica, tiene que
   leerse.
2. **Navegación completa por teclado.** Cada pantalla reclama el foco de un
   control al montarse y los cinco destinos del vestíbulo encadenan
   `focus_neighbor` con vuelta circular. El borde de foco del tema mide 6.59:1
   contra el fondo del botón.
3. **Información independiente del color.** Los veredictos llevan los prefijos
   *Listo* y *Atención* además del verde y el rojo, y un ejemplar prestado se
   marca con la palabra *prestado* en su etiqueta, no solo apagando el botón.

### Estado final

La interfaz quedó unificada bajo un único recurso de tema, con retroalimentación
explícita en la acción crítica del flujo y utilizable sin ratón. Falta cerrar el
laboratorio con la evaluación de usabilidad: la plantilla y el guion para
conducirla están en `USER_FEEDBACK.md`.

### Retrospectiva

- **¿Qué cambio de interfaz mejoró significativamente la experiencia?** El popup
  de confirmación. El resto son mejoras de acabado; esa es la única que cierra
  un vacío real, porque antes la acción más importante del sistema terminaba
  sin acuse de recibo.
- **¿Qué dificultad presentó el tema centralizado?** No crearlo, sino decidir
  qué dejar fuera. La tentación es que el tema lo resuelva todo, pero las
  decisiones de disposición —anchos, márgenes, separaciones— no le pertenecen y
  meterlas allí habría vuelto el recurso imposible de reutilizar.
- **¿Qué aportó la prueba con el usuario real?** _(pendiente de la evaluación;
  se registrará en `USER_FEEDBACK.md`)_
- **¿Por qué estas dos mejoras de accesibilidad?** Porque atacan fallos que el
  proyecto tenía de verdad, no casos hipotéticos: el sistema era inoperable sin
  ratón, y había texto por debajo del umbral de contraste. Medir antes de
  decidir es lo que convirtió la accesibilidad en una corrección verificable en
  lugar de una declaración de intenciones.
- **¿Qué entendería un usuario nuevo de inmediato y qué no?** El recorrido de
  sacar un libro se explica solo: estante, ficha, plazo. Los pases de lectura
  son el punto débil —aparecen al devolver, sin que nada los haya anunciado
  antes—, y es lo primero que conviene observar en la evaluación.

---

## Entrada 008 — Catálogo en recursos e interfaz generada a partir de los datos

**Sprint:** 3 — Experiencia de usuario e interfaces
**Laboratorio:** 9 — Interfaz dinámica y representación de datos mediante Resources
**Fecha:** 23/10/2026
**Estado:** Completado

### Actividades realizadas

El catálogo dejó de ser una constante dentro del gestor. Ahora son tres clases
que heredan de `Resource` en `src/data/` —`LibroData`, `CategoriaData` y
`CatalogoBiblioteca`— con sus campos exportados, y un recurso `catalogo.tres`
que `GlobalManager` carga con `preload()`. Las consultas sobre los datos
(filtrar por estante, buscar por identificador, contar) viven en el catálogo y
no en el gestor, porque son preguntas sobre qué existe y no sobre qué está
prestado.

Sobre esa base se añadió la pantalla de **estantes**, que construye una tarjeta
por categoría recorriendo la colección, y la **sala de lectura** pasó a generar
sus lomos a partir de los ejemplares del estante activo dentro de un
`ScrollContainer`. Ninguna de las dos tiene sus elementos puestos a mano: el
catálogo creció de cuatro a diecisiete ejemplares y de un estante a cuatro sin
añadir un solo nodo a ninguna escena.

Se incorporó el **comprobante de préstamo**, la factura que pide el laboratorio:
muestra el ejemplar con los datos del recurso, desglosa los días entre el plazo
elegido y los que aportan los pases, y permite aplicarlos antes de confirmar.
La máquina de estados ganó `EN_COMPROBANTE` entre la consulta y el registro.

### Desafíos y soluciones

- **Desafío:** elegir un plazo registraba el préstamo de inmediato, así que no
  había dónde aplicar un pase antes de que el ejemplar saliera de la sala.
  **Solución:** separar la intención del efecto. Elegir un plazo arma ahora un
  borrador; el registro solo se escribe al confirmar en el comprobante. Como
  consecuencia, cancelar no deja rastro, cosa que antes no era cierta.

- **Desafío:** los diecisiete ejemplares eran demasiados para cargarlos a mano
  en el Inspector sin erratas.
  **Solución:** `tools/build_catalogo.gd`, una herramienta de autor que genera
  el recurso de una pasada. A partir de ahí el catálogo es un `.tres` normal y
  se edita en el editor; la herramienta queda documentada con la advertencia de
  que lo reescribe entero.

- **Desafío:** cambiar el esquema del registro podía invalidar los guardados
  existentes, que ya tenían préstamos con los identificadores antiguos.
  **Solución:** conservar los cuatro identificadores que ya existían —`dune`,
  `neuromante`, `cien_anios` y `pragmatico`— de modo que el saneamiento del
  Laboratorio 7 siga validándolos contra el catálogo sin descartarlos.

- **Desafío:** el estante activo se perdía al cerrar el proyecto.
  **Solución:** sumarlo al estado persistido. Reabrir devuelve al mismo estante
  que se estaba recorriendo, y el campo nuevo no rompe los guardados anteriores
  porque se lee con un valor por omisión.

### Estado final

El recorrido completo quedó así: vestíbulo → estantes → sala del estante
elegido → ficha del ejemplar → plazo → comprobante con aplicación de pases →
confirmación → préstamos activos. Todo el contenido de las dos pantallas
listadas sale del catálogo; añadir un estante o un ejemplar no obliga a tocar
código. La justificación completa está en `ADR-006.md`.

### Retrospectiva

- **¿Qué ventaja técnica observé al separar los datos de la interfaz que los
  representa?** Que el cambio de tamaño dejó de ser un cambio de código.
  Cuadruplicar el catálogo no tocó ninguna escena, y esa es la prueba de que la
  separación es real y no solo una reorganización de archivos.
- **¿Por qué es más eficiente generar la interfaz por código que dibujarla en
  el editor?** Porque dibujarla obliga a decidir de antemano cuántos elementos
  habrá, y esa decisión es exactamente la que el dato debería tomar. Con cuatro
  libros parecía un detalle; con diecisiete repartidos en estantes de distinto
  tamaño, dibujarla a mano ya no era posible.
- **¿Cómo ayuda la arquitectura basada en recursos a que el proyecto crezca?**
  Porque convierte una tarea de programación en una de edición: sumar un
  ejemplar es llenar campos en el Inspector, algo que puede hacer alguien que no
  escriba GDScript.
- **¿Qué aspecto del EventBus facilitó integrar la interfaz nueva con los pases
  del laboratorio anterior?** Que los pases ya se publicaban por el bus, así que
  el comprobante no tuvo que aprender a leerlos: se suscribió a
  `passes_updated` y publicó `draft_pass_applied`. La pantalla nueva se enchufó
  a un sistema que no sabía que iba a existir.

---

## Entrada 009 — Depuración con breakpoints, pruebas unitarias con GdUnit4 y QA

**Sprint:** 3 — Experiencia de usuario, calidad y mantenimiento
**Laboratorio:** 10 — Depuración, pruebas unitarias y aseguramiento de calidad
**Fecha:** 08/11/2026
**Estado:** Completado

### Actividades realizadas

Se instaló **GdUnit4 6.2.3** y quedó versionado en `addons/gdUnit4`, de modo que
el proyecto se clona y las pruebas corren sin instalar nada aparte. El plugin
está habilitado en `project.godot`, así que el dock de GdUnit aparece al abrir
el proyecto.

La suite vive en `res://tests/` y son **cuatro archivos con treinta casos**,
repartidos por nivel de prueba:

| Suite | Nivel | Casos |
| --- | --- | --- |
| `test_global_manager.gd` | Unitaria | 13 |
| `test_catalogo_biblioteca.gd` | Unitaria (reto autónomo) | 9 |
| `test_flujo_prestamo.gd` | Integración y sistema | 5 |
| `test_persistencia.gd` | Regresión | 3 |

La distinción entre los dos primeros grupos y el tercero no es de tamaño sino de
qué se está midiendo. Las suites unitarias construyen su propia instancia de
`GlobalManager` con `new()` y **no la añaden al árbol**, así que `_ready()` no se
ejecuta: no hay suscripciones al bus ni lectura de disco, y lo único que se mide
es la función bajo prueba. La suite de integración hace lo contrario: no llama a
ninguna función por su nombre, publica intenciones en el `EventBus` y comprueba
qué hizo el Autoload real con ellas.

El diseño de los casos quedó documentado en **`TEST_REPORT.md`** con los tres
niveles que pide la guía: UNI-01 sobre el cálculo de los días comprometidos,
INT-01 sobre el plazo que viaja por el bus hasta el comprobante y SIS-01 sobre
el ciclo completo con escritura y relectura del guardado. El reto autónomo tomó
las cuatro consultas de `CatalogoBiblioteca`, con casos normales, negativos,
límite y de coherencia del recurso publicado.

El guion de la sesión de depuración está en **`registro_depuracion.md`**, con
los dos puntos de ruptura elegidos —el cierre de `cargar_datos()` y la consulta
a la tabla de transiciones en `_cambiar_estado()`—, las variables que hay que
inspeccionar y las pilas de llamadas esperadas.

### Defectos encontrados y corregidos

La suite encontró tres defectos reales, los tres en el guardado. Ninguno se
manifestaba jugando:

1. **`cargar_datos()` dejaba el total descuadrado.** Restituía los préstamos
   del disco pero no recalculaba `total_dias`, así que el estado quedaba con los
   préstamos nuevos y el total anterior. No se notaba porque `_ready()`
   recalculaba justo después de cargar; el descuadre solo aparecía al invocar
   `cargar_datos()` por separado, que es lo que hace SIS-01.
2. **`plan_activo` entraba del disco sin validarse.** Era el único campo del
   guardado que no pasaba por su tabla, al contrario que `prestamos` y
   `categoria_activa`. Desde ahí podía llegar a `dias_de()`, que busca el plan
   en `DURACIONES_PLAN` sin comprobar que exista.
3. **Los identificadores de pase se repetían tras vaciar el registro.**
   `_on_save_reset_requested()` reiniciaba `pases_emitidos` a cero, justo el
   contador que se persiste para que los identificadores no se repitan entre
   sesiones.

Los tres quedaron registrados como Issues en GitHub, corregidos en esta rama y
con una prueba de regresión cada uno en `tests/test_persistencia.gd`.

### Desafíos y soluciones

**Las pruebas que tocan el Autoload tocan la partida del lector.** La suite de
integración y la de regresión usan el `GlobalManager` real, que escribe en
`user://save_data.json`. Ejecutar las pruebas borraba los préstamos de la sesión
de quien las corriera. Se resolvió respaldando `estado` en `before()` con
`duplicate(true)` y restituyéndolo en `after()`, reescribiendo el archivo al
terminar.

**El estado del ciclo se fija a mano en el montaje.** Para dejar cada caso en un
punto de partida limpio hay que volver a `EN_ESTANTE`, y hacerlo por la puerta
del dominio obligaría a recorrer el ciclo entero solo para regresar al
principio. Las pruebas asignan `_estado_prestamo` directamente y lo declaran en
un comentario: es montaje de la prueba, no una transición del dominio.

**El estado `REGISTRANDO` dura de verdad.** El gestor espera un temporizador de
0,6 s para que la animación del sello y el cambio de estado terminen juntos, así
que SIS-01 no podía afirmar nada inmediatamente después de confirmar. Se resolvió
con `await await_millis()` sobre la duración declarada en la constante, en vez de
un número suelto que se desincronizaría al cambiarla.

**GdUnit4 rechaza el modo headless.** Lo hace porque los `InputEvent` de Godot no
se transportan sin ventana y las pruebas de interfaz darían falsos verdes. Esta
suite no simula entrada de usuario, así que se ejecuta con
`--headless --ignoreHeadlessMode`, documentado en el `TEST_REPORT.md`.

### Estado final

Treinta casos en cuatro suites, todos pasando, sin errores ni nodos huérfanos.
Con eso se cierra el Sprint 3 y el proyecto queda en **versión Beta**.

### Retrospectiva

- **¿Cuál fue el error o comportamiento inesperado más difícil de detectar
  mediante breakpoints y por qué?** El total descuadrado de `cargar_datos()`,
  porque con el depurador solo se ve si uno ya sospecha dónde mirar: al arrancar
  el programa el total terminaba bien, así que no había nada anómalo que
  observar. Lo encontró la prueba, no el depurador; el depurador sirvió después
  para ver el instante exacto en que el estado estaba a medias.
- **¿Qué ventaja ofrece ejecutar pruebas unitarias automatizadas con GdUnit4
  frente a probar el juego manualmente?** Que prueban lo que a mano no se
  prueba. Verificar el saneamiento del guardado jugando exigiría editar el JSON
  a mano cinco veces y reiniciar entre cada una; aquí son cinco casos que corren
  en milisegundos y vuelven a correr solos cada vez que se toca el gestor. La
  prueba manual sigue siendo necesaria para la interfaz, que es lo que la suite
  deliberadamente no cubre.
- **¿Qué diferencia principal existe entre una prueba unitaria aislada y una
  prueba de integración vía EventBus?** La unitaria llama a la función por su
  nombre, así que pasa aunque el bus esté desconectado. Si `GlobalManager`
  dejara de suscribirse a `base_selected`, las trece pruebas unitarias seguirían
  verdes y el proyecto estaría roto: elegir un plazo no llegaría a ninguna parte.
  Lo que detecta eso es la de integración, que no llama a nada y solo publica.
- **¿De qué manera la gestión de incidencias en GitHub Issues ayudó a organizar
  la estabilización de la Versión Beta?** Porque separó encontrar de arreglar.
  Los tres defectos aparecieron mientras se escribían las pruebas, en medio de
  otra tarea; anotarlos como Issues permitió terminar la suite primero y
  corregirlos después, cada uno con su prueba de regresión y su commit, en vez de
  dejar tres arreglos a medias mezclados con el trabajo del laboratorio.

---

## Entrada 010 — Sprites animados dirigidos por el estado del objeto

**Sprint:** 3 — Cierre de la versión Beta
**Fecha:** 12/11/2026
**Estado:** Completado

### Actividades realizadas

La entrega pedía sprites animados y una mecánica que cambiara el estado de un
objeto de modo que su animación cambiara con él. **La mecánica ya existía**: el
ciclo del ejemplar del Laboratorio 6, con su tabla de transiciones y su única
función de cambio. Lo que faltaba era que ese estado se viera, porque hasta
ahora solo se comunicaba con texto y con el color de una etiqueta.

Se añadieron dos componentes reutilizables en `src/components/sprites/`,
hermanos de `ButtonNav`:

- **`LibroAnimado`** traduce el estado del ciclo a una animación del ejemplar:
  cerrado en el estante, abriéndose al consultarlo, pasando hojas en bucle
  mientras se lee la ficha, cerrándose al registrar el préstamo y de canto
  cuando sale de la sala.
- **`RelojPlazo`** hace lo mismo con el estado del plazo de cada préstamo: aro
  verde, dorado, naranja o rojo, con la aguja girando más deprisa cuanto menos
  queda.

El segundo componente es el que demuestra que el patrón no estaba atado a la
FSM. El estado del reloj no sale de una máquina de estados sino de una cuenta
—cuántos días quedan sobre cuántos se pidieron— y al componente le da igual de
dónde venga.

Para que esa cuenta existiera hubo que convertir el plazo en tiempo que corre.
Cada préstamo guarda ahora `inicio`, y todas las cuentas pasan por `ahora()`.
De ahí salen `dias_restantes()` y `estado_plazo()`. El esquema del guardado
subió a la versión 2 con migración de los archivos de la versión 1.

La configuración de sala estrenó el **calendario adelantable**: tres botones que
corren el calendario un día, una semana o un mes. Como todas las cuentas pasan
por `ahora()`, nada dentro del dominio distingue un día adelantado de uno
transcurrido.

Los dos recursos `SpriteFrames` —setenta y cuatro recortes entre ambos— los
genera `tools/build_sprite_frames.gd`, por la misma razón que el catálogo lo
genera su herramienta: no se escriben a mano sin equivocarse.

### Desafíos y soluciones

**Los sprites no entran en la interfaz.** `AnimatedSprite2D` es un `Node2D` y
los contenedores de Godot solo colocan `Control`. Ambos componentes envuelven el
sprite en un `Control` con tamaño mínimo y lo recentran cuando cambia el tamaño.

**Suscribir cada sprite al bus habría sido lo obvio y lo incorrecto.** La sala
construye una tarjeta por ejemplar y solo una está abierta: cada estante habría
puesto cinco oyentes en el bus para que cuatro ignoraran cada evento. La
pantalla, que ya sabe cuál está en consulta, reparte el estado entre sus
tarjetas. Se mantiene un suscriptor por pantalla, como en el ADR-001.

**La animación de apertura no podía quedarse en su último fotograma**, porque la
ficha se queda abierta mientras el lector la mira. El componente encadena
`abriendo` con `pasando_hojas` al terminar, mediante `animation_finished`, sin
que la pantalla temporice nada.

**Añadir un campo al estado rompió una suite que ya pasaba.** El montaje de
`test_flujo_prestamo` reconstruía el diccionario entero y no conocía
`desfase_dias`, así que seis casos empezaron a fallar en cuanto `ahora()` lo
consultó. Es exactamente para lo que está la suite: el fallo apareció en
segundos y no en la sustentación.

**La hoja de sprites venía en otra paleta.** Se recoloreó a los valores del
tema con `tools/build_sprite_libro.py`: cubierta de cuero cálido, hojas en el
crema del texto y filo del título en el dorado. El reloj se generó desde cero en
esa misma paleta con `tools/build_sprite_reloj.py`.

### Accesibilidad

El reloj **no comunica el plazo solo con color**, siguiendo la regla que el
proyecto adoptó en el Laboratorio 8. Cambian tres cosas a la vez: el color del
aro, la velocidad de la aguja y cuánto arco oscuro queda dibujado. Y la fila lo
dice además en palabras: «Quedan 3 días de plazo», «Venció hace 7 días».

### Estado final

Cuarenta y cuatro casos en cinco suites, todos pasando. Catorce son nuevos y
cubren los días restantes, los cuatro tramos del plazo, el adelanto del
calendario, la migración del guardado y la coherencia de los dos recursos de
animación.

### Retrospectiva

- **¿Por qué no hice una máquina de estados nueva para la animación?** Porque
  habría dejado dos modelos del mismo ciclo que mantener sincronizados. El
  estado del ejemplar ya existía y es uno solo; lo que faltaba era enseñarlo.
- **¿Qué aporta que el reloj y el libro compartan patrón?** Que prueba que el
  patrón es general. Uno recibe su estado de una FSM y el otro de una división,
  y los dos componentes se escriben igual: reciben un nombre de estado y
  reproducen la animación que se llama así.
- **¿Qué fue lo más difícil?** Convertir el plazo en tiempo. Animar fue
  cuestión de recortar la hoja; que los días corran obligó a tocar el registro,
  el guardado, su versión y la migración, y a inventar una forma de observar un
  vencimiento sin esperar un mes.

---

## Entrada 011 — Shaders 2D y comunicación visual en tiempo real

**Laboratorio:** 12 — Shaders 2D y comunicación visual en tiempo real
**Fecha:** 22/11/2026
**Estado:** Completado

### Actividades realizadas

La guía está escrita sobre Pizza Rush, pero lo que pide no es «una pizza con
borde» y «una pizza que ondula»: es un shader que comunique que algo se puede
interactuar y otro que comunique que un objeto está en cierto estado. La
traducción al proyecto fue directa, porque el estado ya existía desde el
Laboratorio 6 y desde la Beta ya gobernaba sprites.

Se crearon tres shaders en `res://src/shaders/`:

| Shader | Qué comunica | Dónde |
| --- | --- | --- |
| `contorno_interaccion` | Este ejemplar se puede abrir | Tarjeta de la sala, con el cursor encima |
| `sello_registrando` | El préstamo se está escribiendo | Durante `registrando`, 0,6 s |
| `pulso_plazo` | Cuánto aprieta el plazo | Reloj de cada préstamo activo |

El contorno toma su color de `CategoriaData.color`, de modo que **un único
shader produce cuatro bordes distintos sobre diecisiete ejemplares, sin una sola
textura adicional**. Es exactamente el argumento que hace la sección 0.6 de la
guía sobre parametrizar en vez de dibujar, demostrado con los datos del
proyecto.

El `pulso_plazo` resuelve el Reto 2. El único dato que entra desde GDScript es
un `uniform` de urgencia que se escribe una vez por cambio de tramo; el latido
lo lleva `TIME` dentro del shader, en la GPU. Un `Tween` haría lo mismo a costa
de un nodo y de trabajo en la CPU por cada reloj en pantalla.

La distorsión se asignó a `registrando` y no a `pasando_hojas`. Ondular las
hojas del libro abierto es más bonito, pero ese estado ya se distingue por su
animación; `registrando` dura 0,6 s, no tenía nada que lo señalara salvo que los
botones se apagan, y es justo el momento en que el sistema escribe en disco.

### Desafíos y soluciones

**Las hojas de sprites no tenían margen.** El contorno decide si un píxel linda
con la silueta consultando sus ocho vecinos. En una hoja empaquetada al ras,
esos vecinos son píxeles del fotograma de al lado, y el borde sale dibujado con
la silueta equivocada. Se añadieron dos píxeles transparentes alrededor de cada
celda con `tools/build_sprite_margen.py` y se regeneraron los `SpriteFrames`. Es
el fallo más difícil de diagnosticar del laboratorio, porque el shader es
correcto y aun así se ve mal.

**El contorno no se dibujaba.** La guía indica poner el sprite auxiliar detrás
con un `z_index` negativo. En Pizza Rush funciona porque la pizza está sobre el
tablero; aquí el sprite vive dentro de un `PanelContainer`, y `z_index = -1` lo
mandaba **detrás del fondo de la tarjeta**. El orden de hermanos ya lo pone
delante del sprite principal en el dibujo, así que bastó con quitar el
`z_index`. Lo encontré comparando dos capturas que resultaron ser idénticas pese
a que `contorno.visible` valía `true`.

**El color del estante nunca llegaba al shader.** La sala arma la tarjeta
completa y la añade al árbol después, así que cuando repartía los colores el
`_ready()` del componente todavía no había corrido y el nodo del contorno era
`null`. Se guarda el color pedido y se aplica al estar listo, igual que ya se
hacía con el estado pendiente.

**Un material compartido es un material de todos.** Un `ShaderMaterial` puesto
en la escena lo comparten todas las instancias: fijar el color de un estante se
lo llevaban los demás, y un préstamo vencido hacía latir también los relojes que
iban al día. Ambos componentes duplican su material en `_ready()`.

**El tinte del estante embarraba el dibujo.** Al ver la primera captura
renderizada de verdad quedó claro que multiplicar la cubierta de cuero por el
color del estante la dejaba parda. Ahora el tinte es un lavado suave y la
identidad del estante la lleva el contorno, que sí es ese color.

### Validación

Además de las pruebas, los efectos se verificaron **renderizando de verdad** en
un display virtual y comparando capturas, que es como se encontraron dos de los
cuatro problemas de arriba. Un shader que no se dibuja no lanza ningún error.

La suite subió a 59 casos. Los quince nuevos no comprueban que los efectos se
vean bien —eso se mira— sino lo que falla en silencio: que el material esté
asignado, que los `uniform` se llamen como los escribe el código (escribir un
parámetro inexistente en Godot no da error, se ignora) y que la condición de
encendido del contorno exija las dos cosas a la vez.

### Reflexión final

- **¿Qué diferencia existe entre modificar las coordenadas UV de una textura y
  transformar la posición de un objeto?** Transformar el objeto lo mueve: cambian
  su posición en la escena, su caja de colisión y lo que el ratón alcanza.
  Modificar las UV no mueve nada; cambia qué región de la textura se lee en cada
  fragmento, así que el dibujo ondula dentro de su propio rectángulo. En
  `sello_registrando` eso es justamente lo que se quiere: el ejemplar parece
  temblar mientras se sella, pero sigue exactamente donde estaba y se puede
  seguir pulsando igual. Si se hubiera hecho moviendo el nodo, el botón de la
  ficha se escaparía del cursor.
- **¿Cómo permite el canal alfa detectar los límites de una silueta?** Porque el
  alfa dice qué partes de la textura son dibujo y cuáles son vacío. Un píxel está
  en el borde cuando él mismo es transparente y alguno de sus vecinos no lo es:
  `alfa_vecino * (1.0 - texel.a)` es exactamente esa frase. No se calcula ninguna
  silueta geométrica, se aproxima leyendo transparencias, y por eso el resultado
  depende de a qué distancia se mire al vecino y de que haya sitio donde mirar.
- **¿Qué función cumplen los `uniform` y qué ventaja ofrece configurarlos desde
  el Inspector?** Son los parámetros que el shader recibe de fuera, y convierten
  un efecto en una familia de efectos. El caso del proyecto lo deja claro: hay un
  solo `contorno_interaccion.gdshader` y cuatro bordes de colores distintos,
  porque el color es un `uniform` que sale del catálogo. Sin ellos haría falta un
  shader o una textura por estante. Desde el Inspector se afinan viendo el
  resultado en el acto, sin recompilar ni volver a ejecutar, que es como se
  ajustaron la intensidad de la ondulación y el grosor del borde.
