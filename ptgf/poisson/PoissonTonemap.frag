#version 120

uniform sampler2D u;
uniform sampler2D a;
uniform float level;

void main(void) {
  // difference between initial result and averaged result texture 
  gl_FragColor = (texture2D(u,gl_TexCoord[0].st) - 
		  texture2DLod(a,vec2(0.5,0.5),level));
}
