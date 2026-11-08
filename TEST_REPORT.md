# TEST_REPORT — Biblioteca Interactiva 2D

Reporte de pruebas del **Laboratorio 10** (Sprint 3 — Calidad y Mantenimiento).
Documenta los casos diseñados, su nivel en la pirámide de pruebas y el resultado
de la ejecución automatizada con **GdUnit4 6.2.3** sobre **Godot 4.7**.

| Campo | Valor |
| --- | --- |
| **Framework** | GdUnit4 6.2.3 (`addons/gdUnit4`, versionado en el repositorio) |
| **Motor** | Godot 4.7 stable |
| **Ubicación de la suite** | `res://tests/` |
| **Suites** | 4 |
| **Casos automatizados** | 30 |
| **Resultado** | 30 pasados · 0 fallos · 0 errores · 0 huérfanos |
| **Ejecución** | dock de GdUnit en el editor, o `addons/gdUnit4/runtest.sh -a res://tests` |

---

## 1. Qué se eligió probar y por qué

El proyecto tiene tres clases de lógica, y no todas se prueban igual:

| Clase de lógica | Dónde vive | Cómo se prueba |
| --- | --- | --- |
| Reglas de cálculo y validación | `GlobalManager`, `CatalogoBiblioteca` | Prueba **unitaria** sobre una instancia aislada |
| Reacción a las intenciones de la interfaz | suscriptores del `EventBus` | Prueba de **integración** publicando en el bus |
| Ciclo completo con escritura en disco | `guardar_datos()` / `cargar_datos()` | Prueba de **sistema** |

Lo que **no** se automatiza es la interfaz: que una tarjeta se despliegue o que
un botón quede enfocado se verifica a mano, porque automatizarlo costaría más
que el error que evitaría. Las pruebas se concentran en las reglas que, si se
rompen, lo hacen en silencio.

---

## 2. Casos de prueba documentados

### UNI-01 — Cálculo de los días comprometidos

| Campo | Detalle |
| --- | --- |
| **Nivel** | Unitaria |
| **Función** | `GlobalManager.dias_de(registro)` |
| **Condiciones iniciales** | Instancia de `GlobalManager` creada con `new()` y **no añadida al árbol**, de modo que `_ready()` no se ejecuta: sin suscripciones al bus y sin lectura de disco |
| **Entradas** | `{plan: "diario", extra_dias: 0}` · `{plan: "quincenal", extra_dias: 0}` · `{plan: "mensual", extra_dias: 0}` · `{plan: "quincenal", extra_dias: 14}` |
| **Resultado esperado** | `1` · `15` · `30` · `29` |
| **Criterio** | El total es el plazo de la tabla `DURACIONES_PLAN` más los días que aportaron los pases, sin excepción por plan |
| **Pruebas** | `test_dias_de_devuelve_el_plazo_base_de_cada_plan`, `test_dias_de_suma_las_ampliaciones_canjeadas_con_pases`, `test_dias_de_no_depende_del_plan_para_contar_las_ampliaciones` |
| **Resultado** | PASADO |

### INT-01 — El plazo elegido llega al gestor por el Event Bus

| Campo | Detalle |
| --- | --- |
| **Nivel** | Integración |
| **Componentes** | `EventBus` + Autoload real `GlobalManager` + catálogo `catalogo.tres` |
| **Condiciones iniciales** | Estado del lector respaldado y reemplazado por un registro vacío; ciclo en `en_estante` |
| **Entradas** | `EventBus.item_opened.emit("dune")` y después `EventBus.base_selected.emit("quincenal")` |
| **Resultado esperado** | `estado.ejemplar_en_consulta == "dune"`; el ciclo pasa por `en_consulta` y luego a `en_comprobante`; el bus publica un `receipt_changed` con `id == "dune"`, `dias_base == 15`, `dias_total == 15` y `pases_aplicados == 0` |
| **Criterio** | Ninguna función se llama por su nombre: solo se publican intenciones. Si el gestor dejara de suscribirse a `base_selected`, este caso falla y los unitarios no |
| **Pruebas** | `test_int_01_elegir_el_plazo_abre_el_comprobante`, `test_int_02_aplicar_un_pase_amplia_el_comprobante`, `test_int_03_cancelar_el_comprobante_no_toca_el_registro` |
| **Resultado** | PASADO |

### SIS-01 — Ciclo completo y persistencia entre sesiones

| Campo | Detalle |
| --- | --- |
| **Nivel** | Sistema |
| **Componentes** | `EventBus` + `GlobalManager` + `FileAccess`/`JSON` + `user://save_data.json` |
| **Condiciones iniciales** | Registro vacío, sin pases, ciclo en `en_estante` |
| **Entradas** | `item_opened("dune")` → `base_selected("quincenal")` → `item_added("dune")`, esperando los 0,6 s reales del estado `registrando`; luego se vacía el registro en memoria y se invoca `cargar_datos()` |
| **Resultado esperado** | Tras confirmar: el préstamo existe, `total_dias == 15` y el ciclo pasó por `prestado`. Tras simular el cierre y recargar: el préstamo vuelve con `plan == "quincenal"` y 15 días |
| **Criterio** | El plazo sobrevive al reinicio porque está en disco, no en memoria. Es la promesa del Vertical Slice del Laboratorio 7, verificada automáticamente |
| **Pruebas** | `test_sis_01_el_prestamo_sobrevive_al_reinicio`, `test_sis_02_devolver_entrega_un_pase_y_libera_el_ejemplar` |
| **Resultado** | PASADO |

---

## 3. Reto autónomo — consultas del catálogo

Función adicional elegida: las cuatro consultas de `CatalogoBiblioteca`
(`libros_de`, `buscar_libro`, `buscar_categoria`, `contar_libros`). Son las
funciones de las que depende todo lo auto-poblado del proyecto: si `libros_de()`
devolviera un ejemplar de otro estante, la sala mostraría libros que no
corresponden y ninguna pantalla se daría cuenta, porque todas confían en que el
catálogo responde bien.

Se prueban contra el catálogo publicado y no contra uno inventado, para que las
pruebas verifiquen además que el recurso está bien formado.

| Tipo de caso | Prueba | Resultado |
| --- | --- | --- |
| Normal | `test_buscar_libro_devuelve_el_recurso_del_ejemplar` | PASADO |
| Normal | `test_libros_de_solo_devuelve_los_de_ese_estante` | PASADO |
| Negativo | `test_buscar_libro_devuelve_null_fuera_de_catalogo` | PASADO |
| Negativo | `test_buscar_categoria_devuelve_null_fuera_de_catalogo` | PASADO |
| Límite | `test_las_consultas_toleran_el_identificador_vacio` | PASADO |
| Coherencia | `test_contar_libros_coincide_con_la_consulta` | PASADO |
| Coherencia | `test_ningun_ejemplar_quedo_sin_estante` | PASADO |
| Coherencia | `test_los_identificadores_de_los_ejemplares_son_unicos` | PASADO |

El caso límite del identificador vacío no es hipotético: el estado arranca con
`categoria_activa` en cadena vacía, así que esa consulta se hace de verdad en el
primer arranque del programa.

---

## 4. Defectos encontrados y corregidos

Las tres pruebas de `tests/test_persistencia.gd` **fallaban cuando se
escribieron**. Cada una reproduce un defecto que el diseño de casos destapó, y
queda en la suite como prueba de regresión. Los tres están registrados como
Issues en GitHub y se cerraron en esta misma rama.

| ID | Defecto | Causa | Corrección | Prueba de regresión |
| --- | --- | --- | --- | --- |
| **REG-01** | `cargar_datos()` restituía los préstamos pero dejaba `total_dias` con el valor anterior | El total es una función del registro, pero el recálculo estaba en `_ready()` y no en la carga, así que solo quedaba coherente al arrancar | `cargar_datos()` termina llamando a `_recalcular()` | `test_reg_01_cargar_datos_deja_el_total_coherente` |
| **REG-02** | `plan_activo` entraba del disco sin validarse contra `DURACIONES_PLAN` | Era el único campo del guardado sin saneamiento, al contrario que `prestamos` y `categoria_activa`; desde ahí podía llegar a `dias_de()`, que busca el plan en la tabla sin red | Se valida contra la tabla y, si no está, se cae a `PLAN_POR_DEFECTO` con una advertencia | `test_reg_02_el_plazo_activo_del_guardado_se_valida` |
| **REG-03** | Tras vaciar el registro, el primer pase volvía a llamarse `pase_001` | `_on_save_reset_requested()` reiniciaba `pases_emitidos` a cero, justo el contador que se persiste para que los identificadores no se repitan | El contador sobrevive al vaciado | `test_reg_03_los_identificadores_de_pase_no_se_repiten_tras_vaciar` |

Ninguno de los tres se manifestaba jugando: REG-01 quedaba tapado porque
`_ready()` recalcula justo después de cargar, REG-02 necesita un guardado
editado a mano y REG-03 solo se nota comparando identificadores entre sesiones.
Son exactamente el tipo de defecto que una suite automatizada encuentra y una
partida de prueba no.

---

## 5. Cómo ejecutar la suite

**Desde el editor.** El plugin ya viene habilitado en `project.godot`, así que
al abrir el proyecto aparece el dock de GdUnit en el panel izquierdo. Botón
derecho sobre `res://tests` → *Run Tests*.

**Desde la línea de comandos.**

```bash
# Linux / macOS
export GODOT_BIN=/ruta/a/godot
./addons/gdUnit4/runtest.sh -a res://tests
```

```cmd
:: Windows
set GODOT_BIN=C:\ruta\a\godot.exe
addons\gdUnit4\runtest.cmd -a res://tests
```

El runner escribe un reporte XML y HTML en `reports/`, carpeta ignorada por git
porque es un artefacto generado.

> Nota sobre el modo headless: GdUnit4 lo rechaza por defecto, porque los
> `InputEvent` de Godot no se transportan sin ventana y las pruebas de interfaz
> darían falsos verdes. Esta suite no simula entrada de usuario, así que puede
> ejecutarse con `--headless --ignoreHeadlessMode`, que es como se validó aquí.

---

## 6. Inventario de la suite

| Suite | Nivel | Casos | Qué cubre |
| --- | --- | --- | --- |
| `tests/test_global_manager.gd` | Unitaria | 13 | `dias_de()`, `_sanear_prestamos()`, `_sanear_pases()` y la tabla de transiciones de la FSM |
| `tests/test_catalogo_biblioteca.gd` | Unitaria | 9 | Las cuatro consultas del catálogo y la coherencia del recurso publicado |
| `tests/test_flujo_prestamo.gd` | Integración + Sistema | 5 | INT-01 a INT-03 y SIS-01 a SIS-02 |
| `tests/test_persistencia.gd` | Regresión | 3 | REG-01, REG-02 y REG-03 |

Las dos suites que tocan el Autoload real respaldan el estado del lector en
`before()` y lo restituyen en `after()`, de modo que ejecutar las pruebas no
altera la partida guardada.
