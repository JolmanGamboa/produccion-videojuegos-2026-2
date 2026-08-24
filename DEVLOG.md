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
