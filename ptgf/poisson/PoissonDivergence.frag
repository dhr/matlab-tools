#version 120 
#extension GL_ARB_draw_buffers : enable

uniform sampler2D gx; 
uniform sampler2D gy; 
uniform sampler2D dc; 

uniform float sw;
uniform float sh;

void main(void) {
  // divergence 
  gl_FragData[0] = (texture2D(gx,gl_TexCoord[0].st)-
  		    texture2D(gx,gl_TexCoord[0].st-vec2(sw,0.0)) +
  		    texture2D(gy,gl_TexCoord[0].st)-
  		    texture2D(gy,gl_TexCoord[0].st-vec2(0.0,sh)));

  // keeping original constraints 
  gl_FragData[1] = texture2D(dc,gl_TexCoord[0].st);
}
