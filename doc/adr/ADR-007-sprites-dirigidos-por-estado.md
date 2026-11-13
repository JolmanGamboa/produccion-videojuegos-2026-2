# ADR-007 — Sprites animados dirigidos por el estado del objeto

| Campo | Valor |
| --- | --- |
| **Estado** | Aceptada |
| **Fecha** | 2026-11-12 |
| **Autor** | Jolman Harley Gamboa Salamanca |
| **Contexto** | Producción de Videojuegos 2026-2 — Versión Beta |
| **Relacionada con** | ADR-001 (Event Bus), ADR-004 (FSM), ADR-005 (Persistencia) |

## Contexto

La entrega exige sprites animados y una mecánica que cambie el estado de un
objeto de forma que su animación cambie con él.

El proyecto ya tenía la mecánica. Desde el ADR-004, el ejemplar recorre una
máquina de estados —`en_estante`, `en_consulta`, `en_comprobante`,
`registrando`, `prestado`— con una tabla de transiciones y una única función
que la gobierna. Lo que faltaba era el otro extremo: ese estado solo se
comunicaba con texto y con el color de una etiqueta.

Es decir, no había que inventar una mecánica, había que **darle cuerpo visible a
la que ya existía**. Y conviene decirlo tal cual, porque inventar una segunda
máquina de estados solo para tener algo que animar habría dejado el proyecto
con dos modelos del mismo ciclo.

Quedaba un problema aparte. Un segundo objeto con estados visibles era deseable
para demostrar que el patrón no estaba atado a la FSM, y el candidato natural
—el plazo de un préstamo— no era un estado sino una duración: `dias` decía
cuántos días se pidieron, y nada los descontaba. No existía el paso del tiempo.

## Decisión

### 1. El sprite es un suscriptor más del estado, no su dueño

`LibroAnimado` es un componente reutilizable, hermano de `ButtonNav`, que
traduce el vocabulario de estados que ya publica el `EventBus` a la animación
que le corresponde:

| Estado del ciclo | Animación | Qué se ve |
| --- | --- | --- |
| `en_estante` | `cerrado` | el libro cerrado, quieto |
| `en_consulta` | `abriendo` → `pasando_hojas` | se abre y se queda pasando hojas |
| `en_comprobante` | `pasando_hojas` | sigue abierto mientras se tramita |
| `registrando` | `cerrando` | se cierra al sellarse el préstamo |
| `prestado` | `de_canto` | sale de la sala |

El mapa es una tabla, no una cadena de condicionales, por la misma razón que lo
es la tabla de transiciones: se lee de un vistazo y añadir un estado es añadir
una línea.

**El componente no se suscribe al bus.** La sala construye una tarjeta por
ejemplar y solo una está abierta a la vez; suscribir cada sprite pondría en el
bus tantos oyentes como libros tenga el estante para que todos menos uno
ignoraran cada evento. La pantalla, que es la que sabe cuál está en consulta,
reparte el estado entre sus tarjetas. Se mantiene así la regla del ADR-001: un
suscriptor por pantalla, no uno por nodo.

### 2. El plazo pasa de duración a cuenta atrás

Cada préstamo guarda ahora cuándo empezó:

```gdscript
prestamos[item_id] = {"plan": plan, "extra_dias": extra, "inicio": ahora()}
```

`ahora()` es el reloj del sistema más un desfase, y **toda cuenta de días pasa
por esa función**. De ahí salen `dias_restantes()` y `estado_plazo()`, que
clasifica el préstamo en cuatro tramos según la fracción que le quede:
`al_dia`, `por_vencer` (la mitad), `urgente` (un cuarto) y `vencido`.

El componente `RelojPlazo` consume ese estado igual que `LibroAnimado` consume
el del ciclo. Y aquí está lo que hacía falta demostrar: **el estado no viene de
una máquina de estados sino de una cuenta, y al componente le da igual**. El
patrón es independiente de cómo se decida el estado.

### 3. El calendario de la sala se puede adelantar

Un préstamo mensual tarda un mes en vencer, lo que hace imposible mostrar el
reloj en rojo durante una sustentación. La configuración de sala publica
`time_advanced`, que incrementa un desfase persistido.

No es una trampa ni un modo de depuración: como todas las cuentas pasan por
`ahora()`, **nada dentro del dominio distingue un día adelantado de uno
transcurrido**. Lo que se ve al adelantar es exactamente lo que se vería
esperando.

### 4. El esquema del guardado sube a la versión 2, con migración

Añadir `inicio` cambia la forma del registro. El guardado de la versión 1 no se
descarta: se migra al leerlo, dando por empezados hoy los préstamos que no
traen fecha. Es la lectura más benévola —nadie pierde días por actualizar— y
evita tirar un archivo que por lo demás es válido.

## Alternativas consideradas

| Alternativa | Motivo del rechazo |
| --- | --- |
| Una máquina de estados nueva, solo para la animación | Dejaría dos modelos del mismo ciclo que habría que mantener sincronizados. El estado del ejemplar ya existe y es uno. |
| `AnimationPlayer` sobre un `TextureRect` | Funciona, pero obliga a declarar cada fotograma como pista de animación. `AnimatedSprite2D` con `SpriteFrames` es lo que el motor ofrece para hojas de sprites, y el recurso se edita en el Inspector. |
| Animar el sprite desde la pantalla, sin componente | La sala tendría que saber qué fotogramas son «abrir» y cuáles «pasar hojas». Ese conocimiento es del objeto, no de quien lo muestra. |
| Que cada sprite se suscriba al `EventBus` | Tantos oyentes como ejemplares tenga el estante, todos menos uno ignorando cada evento. |
| Un día de sala cada N segundos | Se ve enseguida, pero el plazo dejaría de significar días y un préstamo caducaría por tener el programa abierto. |
| Solo tiempo real, sin desfase | Más limpio, pero el reloj en rojo sería inobservable sin cambiar la hora del sistema. |
| Descartar los guardados de la versión 1 | Es lo cómodo. Le borraría los préstamos a quien venía de antes por un campo que se puede deducir. |

## Consecuencias

**Ventajas**

- El estado del objeto se ve, y se ve porque la mecánica que ya existía ahora
  tiene cuerpo. La sustentación puede enseñar la tabla de transiciones y la
  animación una al lado de la otra.
- Dos objetos distintos comparten el patrón con estados de origen distinto —uno
  de una FSM, otro de una cuenta—, lo que prueba que el patrón es general.
- El plazo por fin significa algo: antes un préstamo mensual y uno diario se
  distinguían solo por un número en una etiqueta.
- El reloj no comunica nada solo con color. Cambian también la velocidad de la
  aguja y cuánto arco queda dibujado, y la fila lo dice en palabras. Es la regla
  de accesibilidad del Laboratorio 8 aplicada a un elemento nuevo.
- Los dos `SpriteFrames` los genera `tools/build_sprite_frames.gd`, de modo que
  los setenta y cuatro recortes no se escriben a mano.

**Costos**

- `AnimatedSprite2D` es un `Node2D` y no se coloca en los contenedores de
  interfaz. Ambos componentes lo envuelven en un `Control` y centran el sprite
  a mano cuando cambia el tamaño. Es el precio de mezclar los dos árboles.
- El guardado tiene una versión más que mantener, y la función de saneamiento
  carga con la migración.
- El desfase del calendario es estado persistido que no corresponde a nada del
  dominio. Se asume a cambio de poder observar el vencimiento.
- Las animaciones del libro salen de una hoja de sprites ajena, recoloreada a la
  paleta del tema. Si se cambia la paleta hay que volver a generarla con
  `tools/build_sprite_libro.py`.
