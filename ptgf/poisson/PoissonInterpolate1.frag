#version 120

uniform sampler2D u;
uniform sampler2D u0;
uniform float sw2;
uniform float sh2;

void main(void) {
  gl_FragColor = (texture2D(u,gl_TexCoord[0].st+vec2(sw2,sh2)) +
		  texture2D(u0,gl_TexCoord[0].st));
}
