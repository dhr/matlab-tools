#version 120 

uniform sampler2D f; 
uniform sampler2D u;
uniform sampler2D dc;

uniform float sw;
uniform float sh;
uniform float x;
uniform float c;
uniform float e;
uniform float t;

void main(void) {
  
  // current solution for this level
  vec4 fi = texture2D(f,gl_TexCoord[0].st);
  
  // jacobi iteration
  vec4 lui = (texture2D(u,gl_TexCoord[0].st)*x +
	      (texture2D(u,gl_TexCoord[0].st+vec2( sw, sh)) +
	       texture2D(u,gl_TexCoord[0].st+vec2(-sw, sh)) +
	       texture2D(u,gl_TexCoord[0].st+vec2( sw,-sh)) +
	       texture2D(u,gl_TexCoord[0].st+vec2(-sw,-sh)))*c +
	      (texture2D(u,gl_TexCoord[0].st+vec2(sw,0.0)) +
	       texture2D(u,gl_TexCoord[0].st-vec2(sw,0.0)) +
	       texture2D(u,gl_TexCoord[0].st+vec2(0.0,sh)) +
	       texture2D(u,gl_TexCoord[0].st-vec2(0.0,sh)))*e );

  // current constraints 
  vec4 co = texture2D(dc,gl_TexCoord[0].st);

  // refine... except if we are on a constraint
  gl_FragColor = mix((fi-lui)*t,co,step(0.0,co));
}
