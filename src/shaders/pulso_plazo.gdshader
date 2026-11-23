shader_type canvas_item;

// ============================================================================
// pulso_plazo.gdshader — El latido del reloj cuando aprieta el plazo
// ============================================================================
// Resuelve el Reto 2 del laboratorio: un resplandor animado que comunica una
// condición y se mantiene solo, sin que GDScript actualice sus parámetros en
// cada fotograma.
//
// Esa es la idea que vale la pena entender. El único dato que entra desde el
// juego es `urgencia`, y se escribe una sola vez: cuando el préstamo cambia de
// tramo. De ahí en adelante el latido lo lleva `TIME` dentro del shader, en la
// GPU. Un `Tween` en GDScript haría lo mismo a costa de un nodo y de trabajo en
// la CPU por cada reloj en pantalla.
//
// El pulso es además un cuarto canal de información. El reloj ya distinguía sus
// estados por el color del aro, por la velocidad de la aguja y por cuánto arco
// quedaba dibujado; esto añade un ritmo. Nada de lo que comunica depende solo
// del color, que es la regla que el proyecto sigue desde el Laboratorio 8.
// ----------------------------------------------------------------------------

// 0.0 cuando el plazo va holgado, 1.0 cuando ya venció. Lo escribe
// `reloj_plazo.gd` al cambiar de estado, una vez por cambio.
uniform float urgencia : hint_range(0.0, 1.0) = 0.0;

// Color del resplandor. Por defecto, el dorado del tema.
uniform vec4 color_pulso : source_color = vec4(0.851, 0.627, 0.329, 1.0);

// Latidos por segundo con la urgencia al máximo.
uniform float ritmo : hint_range(0.5, 6.0) = 2.6;

// Cuánto llega a aclararse la imagen en la cresta del latido.
uniform float amplitud : hint_range(0.0, 1.0) = 0.45;


void fragment() {
	vec4 texel = texture(TEXTURE, UV);

	// El latido acelera con la urgencia: lento cuando queda plazo, insistente
	// cuando no. Con urgencia 0.0 la frecuencia no llega a cero, de modo que el
	// reloj respira en vez de quedarse muerto.
	float frecuencia = mix(0.6, ritmo, urgencia);

	// sin() va de -1.0 a 1.0; esto lo lleva a 0.0 … 1.0 para poder usarlo como
	// una mezcla.
	float latido = sin(TIME * frecuencia * TAU) * 0.5 + 0.5;

	// La urgencia gobierna también cuánto se nota el latido, así que un plazo
	// holgado apenas pulsa aunque su reloj use el mismo shader.
	float mezcla = latido * amplitud * urgencia;

	// Se mezcla solo el color, nunca el alfa: el resplandor no puede encender
	// los píxeles vacíos de alrededor ni recortar la silueta del reloj.
	vec3 encendido = mix(texel.rgb, color_pulso.rgb, mezcla);

	COLOR = vec4(encendido, texel.a) * COLOR;
}
