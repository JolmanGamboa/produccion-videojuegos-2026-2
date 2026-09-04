# ADR 0001 — Navegación desacoplada mediante un Event Bus global

| Campo | Valor |
| --- | --- |
| **Estado** | Aceptada |
| **Fecha** | 2026-09-03 |
| **Autor** | Jolman Harley Gamboa Salamanca |
| **Contexto del curso** | Producción de Videojuegos 2026-2 — Corte 1, Laboratorio 2 |
| **Reemplaza a** | Navegación directa con `get_tree().change_scene_to_file()` (Laboratorio 1) |

## 1. Contexto

El prototipo del Laboratorio 1 resolvía la navegación con un nodo utilitario
(`change_scene.gd`) que invocaba `get_tree().change_scene_to_file()` sobre rutas
de texto absolutas. Ese diseño funcionaba con dos pantallas, pero presentaba
tres problemas verificables al crecer a los cuatro entornos de la Biblioteca
Interactiva (vestíbulo, sala de lectura, configuración y créditos):

1. **Acoplamiento por ruta.** Cada emisor conocía la ubicación física del
   destino. Renombrar una carpeta obligaba a editar todos los emisores: un
   *efecto dominó* de complejidad O(n) sobre el número de pantallas.
2. **Dependencias cruzadas.** El menú dependía del nivel y el nivel del menú, un
   ciclo que impide probar o reutilizar un panel de forma aislada.
3. **Ciclo de vida opaco.** `change_scene_to_file()` libera la escena anterior de
   forma implícita, sin un punto único donde auditar la liberación de memoria ni
   donde conservar estado entre pantallas.

## 2. Decisión

Se adopta un **Event Bus global** implementado como Autoload de Godot 4
(`res://src/core/event_bus.gd`, identificador `EventBus`), que combina los
patrones **Singleton** (instancia única viva durante toda la aplicación) y
**Observer** (publicación y suscripción de eventos).

Reglas derivadas de la decisión:

- El bus solo declara señales con tipado estático estricto y las rutas de escena
  como constantes; **no contiene lógica de negocio ni referencias a nodos**:

  ```gdscript
  signal navigation_requested(target_scene_path: String)
  signal parameter_changed(param_name: String, value: Variant)
  ```

- Los paneles de interfaz son **únicamente emisores**. Ningún panel llama a
  `get_tree().change_scene_to_file()` ni referencia a otro panel.
- `MainApp` (`res://src/core/main_app.tscn`, escena principal del proyecto) es el
  **único suscriptor con autoridad** sobre el árbol: instancia el panel entrante
  en `ViewContainer` y libera el anterior con `queue_free()`, anulando después la
  referencia lógica para evitar fugas de memoria.
- La suscripción a `navigation_requested` se realiza con `CONNECT_DEFERRED`, de
  modo que el panel emisor termina de procesar su propio evento antes de que su
  nodo sea destruido.
- `MainApp` persiste los valores recibidos por `parameter_changed` en un
  diccionario y los reinyecta en cada panel nuevo que implemente el método
  `aplicar_parametro()`, con lo que la configuración del lector sobrevive a la
  destrucción de las escenas.

## 3. Alternativas consideradas

| Alternativa | Motivo del rechazo |
| --- | --- |
| Mantener `change_scene_to_file()` con constantes centralizadas | Reduce los literales dispersos, pero el emisor sigue decidiendo el destino y conservando la dependencia cruzada entre pantallas. |
| Señales locales encadenadas hacia un nodo padre (*signal bubbling*) | Obliga a que cada panel conozca la posición exacta de su padre en el árbol; se rompe al reordenar la jerarquía. |
| Un `SceneManager` inyectado por dependencia en cada panel | Elimina las rutas, pero introduce un contrato de inicialización obligatorio en cada escena y complica instanciarlas de forma aislada para pruebas. |
| Máquina de estados finitos global | Solución adecuada para el flujo de juego futuro, pero desproporcionada para cuatro pantallas de interfaz en este corte. |

## 4. Consecuencias

**Positivas**

- Agregar un estante o un panel nuevo cuesta una constante en el bus y una línea
  de conexión: no se modifica ningún emisor existente.
- La liberación de memoria queda auditable en un solo método (`_cargar_panel`),
  observable en el *Debugger* de Godot por el conteo de nodos.
- Los paneles son escenas autónomas: se pueden ejecutar con `F6` sin arrastrar
  dependencias, lo que facilita las pruebas manuales.
- La configuración global (estante activo, tamaño de sinopsis) persiste sin
  guardar estado dentro de las vistas.

**Negativas y mitigaciones**

- *Indirección:* el flujo ya no se lee de forma lineal en el código del emisor.
  Se mitiga documentando el bus y trazando cada evento con `print()` con prefijo
  del módulo emisor.
- *Señales huérfanas:* un evento sin suscriptor falla en silencio. Se mitiga
  concentrando la suscripción en `MainApp._ready()` y validando la ruta recibida
  con `push_error()` cuando el recurso no se puede cargar.
- *Acoplamiento residual al Autoload:* todos los paneles dependen del símbolo
  global `EventBus`. Se acepta como costo consciente frente a la dependencia
  mutua entre escenas.

## 5. Validación

- El proyecto arranca en `res://src/core/main_app.tscn` y monta el vestíbulo sin
  que ninguna escena de interfaz conozca la ruta de otra.
- Recorrido completo vestíbulo → sala de lectura → configuración → créditos →
  vestíbulo sin fugas: el panel anterior desaparece del árbol en el *Debugger*.
- Un cambio de estante emitido desde configuración se refleja en la sala de
  lectura tras navegar hacia ella, sin comunicación directa entre ambos paneles.
