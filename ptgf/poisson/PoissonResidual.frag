#version 120 
#extension GL_ARB_draw_buffers : enable

uniform sampler2D gx; 
uniform sampler2D gy; 
uniform sampler2D dc; 
uniform sampler2D u;

uniform float sw;
uniform float sh;
uniform float m;
uniform float c;
uniform float e;

void main(void) {

  // divergence 
  vec4 f = (texture2D(gx,gl_TexCoord[0].st)-
	    texture2D(gx,gl_TexCoord[0].st-vec2(sw,0.0)) +
	    texture2D(gy,gl_TexCoord[0].st)-
	    texture2D(gy,gl_TexCoord[0].st-vec2(0.0,sh)));
  

  // residual (beginning: u=0), then res=f
  vec4 ucurrent = texture2D(u,gl_TexCoord[0].st);
  vec4 r = (ucurrent*m +
	    (texture2D(u,gl_TexCoord[0].st+vec2( sw, sh)) +
	     texture2D(u,gl_TexCoord[0].st+vec2(-sw, sh)) +
	     texture2D(u,gl_TexCoord[0].st+vec2( sw,-sh)) +
	     texture2D(u,gl_TexCoord[0].st+vec2(-sw,-sh)))*c +
	    (texture2D(u,gl_TexCoord[0].st+vec2(sw ,0.0)) +
	     texture2D(u,gl_TexCoord[0].st+vec2(-sw,0.0)) +
	     texture2D(u,gl_TexCoord[0].st+vec2(0.0, sh)) +
	     texture2D(u,gl_TexCoord[0].st+vec2(0.0,-sh)))*e );

  // Dirichlet constraints 
  vec4 oc = texture2D(dc,gl_TexCoord[0].st);
  vec4 nc = mix(vec4(-1.0),oc-ucurrent,step(0.0,oc));

  gl_FragData[0] = f-r;
  gl_FragData[1] = nc;
}
