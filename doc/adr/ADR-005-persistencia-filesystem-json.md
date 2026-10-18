# ADR-005 — Persistencia del estado en disco con FileAccess y JSON

| Campo | Valor |
| --- | --- |
| **Estado** | Aceptada |
| **Fecha** | 2026-10-17 |
| **Autor** | Jolman Harley Gamboa Salamanca |
| **Contexto** | Producción de Videojuegos 2026-2 — Laboratorio 7 (Sprint Review 2, Vertical Slice) |
| **Relacionada con** | ADR-003 (GlobalManager), ADR-004 (FSM del ciclo del ejemplar) |

## Contexto

Hasta el Laboratorio 6 el estado de la biblioteca sobrevivía al cambio de
pantalla, pero no a cerrar la aplicación: `GlobalManager` es un Autoload y su
vida es la del proceso. Para un Vertical Slice eso deja un hueco evidente —el
lector pierde sus préstamos cada vez que abre el proyecto— y hace imposible la
mecánica de recompensa que pide el laboratorio, porque un premio que se evapora
al cerrar no es un premio.

Había además un problema de alcance. La guía pide persistir los cupones, pero
guardar solo la recompensa y no los préstamos que la originan produciría un
estado incoherente al arrancar: pases ganados por devolver ejemplares que ya no
figuran en ningún registro.

## Decisión

Se persiste **el estado completo de la biblioteca** en un único archivo JSON
escrito con `FileAccess`, dentro de `GlobalManager`, que ya es el dueño de ese
estado desde el ADR-003.

```gdscript
const SAVE_PATH: String = "user://save_data.json"
const VERSION_GUARDADO: int = 1
```

**Qué se guarda.** El plan activo, el registro de préstamos
(`id → { plan, extra_dias }`), la colección de pases y el contador de pases
emitidos. El total de días no se guarda: es un valor derivado y se recalcula al
cargar, de modo que no puede quedar desincronizado del registro.

**Cuándo se guarda.** Después de cada cambio del registro —préstamo nuevo,
devolución y canje de un pase— en vez de al cerrar la aplicación. Un cierre
inesperado, o una pestaña del navegador que el usuario cierra sin avisar, no
deja la sesión a medias.

**Cuándo se carga.** En `_ready()`, antes del primer `_recalcular()`, para que
el total que ve la interfaz refleje desde el inicio lo que había en disco en
lugar de un registro vacío que luego se corrige.

**Cómo se valida lo leído.** JSON no conserva tipos ni garantiza que el archivo
siga siendo el que escribimos: puede haberse editado a mano, venir de una
versión anterior del esquema o estar truncado. Por eso la carga no confía en el
contenido: comprueba la versión del esquema y reconstruye cada préstamo y cada
pase contra el catálogo y la tabla de plazos, descartando lo que no valide. Ante
un archivo ilegible se arranca con la sala vacía en vez de propagar datos que no
se pueden interpretar.

**Mecánica de recompensa.** Devolver un ejemplar entrega un *pase de lectura*,
que se canjea para ampliar el plazo de otro préstamo vigente. Es la adaptación
del ciclo obtener → guardar → consumir que pide la guía al dominio de la
biblioteca: el pase se gana con una acción que ya existía, se gasta sobre una
entidad que ya existía y ambas cosas quedan escritas en disco.

> Nota de correspondencia con la guía: `guardar_datos()` y `cargar_datos()` son
> las funciones que la Guía de Laboratorio 7 llama `save_coupons()` y
> `load_coupons()`. Se conserva la nomenclatura en español del proyecto y el
> nombre genérico porque persisten el estado completo, no solo los pases.

## Alternativas consideradas

| Alternativa | Motivo del rechazo |
| --- | --- |
| `ConfigFile` (formato INI) | Cómodo para pares clave-valor planos, pero el registro de préstamos es un diccionario anidado y la colección de pases es un arreglo de objetos: habría que aplanarlos y volver a armarlos a mano. |
| Guardar un `Resource` con `ResourceSaver` | Conserva tipos sin trabajo extra, pero produce un archivo binario o `.tres` que no se puede inspeccionar durante la sustentación, y cargar recursos arbitrarios desde `user://` permite ejecutar código embebido. |
| `localStorage` del navegador mediante JavaScript | Ataría el guardado a la versión Web y obligaría a mantener dos caminos distintos. `user://` ya resuelve a IndexedDB en el navegador sin cambiar una línea. |
| Guardar solo al salir, con `NOTIFICATION_WM_CLOSE_REQUEST` | Menos escrituras, pero en la versión Web el cierre de la pestaña no garantiza que la notificación llegue, y un cierre inesperado perdería la sesión entera. |
| Persistir únicamente los pases, como enuncia la guía | Dejaría pases ganados por devolver ejemplares ausentes del registro: un estado incoherente al arrancar. |

## Consecuencias

**Ventajas**

- El proyecto deja de ser un prototipo que se reinicia: los préstamos y los
  pases son de verdad del lector, que es lo que convierte el prototipo en un
  Vertical Slice.
- El archivo es legible, lo que permite abrirlo durante la sustentación y
  mostrar que el pase canjeado desapareció de la colección.
- El mismo código sirve en escritorio y en navegador, porque `user://` es quien
  resuelve el destino.
- El campo `version` deja preparada la evolución del esquema sin romper
  guardados existentes.

**Costos**

- Se escribe en disco en cada cambio del registro. Con un catálogo de cuatro
  ejemplares el archivo pesa menos de un kilobyte, así que el costo es
  irrelevante aquí, pero no escalaría a un catálogo grande sin agrupar las
  escrituras.
- La carga necesita código de validación que duplica, en forma de comprobación,
  reglas que el resto del sistema da por ciertas.
- En la versión Web el guardado queda atado al origen de la página: una ventana
  de incógnito arranca siempre vacía. Es el comportamiento correcto, pero hay
  que explicarlo al probar.

## Justificación

El estado ya estaba centralizado en un único punto desde el ADR-003, así que
persistirlo no obligó a repartir responsabilidades nuevas: `GlobalManager` ganó
dos funciones y ninguna pantalla se enteró. JSON se eligió por encima de las
demás opciones justamente por lo que lo hace "poco eficiente" —es texto plano
legible— porque en una entrega académica poder abrir el archivo y señalar el
dato es más valioso que ahorrar unos bytes.

![Flujo de persistencia](diagrams/persistencia-estado.png)
