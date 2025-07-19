#version 330

in vec2 fragTexCoord;
out vec4 finalColor;

uniform sampler2D texture0;
uniform int u_tex_height;
uniform int u_tex_width;

uniform float u_camera_offset_x;
uniform float u_camera_offset_y;

uniform float u_wave_center_x;
uniform float u_wave_center_y;

uniform float u_time;

#define MAX_RIPPLES 10
uniform float u_times[MAX_RIPPLES];
uniform float u_diffuse[MAX_RIPPLES];
uniform vec2 u_centers[MAX_RIPPLES];
uniform int u_gradients[MAX_RIPPLES];
uniform int u_ripples_count;

#define PALETTE_COUNT 10
uniform vec3 u_palette[PALETTE_COUNT];


void main() {
	finalColor = texture(texture0, fragTexCoord.xy);
	for (int i = 0; i < u_ripples_count; i++) {
		float time = u_times[i];
		float offset = time;
		float current_time = offset;
		vec3 wave_params = vec3(10.0, 0.8, 0.1 );
		float ratio = float(u_tex_height)/float(u_tex_width);
		vec2 uv = fragTexCoord.xy;

		vec2 center = u_centers[i];
		center.y = 1 - center.y;
		vec2 wave_center = center;
		float dist = distance(uv, wave_center);

		if ((dist <= ((current_time) + (wave_params.z))) &&
				(dist >= ((current_time) - (wave_params.z))))
		{
			float diff = (dist - current_time );
			float scale_diff = (1.0 - pow(abs(diff * wave_params.x), wave_params.y));
			float diffuse = u_diffuse[i];
			float diff_time = (diff  * scale_diff);
			uv += ((normalize(uv - wave_center) * diff_time) / ((current_time * dist * diffuse) + 1));
			vec4 color = texture(texture0, uv);
			if (color == vec4(1, 1, 1, 1)) {
				color = vec4(u_palette[u_gradients[i]], 1);
			}
			color += (color * scale_diff) / ((current_time * dist * diffuse) + 1);
			finalColor += vec4(color.rgb, 1);
		}
	}
}
