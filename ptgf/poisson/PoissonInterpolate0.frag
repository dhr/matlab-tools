#version 120

uniform sampler2D u;
uniform float sw2;
uniform float sh2;

void main(void) {
  // simple access to the currentLevel+1 in the texture 
  gl_FragColor = texture2D(u,gl_TexCoord[0].st+vec2(sw2,sh2));
}
