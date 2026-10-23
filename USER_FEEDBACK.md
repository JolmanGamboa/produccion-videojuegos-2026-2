# USER_FEEDBACK — Pruebas de usabilidad

Registro de las evaluaciones con usuarios reales de la **Biblioteca Interactiva
2D**. Cada prueba se realiza sin explicar de antemano cómo funciona el sistema:
lo que el evaluador no entienda por su cuenta es precisamente el hallazgo.

---

## Evaluación de Usabilidad 1

| Campo | Detalle de la Evaluación |
| --- | --- |
| **Evaluación** | Evaluación de Usabilidad 1 |
| **Fecha** | _(DD/MM/AAAA)_ |
| **Perfil del evaluador** | _(edad aproximada, ocupación, experiencia previa con videojuegos o con este proyecto)_ |
| **Tareas realizadas** | _(qué recorrido hizo: navegación, consulta de una ficha, registro de un préstamo, devolución, canje de un pase)_ |
| **Aspectos comprendidos** | _(qué entendió sin ayuda)_ |
| **Dificultades encontradas** | _(dónde dudó, qué intentó pulsar, qué preguntó)_ |
| **Sugerencias recibidas** | _(lo que propuso con sus propias palabras)_ |
| **Mejoras a implementar** | _(qué se decide cambiar a partir de lo anterior, y con qué prioridad)_ |

---

## Guion para conducir la prueba

Entregar el proyecto abierto en el vestíbulo y decir solo esto: *«Es una
biblioteca. Llévate un libro prestado y devuélvelo.»* A partir de ahí, no
intervenir: cada pregunta que el evaluador haga es un hallazgo.

**Qué cronometrar y observar en cada paso**

| Paso del flujo | Qué vigilar |
| --- | --- |
| Vestíbulo | ¿Entiende qué hay detrás de cada botón antes de pulsarlo? ¿Le dicen algo los iconos? |
| Sala de lectura | ¿Descubre que primero hay que abrir un libro y después elegir el plazo, o intenta pulsar el plazo primero? |
| Elección de plazo | ¿Entiende que diario, quincenal y mensual son duraciones y no precios? |
| Confirmación del préstamo | ¿Lee el popup o lo cierra de inmediato? ¿Cuál de los dos botones elige? |
| Estante con un ejemplar prestado | ¿Entiende por qué ese lomo está apagado? ¿Lo intenta pulsar igual? |
| Préstamos activos | ¿Encuentra cómo devolver? ¿Distingue devolver de ampliar? |
| Pases de lectura | ¿Entiende de dónde salió el pase y para qué sirve? **Punto sospechoso: es la mecánica menos explicada del sistema.** |
| Cerrar y reabrir | ¿Espera que sus préstamos sigan ahí, o le sorprende? |

**Preguntas al terminar** (nunca durante)

1. ¿Qué creíste que hacía cada botón del menú antes de entrar?
2. ¿En qué momento no supiste qué hacer?
3. ¿Para qué entendiste que sirve un pase de lectura?
4. ¿Hubo algo que creíste haber hecho y resultó que no?
5. Si tuvieras que explicarle esto a otra persona en una frase, ¿qué dirías?

---

## Cambios de interfaz ya incorporados en el Laboratorio 8

Se registran aparte de la prueba porque son anteriores a ella: se derivaron de
revisar el proyecto con criterios de UI, UX y accesibilidad, no de observar a un
usuario. La evaluación sirve para confirmarlos o desmentirlos.

| Cambio | Problema que ataca |
| --- | --- |
| Tema centralizado `ui_theme.tres` con los cuatro estados del botón | Un botón sin estado *hover* ni *pressed* no confirma que se pulsó |
| Contraste del botón deshabilitado de 3.07:1 a 4.53:1 | Un botón apagado comunica información y no se leía |
| Iconografía de apoyo en las acciones recurrentes | El texto solo obliga a leer cada botón entero |
| Popup de confirmación del préstamo | El registro terminaba con una línea de texto fácil de pasar por alto |
| Navegación completa por teclado | El sistema solo se podía usar con ratón |
| Prefijos *Listo* y *Atención* en los veredictos | El resultado se distinguía únicamente por el color |
| Marca textual *prestado* en el estante | La indisponibilidad se señalaba solo apagando el botón |
| Fondo de la sala en el vestíbulo | La pantalla de entrada no comunicaba de qué trata el proyecto |

---

## Evaluación de Usabilidad 2

_(Pendiente. Se realizará tras aplicar las mejoras derivadas de la primera.)_
