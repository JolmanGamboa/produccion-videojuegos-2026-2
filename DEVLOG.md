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
