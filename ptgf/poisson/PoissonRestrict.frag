#version 120 
#extension GL_ARB_draw_buffers : enable

uniform sampler2D f; 
uniform sampler2D dc; 

uniform float sw2;
uniform float sh2;
uniform float sw4;
uniform float sh4;

void main(void) {
  // restrict residual 
  gl_FragData[0] = (texture2D(f,gl_TexCoord[0].st) +
		    texture2D(f,gl_TexCoord[0].st-vec2(0.0,sh2)) +
		    texture2D(f,gl_TexCoord[0].st-vec2(sw2,sh2)) +
		    texture2D(f,gl_TexCoord[0].st-vec2(sw2,0.0)));

  vec4 v1 = texture2D(f,gl_TexCoord[0].st);
  vec4 v2 = texture2D(f,gl_TexCoord[0].st-vec2(0.0,sh2));
  vec4 v3 = texture2D(f,gl_TexCoord[0].st-vec2(sw2,sh2));
  vec4 v4 = texture2D(f,gl_TexCoord[0].st-vec2(sw2,0.0));

  // compute color contraints
  vec4 sum = vec4(0.0);
  vec4 nb  = vec4(0.0);
  vec4 c[4];

  c[0] = texture2D(dc,gl_TexCoord[0].st+vec2( sw4, sh4));
  c[1] = texture2D(dc,gl_TexCoord[0].st+vec2(-sw4, sh4));
  c[2] = texture2D(dc,gl_TexCoord[0].st+vec2(-sw4,-sh4));
  c[3] = texture2D(dc,gl_TexCoord[0].st+vec2( sw4,-sh4));

  for(int i=0;i<4;++i) {
    sum += max(vec4(0.0),c[i]);
    nb  += step(0.0,c[i]);
  }
  
  vec4 snb = sign(nb); 
  gl_FragData[1] = mix(vec4(-1.0),sum/(nb+vec4(1.0)-snb),snb); 
}
