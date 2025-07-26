precision mediump float;

varying vec2 fragTexCoord;

uniform sampler2D texture0;
uniform sampler2D from;

uniform float progress;


void main() {
	float diamond_size = 20.0;
	float x_coefficient = 1.0;
	float y_coefficient = 1.0;

    float xFraction = fract(fragTexCoord.x * diamond_size);
    float yFraction = fract(fragTexCoord.y * diamond_size);

    float xDistance = abs(xFraction - 0.5);
    float yDistance = abs(yFraction - 0.5);

    vec2 flipped = vec2(0.0, 1.0) - fragTexCoord;
    flipped *= vec2(-1.0, 1.0);

    if (xDistance + yDistance + (fragTexCoord.x * x_coefficient) + (fragTexCoord.y * y_coefficient) > progress * 4.0) {
        gl_FragColor = texture2D(from, flipped);
    }
    else gl_FragColor  = texture2D(texture0, flipped);
}
