# Registro de depuración — Laboratorio 10

Sesión de depuración asistida con el inspector de **Godot 4.7** sobre el
proyecto integrador *Biblioteca Interactiva 2D*.

> **Estado de este documento.** El guion de la sesión, los puntos de ruptura y
> los valores que deben observarse están preparados abajo a partir de los
> defectos que destapó la suite de pruebas. Los campos marcados
> **(completar en la sesión)** son observaciones de primera mano y se llenan
> ejecutando el proyecto en el editor: no se dan por escritas aquí.

| Campo | Valor |
| --- | --- |
| **Fecha de la sesión** | (completar en la sesión) |
| **Versión del motor** | Godot 4.7 stable |
| **Escena ejecutada** | `res://src/core/main_app.tscn` (F5) |
| **Puntos de ruptura** | 2 |

---

## Sesión 1 — `cargar_datos()` y el total descuadrado

### Por qué esta función

La suite reveló que `cargar_datos()` restituía los préstamos del disco pero
dejaba `estado["total_dias"]` con el valor que tenía antes (defecto REG-01 del
`TEST_REPORT.md`). El depurador sirve aquí para ver el momento exacto en que el
estado queda a medias: los préstamos ya son los nuevos y el total todavía no.

### Preparación

1. Abrir `res://src/core/global_manager.gd`.
2. Colocar un punto de ruptura en la línea del `_recalcular()` que cierra
   `cargar_datos()` (al final de la función, después del `print` del estado
   restaurado).
3. Asegurarse de que hay un guardado con préstamos: ejecutar el proyecto,
   tomar prestado un ejemplar y cerrar.
4. Volver a ejecutar con **F5**. El programa se detiene en el punto de ruptura
   durante el `_ready()` del Autoload, antes de que se dibuje el vestíbulo.

### Variables a inspeccionar

| Variable | Qué mirar |
| --- | --- |
| `estado["prestamos"]` | Debe traer ya los préstamos leídos del archivo |
| `estado["total_dias"]` | En la pausa todavía vale `0`, el valor con el que arranca el diccionario |
| `guardado` | El diccionario tal como salió de `JSON.parse_string()`, para comparar con lo saneado |
| `plan_guardado` | El plazo activo leído, ya validado contra `DURACIONES_PLAN` |

### Ejecución paso a paso

- **Step Over (F8)** sobre el `_recalcular()`: `estado["total_dias"]` pasa de
  `0` al total real de los préstamos cargados.
- **Step Into (F7)** en su lugar entra en `_recalcular()`, donde se ve el bucle
  que llama a `dias_de()` por cada préstamo y acumula el total.
- **Continue (F6)** deja que arranque el vestíbulo.

### Pila de llamadas esperada

```
_recalcular()        ← global_manager.gd
cargar_datos()       ← global_manager.gd
_ready()             ← global_manager.gd  (Autoload)
```

Esa pila es la que explica por qué el defecto no se notaba jugando: `_ready()`
llamaba a `_recalcular()` justo después de `cargar_datos()`, así que al arrancar
el total terminaba bien. El descuadre solo aparecía al invocar `cargar_datos()`
por separado, que es exactamente lo que hace la prueba de sistema SIS-01.

### Hallazgos

(completar en la sesión)

---

## Sesión 2 — `_cambiar_estado()` y la tabla de transiciones

### Por qué esta función

Es la única puerta por la que pasa el ciclo del ejemplar. Interesa ver, sin
leer el código, **quién** pide cada transición: con el punto de ruptura dentro
de la función, la pila de llamadas nombra el manejador que la solicitó y, por
encima, la señal del `EventBus` que lo disparó.

### Preparación

1. Punto de ruptura en la línea `var permitidas: Array = TRANSICIONES[_estado_prestamo]`
   de `_cambiar_estado()`.
2. Ejecutar con **F5**, entrar a un estante y abrir la ficha de un ejemplar.

### Variables a inspeccionar

| Variable | Qué mirar |
| --- | --- |
| `_estado_prestamo` | El estado de partida, como entero del `enum` |
| `nuevo_estado` | El estado solicitado |
| `permitidas` | El arreglo de destinos válidos desde el estado actual |
| `TRANSICIONES` | La tabla completa, para confirmar que el rechazo viene del dato y no de un `if` suelto |

### Qué recorrer

- Abrir un ejemplar: `en_estante → en_consulta`, transición permitida.
- Elegir un plazo: `en_consulta → en_comprobante`.
- Confirmar: `en_comprobante → registrando` y, tras el temporizador,
  `registrando → prestado`.
- Para ver un rechazo: con el ejemplar en el estante, pulsar directamente una
  acción que pida `prestado`. La función entra, `permitidas` no contiene el
  destino y devuelve `false` sin tocar `_estado_prestamo`.

### Pila de llamadas esperada

```
_cambiar_estado()    ← global_manager.gd
_on_item_opened()    ← global_manager.gd   (suscriptor de EventBus.item_opened)
emit_signal()        ← step_1_base.gd      (la tarjeta del ejemplar)
```

### Hallazgos

(completar en la sesión)

---

## Respuestas a las preguntas de la guía

### ¿Qué variables inspeccionó?

(completar en la sesión)

### ¿Qué descubrió sobre el flujo de ejecución?

(completar en la sesión)

### ¿Cómo le ayudó la herramienta?

(completar en la sesión)

---

## Depuración frente a pruebas automatizadas

Las dos sesiones de arriba y la suite de `tests/` hacen cosas distintas, y el
laboratorio las junta a propósito:

- El **depurador** responde *por qué* ocurre algo. Detiene el programa en un
  punto y deja ver el estado real y quién llamó a quién. Es la herramienta para
  entender un defecto, pero no deja nada que vuelva a comprobarse mañana.
- Las **pruebas automatizadas** responden *si* sigue ocurriendo. No explican
  nada, pero cada una queda ejecutándose para siempre.

El orden que resultó útil aquí fue: las pruebas encontraron los tres defectos,
el depurador sirvió para entender el de `cargar_datos()`, y la prueba de
regresión quedó en la suite para que no vuelva.
