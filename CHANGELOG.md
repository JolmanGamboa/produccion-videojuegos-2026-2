# Changelog

Registro de cambios del proyecto **Biblioteca Interactiva 2D**.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el
versionamiento se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

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
