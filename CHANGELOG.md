# Changelog

Registro de cambios del proyecto **Biblioteca Interactiva 2D**.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el
versionamiento se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [1.5.0] — 2026-11-22 · Shaders 2D (Laboratorio 12)

### Añadido

- `res://src/shaders/` con tres shaders de tipo `canvas_item`:
  `contorno_interaccion` (borde que indica que un ejemplar se puede abrir),
  `sello_registrando` (ondulación del muestreo mientras se escribe el préstamo)
  y `pulso_plazo` (latido del reloj, que acelera con la urgencia).
- El contorno toma su color de `CategoriaData.color`: un único shader produce
  cuatro bordes distintos sobre diecisiete ejemplares, sin texturas nuevas.
- `tools/build_sprite_margen.py`, que separa las celdas de una hoja de sprites
  con un margen transparente.
- Quince casos de prueba en `tests/test_shaders.gd`.

### Modificado

- Las dos hojas de sprites llevan dos píxeles de margen alrededor de cada
  fotograma. Sin él, el contorno consulta píxeles del fotograma vecino y dibuja
  el borde con la silueta equivocada. El tamaño de celda pasa a 32 × 39 en el
  libro y 36 × 36 en el reloj.
- El tinte del estante sobre el ejemplar pasa a ser un lavado suave: el color
  entero apagaba la cubierta de cuero. La identidad del estante la lleva ahora
  el contorno.

---

## [1.4.0] — 2026-11-12 · Sprites animados y el plazo como cuenta atrás

### Añadido

- Componentes `LibroAnimado` y `RelojPlazo` en `src/components/sprites/`: dos
  objetos cuyo sprite cambia con su estado, uno gobernado por la máquina de
  estados del ciclo y otro por los días que le quedan al préstamo.
- Hojas de sprites `libro_biblioteca.png` (42 fotogramas) y `reloj_plazo.png`
  (32 fotogramas), ambas en la paleta de `ui_theme.tres`, con sus recursos
  `SpriteFrames` generados por `tools/build_sprite_frames.gd`.
- El plazo pasa a ser tiempo que corre: cada préstamo guarda su fecha de inicio
  y el gestor expone `ahora()`, `dias_restantes()` y `estado_plazo()`.
- La pantalla de préstamos muestra el reloj de cada plazo y los días que
  quedan en palabras.
- Calendario de sala adelantable desde la configuración, para poder observar el
  vencimiento de un préstamo sin esperar días reales.
- Señales `time_advanced` y `calendar_changed` en el Event Bus, y el vocabulario
  de los cuatro estados del plazo.
- `ADR-007` sobre los sprites dirigidos por el estado del objeto.
- Catorce casos de prueba nuevos en `tests/test_plazo_y_sprites.gd`.

### Modificado

- El esquema del guardado sube a la versión 2. Los archivos de la versión 1 se
  migran al leerlos en vez de descartarse: los préstamos sin fecha de inicio
  empiezan a contar desde la primera carga.
- En la sala, el icono fijo de cada tarjeta se sustituye por el ejemplar
  animado.
- La configuración de sala deja de ser una pantalla solo informativa.

---

## [1.3.0] — 2026-11-08 · Versión Beta (Laboratorios 8, 9 y 10)

> La Release de GitHub de esta versión lleva la etiqueta `v0.9.0-beta`, que es
> la que pide la guía del curso para marcar la Beta. El número de este registro
> sigue el versionamiento semántico del proyecto, que ya había pasado de 1.0.0.

### Añadido

- Suite de pruebas automatizadas con **GdUnit4 6.2.3** en `res://tests/`:
  treinta casos en cuatro suites, repartidos entre pruebas unitarias, de
  integración por el `EventBus`, de sistema con persistencia y de regresión.
- `TEST_REPORT.md` con los casos UNI-01, INT-01 y SIS-01 documentados por nivel,
  el reto autónomo sobre las consultas del catálogo y los defectos corregidos.
- `registro_depuracion.md` con el guion de la sesión de depuración: puntos de
  ruptura, variables a inspeccionar y pilas de llamadas esperadas.
- Catálogo en recursos: `LibroData`, `CategoriaData` y `CatalogoBiblioteca` con
  `catalogo.tres`, con cuatro estantes y diecisiete ejemplares.
- Pantalla de estantes y sala de lectura auto-pobladas desde el catálogo, con
  una tarjeta desplegable por ejemplar.
- Comprobante de préstamo con consumo de pases antes de confirmar, y el estado
  `EN_COMPROBANTE` en la máquina de estados.
- Navegación completa por teclado, iconografía de apoyo, popup de confirmación
  y fondo decorativo del vestíbulo.
- `USER_FEEDBACK.md` con la plantilla y el guion de la prueba de usabilidad.
- `ADR-006` sobre el catálogo en recursos y la interfaz generada a partir de los
  datos.

### Modificado

- La sala de lectura pasa de cuatro bloques fijos a una lista de tarjetas: el
  detalle y los plazos viven dentro del ejemplar al que pertenecen, de modo que
  lo que crece es la tarjeta y no la pantalla.
- El comprobante se reparte en dos columnas y su alto mínimo baja a 456 px.
- `cargar_datos()` recalcula el total al terminar, de modo que deja el estado
  coherente para cualquiera que la invoque, no solo para `_ready()`.
- El contraste del botón deshabilitado sube a 4.53:1 (WCAG AA).

### Corregido

- El total de días quedaba descuadrado al recargar el guardado por separado,
  porque el recálculo vivía en `_ready()` y no en la carga (REG-01).
- `plan_activo` entraba del archivo de guardado sin validarse contra la tabla de
  plazos, al contrario que el resto de los campos (REG-02).
- Vaciar el registro reiniciaba el contador de pases emitidos, así que los
  identificadores se repetían entre sesiones (REG-03).
- Abrir el comprobante disparaba una cadena de navegaciones hasta desbordar la
  salida, porque el panel saliente seguía suscrito al bus mientras esperaba su
  liberación diferida.
- El fondo del vestíbulo quedaba oculto por una capa opaca dibujada encima.

---

## [1.2.0] — 2026-10-17 · Laboratorio 7: Vertical Slice, persistencia y Web

### Añadido

- Persistencia del estado en `user://save_data.json` con `FileAccess` y `JSON`:
  `guardar_datos()` tras cada cambio del registro y `cargar_datos()` en
  `_ready()`, con validación del esquema y saneamiento de lo leído.
- Pases de lectura: se obtienen al devolver un ejemplar y se canjean para
  ampliar el plazo de otro préstamo vigente.
- Tablero de pases en el panel de préstamos, con el origen de cada uno y un
  botón de ampliación por fila.
- Botón para vaciar el registro guardado y repetir la prueba de persistencia.
- Tema visual unificado (`src/assets/ui/biblioteca_theme.tres`) registrado como
  tema por defecto del proyecto.
- Señales `consultation_changed`, `pass_redeemed`, `passes_updated`,
  `pass_result` y `save_reset_requested` en el Event Bus.
- `doc/web-export.md` con los ajustes del preset Web y la publicación.
- `ADR-005` sobre la persistencia y su diagrama de flujo.

### Modificado

- El registro de préstamos pasa de `id → plazo` a `id → { plan, extra_dias }`
  para admitir las ampliaciones canjeadas.
- Los títulos, subtítulos, fichas y totales usan variaciones del tema en vez de
  tamaños de fuente sueltos por escena.
- El vestíbulo, la configuración y los créditos limitan el ancho de su columna
  y la centran.
- El nombre del proyecto pasa a «Biblioteca Interactiva 2D».

### Corregido

- Volver a la sala con un ejemplar en consulta dejaba la ficha vacía y permitía
  publicar un préstamo sin ejemplar.
- Un ejemplar ya prestado se podía abrir y tramitar hasta recibir el rechazo
  solo después del registro; ahora aparece marcado en el estante.

---

## [1.1.0] — 2026-10-01 · Laboratorio 6: FSM y animaciones programáticas

### Añadido

- Máquina de estados del ciclo del ejemplar en `GlobalManager`: `en_estante`,
  `en_consulta`, `registrando` y `prestado`, con tabla de transiciones
  permitidas y una única función `_cambiar_estado()`.
- Señales `item_opened`, `item_closed`, `loan_state_changed` y `loan_result` en
  el Event Bus, junto con las constantes del vocabulario de estados.
- Animaciones `Tween`: la ficha se encoge y se atenúa mientras el préstamo se
  registra, y el veredicto aparece con un destello de su color.
- Botón para devolver el ejemplar al estante sin llevárselo.
- Diagrama de estados en `doc/diagrams/` (SVG, PNG y PDF).
- `ADR.md` en la raíz con el índice de decisiones y el ADR-004.
- `BACKLOG.md` con las tareas completadas y las pendientes del proyecto.

### Modificado

- El plazo solo se acepta con un ejemplar en consulta; el estante y las
  devoluciones quedan bloqueados mientras un préstamo se registra.
- El ejemplar en consulta pasó a vivir en el estado global, por lo que
  sobrevive al cambio de pantalla.

### Corregido

- Elegir dos veces un plazo ya no registra el mismo ejemplar por duplicado.
- Un ejemplar ya prestado no puede volver a salir del estante sin devolverse.

---

## [1.0.0] — 2026-09-11 · Cierre del Sprint 1 (Sprint Review 1)

Primera versión integrada del sistema: cinco entornos navegables, registro de
préstamos desasociado de la interfaz y componentes reutilizables.

### Añadido

- `GlobalManager` registrado como Autoload: centraliza en un `Dictionary` qué
  ejemplares están prestados y con qué plazo, y propaga el estado con
  `total_changed` y `loans_updated`.
- Constantes del dominio: `DURACIONES_PLAN` (diario 1 día, quincenal 15,
  mensual 30) y `CATALOGO` con una entrada por ejemplar de la biblioteca.
- Pantalla **Préstamos activos** (`scenes/loans/`), que lista los ejemplares
  fuera del estante con su plazo y permite devolverlos.
- Tres plazos de préstamo en la parte inferior de la sala de lectura.
- Componente reutilizable `ButtonNav` (`components/navigation/`),
  parametrizable desde el Inspector con `@export_file("*.tscn")` y
  `@export var discard_previous: bool`.
- Pila de historial `navigation_history: Array[String]` en `MainApp`,
  administrada con `append()` y `pop_back()` e impresa en consola tras cada
  navegación.
- Señales de estado en el Event Bus: `base_selected`, `item_added`,
  `item_removed`, `total_changed` y `loans_updated`.
- Documentos `ADR-002`, `ADR-003` y este `CHANGELOG.md`.

### Modificado

- `navigation_requested` incorpora el parámetro `discard_previous: bool` para
  distinguir avances de regresos.
- Los paneles se reubican en módulos por dominio: `scenes/main/` y
  `scenes/simulation/`.
- El vestíbulo resuelve su navegación con instancias de `ButtonNav` y conserva
  únicamente el cierre local de la aplicación.
- La sala de lectura mantiene la consulta de fichas del laboratorio anterior,
  pero deja de guardar datos propios: ahora solo emite intenciones y escucha.
- El contenedor visual de `MainApp` se renombra a `SceneContainer`.
- El panel de configuración se renombra de *Configuración de parámetros* a
  *Configuración de sala*.

### Eliminado

- `config_panel.gd` y `credits_panel.gd`: ambos paneles resuelven su navegación
  de forma declarativa, sin script controlador.
- Señal `parameter_changed`, sustituida por el flujo de estado del
  `GlobalManager`.

---

## [0.2.0] — 2026-09-03 · Laboratorio 2

### Añadido

- `EventBus` como Autoload (Singleton + Observer) con señales tipadas.
- `MainApp` como orquestador único del árbol de escenas, con liberación
  explícita de memoria mediante `queue_free()`.
- Cuatro paneles modulares con co-localización de escena y script.
- `ADR-001` sobre la adopción del Event Bus.

### Modificado

- Nombre del proyecto y escena principal de arranque.

### Eliminado

- `change_scene.gd` y todas las llamadas directas a `change_scene_to_file()`.
- Estructura plana `src/scripts/` y carpetas vacías heredadas.

---

## [0.1.0] — 2026-08-27 · Laboratorio 1

### Añadido

- Prototipo inicial con flujo de navegación básico entre dos pantallas.
- Interacción local con conexión de señales mediante `connect()` y `bind()`.
- `README.md` y `DEVLOG.md` del proyecto.
