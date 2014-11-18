varying vec3 normal;
varying float depth;

uniform bool Clamped;

void main()
{
	if (Clamped)
		gl_FragColor.rgb = (normalize(normal) + 1.0)*0.5;
	else
		gl_FragColor.rgb = normalize(normal);
	gl_FragColor.a = depth;
}
