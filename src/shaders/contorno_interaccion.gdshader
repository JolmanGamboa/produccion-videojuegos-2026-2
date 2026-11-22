shader_type canvas_item;

// ============================================================================
// contorno_interaccion.gdshader — El borde que dice «esto se puede abrir»
// ============================================================================
// Dibuja un contorno alrededor de la silueta del ejemplar consultando, para
// cada fragmento transparente, sus ocho píxeles vecinos. Si alguno de ellos
// pertenece al dibujo, este fragmento está en el borde y se pinta.
//
// No calcula la silueta geométrica: la aproxima leyendo el canal alfa de la
// textura. Por eso el resultado depende de la distancia de muestreo, y por eso
// la hoja de sprites lleva dos píxeles de margen alrededor de cada fotograma:
// sin ellos, los vecinos de un borde serían píxeles del fotograma de al lado y
// el contorno saldría con la silueta equivocada.
//
// El color llega desde fuera. Cada estante del catálogo tiene el suyo en
// `CategoriaData.color`, de modo que un único shader sirve para los diecisiete
// ejemplares sin una sola textura adicional: es la razón de ser de `uniform`.
// ----------------------------------------------------------------------------

// Color del contorno. `source_color` le dice al editor que es un color y no
// cuatro números sueltos, para que muestre el selector.
uniform vec4 color_contorno : source_color = vec4(0.851, 0.627, 0.329, 1.0);

// Grosor, medido en píxeles de la textura. Por encima del margen de la hoja el
// contorno se recorta, así que el rango se queda en 2.0.
uniform float grosor : hint_range(0.5, 2.0, 0.5) = 1.0;

// Opacidad general, para poder encender y apagar el contorno con una animación
// en vez de un corte seco.
uniform float intensidad : hint_range(0.0, 1.0) = 1.0;


void fragment() {
	vec4 texel = texture(TEXTURE, UV);

	// TEXTURE_PIXEL_SIZE es cuánto mide un píxel de la textura en coordenadas
	// UV, que van de 0.0 a 1.0 sea cual sea la resolución. Multiplicarlo por el
	// grosor da el salto que hay que dar para mirar al vecino.
	vec2 salto = TEXTURE_PIXEL_SIZE * grosor;

	// Se queda con el alfa más alto de los ocho vecinos: basta con que uno
	// pertenezca al dibujo para que este fragmento esté en el borde.
	float alfa_vecino = 0.0;
	alfa_vecino = max(alfa_vecino, texture(TEXTURE, UV + vec2(salto.x, 0.0)).a);
	alfa_vecino = max(alfa_vecino, texture(TEXTURE, UV - vec2(salto.x, 0.0)).a);
	alfa_vecino = max(alfa_vecino, texture(TEXTURE, UV + vec2(0.0, salto.y)).a);
	alfa_vecino = max(alfa_vecino, texture(TEXTURE, UV - vec2(0.0, salto.y)).a);
	alfa_vecino = max(alfa_vecino, texture(TEXTURE, UV + salto).a);
	alfa_vecino = max(alfa_vecino, texture(TEXTURE, UV - salto).a);
	alfa_vecino = max(alfa_vecino, texture(TEXTURE, UV + vec2(salto.x, -salto.y)).a);
	alfa_vecino = max(alfa_vecino, texture(TEXTURE, UV + vec2(-salto.x, salto.y)).a);

	// El contorno vive solo donde este fragmento está vacío y un vecino no lo
	// está. El factor (1.0 - texel.a) apaga el efecto dentro del dibujo.
	float alfa_contorno = alfa_vecino * (1.0 - texel.a);

	if (texel.a < 0.01 && alfa_contorno > 0.01) {
		COLOR = vec4(color_contorno.rgb, color_contorno.a * alfa_contorno * intensidad);
	} else {
		// Descartar es más barato que dibujar con alfa cero, y además evita
		// que este sprite auxiliar tape al ejemplar que tiene delante.
		discard;
	}
}
