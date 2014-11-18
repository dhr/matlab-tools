uniform bool OrthographicProjection;

varying vec3 ecPosition;
varying vec3 normal;

void main()
{
  vec4 position = (gl_ModelViewMatrix * gl_Vertex);
  ecPosition = position.xyz/position.w;
  normal = normalize(gl_NormalMatrix * gl_Normal);
  
  float nDotEC;
  if (OrthographicProjection)
    nDotEC = dot(normal, vec3(0, 0, 1));
  else
    nDotEC = dot(normal, normalize(-ecPosition));
  
  if (nDotEC > 0.0)
    gl_FrontColor = gl_Color;
  else
    gl_BackColor = gl_Color;
    
  gl_Position = ftransform();
}
