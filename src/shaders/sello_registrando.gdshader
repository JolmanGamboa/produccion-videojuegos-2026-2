shader_type canvas_item;

// ============================================================================
// sello_registrando.gdshader — La ondulación de la tinta al sellar el préstamo
// ============================================================================
// Distorsiona la imagen del ejemplar desplazando las coordenadas con las que se
// consulta la textura, siguiendo una onda que avanza con el tiempo.
//
// Lo importante de este efecto es lo que NO hace: el ejemplar no se mueve de
// sitio. Lo que cambia es qué región de la textura se lee en cada fragmento, de
// modo que el dibujo ondula dentro de su propio rectángulo. Es la diferencia
// entre transformar la geometría y alterar el muestreo, y aquí se ve sola:
// el nodo conserva su posición, su escala y su caja de colisión.
//
// Se activa únicamente durante `registrando`, el estado en que el gestor está
// escribiendo el préstamo en disco. Dura 0,6 s, es el único tramo del ciclo que
// no tenía nada que lo distinguiera a la vista, y es justo el momento en que el
// sistema está haciendo algo que el lector no puede ver.
// ----------------------------------------------------------------------------

// Cuánto se desplaza el muestreo, en coordenadas UV. Por encima de 0,02 el
// dibujo se vuelve ilegible: una distorsión que no se lee no comunica nada.
uniform float intensidad : hint_range(0.0, 0.05) = 0.010;

// Cuántas crestas de onda caben a lo alto del fotograma.
uniform float frecuencia : hint_range(1.0, 80.0) = 22.0;

// Velocidad a la que la onda recorre la imagen.
uniform float velocidad : hint_range(0.0, 10.0) = 4.0;


void fragment() {
	vec2 uv_ondulado = UV;

	// sin() oscila entre -1.0 y 1.0. El término con UV.y hace que la onda
	// recorra la imagen de arriba abajo; el término con TIME la pone en
	// movimiento sin que GDScript tenga que tocar nada cada fotograma.
	float onda = sin(UV.y * frecuencia + TIME * velocidad);

	uv_ondulado.x += onda * intensidad;

	// Multiplicar por COLOR conserva lo que el nodo ya traía: el tinte del
	// estante que la sala aplica a cada ejemplar y la opacidad de las
	// animaciones de entrada.
	COLOR = texture(TEXTURE, uv_ondulado) * COLOR;
}
