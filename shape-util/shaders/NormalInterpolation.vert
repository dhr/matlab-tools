varying vec3 normal;
varying float depth;

uniform bool TransformNormal;

void main()
{
	gl_Position = ftransform();

	if (TransformNormal)
		normal = gl_NormalMatrix * gl_Normal;
	else
		normal = gl_Normal;
	
	vec4 ecPosition = gl_ModelViewMatrix * gl_Vertex;

	depth = length(vec3(ecPosition) / ecPosition.w);
}
