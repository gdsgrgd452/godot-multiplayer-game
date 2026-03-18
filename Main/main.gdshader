shader_type canvas_item;

// We export these variables so you can easily change them in the Inspector!
uniform float square_size = 100.0;
uniform vec4 color1 : source_color = vec4(0.2, 0.2, 0.2, 1.0); // Dark square
uniform vec4 color2 : source_color = vec4(0.3, 0.3, 0.3, 1.0); // Light square

varying vec2 world_pos;

void vertex() {
	// Grab the actual world coordinates so the grid stays locked in place
	// when the player's camera moves around!
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Math to create a grid of squares based on your world position
	vec2 grid = floor(world_pos / square_size);
	
	// Modulo 2 creates the alternating 0 and 1 pattern (the checkerboard)
	float checker = mod(grid.x + grid.y, 2.0);
	
	// Mix the two colors together based on that 0 or 1 pattern
	COLOR = mix(color1, color2, checker);
}
