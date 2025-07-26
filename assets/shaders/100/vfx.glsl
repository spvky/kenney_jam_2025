precision mediump float;

varying vec2 fragTexCoord;

uniform sampler2D texture0;

#define MAX_RIPPLES 10
uniform float u_times[MAX_RIPPLES];
uniform float u_diffuse[MAX_RIPPLES];
uniform vec2 u_centers[MAX_RIPPLES];
uniform int u_gradients[MAX_RIPPLES];
uniform int u_ripples_count;

#define PALETTE_COUNT 10
uniform vec3 u_palette[PALETTE_COUNT];

vec3 get_palette_color(int index) {
    if (index == 0) return u_palette[0];
    else if (index == 1) return u_palette[1];
    else if (index == 2) return u_palette[2];
    else if (index == 3) return u_palette[3];
    else if (index == 4) return u_palette[4];
    else if (index == 5) return u_palette[5];
    else if (index == 6) return u_palette[6];
    else if (index == 7) return u_palette[7];
    else if (index == 8) return u_palette[8];
    else if (index == 9) return u_palette[9];
    else return vec3(1.0, 0.0, 1.0); // Fallback magenta
}


void main() {
	vec4 finalColor = texture2D(texture0, fragTexCoord.xy);
	int count = u_ripples_count;
	for (int i = 0; i < MAX_RIPPLES; i++) {
		if (i >= u_ripples_count) break;
		float time = u_times[i];
		float offset = time;
		float current_time = offset;
		vec3 wave_params = vec3(10.0, 0.8, 0.1 );
		vec2 uv = fragTexCoord.xy;

		vec2 center = u_centers[i];
		center.y = 1.0 - center.y;
		vec2 wave_center = center;
		float dist = distance(uv, wave_center);

		if ((dist <= ((current_time) + (wave_params.z))) &&
				(dist >= ((current_time) - (wave_params.z))))
		{
			float diff = (dist - current_time );
			float scale_diff = (1.0 - pow(abs(diff * wave_params.x), wave_params.y));
			float diffuse = u_diffuse[i];
			float diff_time = (diff  * scale_diff);
			uv += ((normalize(uv - wave_center) * diff_time) / ((current_time * dist * diffuse) + 1.0));
			vec4 color = texture2D(texture0, uv);
			if (color == vec4(1.0, 1.0, 1.0, 1.0)) {
				color = vec4(get_palette_color(u_gradients[i]), 1);
			}
			color += (color * scale_diff) / ((current_time * dist * diffuse) + 1.0);
			finalColor += vec4(color.rgb, 1.0);
		}
	}

	gl_FragColor = finalColor;
}
