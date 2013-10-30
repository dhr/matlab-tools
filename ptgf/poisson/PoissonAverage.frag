#version 120

uniform sampler2D u;

void main(void) {
  // simple access to the current texture 
  gl_FragColor = texture2D(u,gl_TexCoord[0].st);
}
