shader_type canvas_item;
render_mode unshaded;

// Fixed palette sampled from the user's color reference, shared by every
// frame and the menu portrait. Preserve alpha for the hand-drawn silhouette.
// Light green #165E36, dark green #094123, skin #E38268,
// red #BF0202, ink #010201.
uniform vec4 green : source_color = vec4(0.08627451, 0.36862745, 0.21176471, 1.0);
uniform vec4 dark_green : source_color = vec4(0.03529412, 0.25490196, 0.13725490, 1.0);
uniform vec4 skin : source_color = vec4(0.89019608, 0.50980392, 0.40784314, 1.0);
uniform vec4 red : source_color = vec4(0.74901961, 0.00784314, 0.00784314, 1.0);
uniform vec4 ink : source_color = vec4(0.00392157, 0.00784314, 0.00392157, 1.0);

varying vec4 vertex_tint;

void vertex() {
	// Fragment COLOR already includes the source texture. Capture only the
	// vertex/modulate tint so the old pixel colors cannot darken the palette.
	vertex_tint = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 paint = ink.rgb;
	float brightest = max(source.r, max(source.g, source.b));
	if (brightest > 0.14) {
		if (source.g > source.r * 1.12 && source.g > source.b * 1.05) {
			paint = source.g < 0.18 ? dark_green.rgb : green.rgb;
		} else if (source.r > source.g * 1.25 && source.r > source.b * 1.25) {
			paint = source.r > source.g * 3.0 ? red.rgb : skin.rgb;
		}
	}
	// Generated interiors can contain slightly translucent pixels. Keep the
	// paint opaque so the floor cannot alter its color between frames.
	float opacity = source.a >= 0.95 ? 1.0 : source.a;
	COLOR = vec4(paint, opacity) * vertex_tint;
}
