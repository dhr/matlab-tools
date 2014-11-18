uniform bool UseSoftShading;
uniform bool OrthographicProjection;

varying vec3 ecPosition;
varying vec3 normal;

void main()
{
  vec4 lightPos = gl_LightSource[0].position;
  
  vec3 lightVector;
  if (lightPos.w != 0.0)
    lightVector = normalize(lightPos.xyz/lightPos.w - ecPosition);
  else
    lightVector = normalize(lightPos.xyz);
  
  vec3 normedNormal = normalize(normal);
  float nDotV = dot(normedNormal, lightVector);
  float nDotEC;
  if (OrthographicProjection)
    nDotEC = dot(normedNormal, vec3(0, 0, 1));
  else
    nDotEC = dot(normedNormal, normalize(-ecPosition));
  
  gl_LightProducts lightProduct;
  gl_LightModelProducts lightModelProduct;
  gl_MaterialParameters material;
  if (nDotEC > 0.0) { /* gl_FrontFacing broken for some drivers... */
    lightProduct = gl_FrontLightProduct[0];
    lightModelProduct = gl_FrontLightModelProduct;
    material = gl_FrontMaterial;
  } else {
    nDotV = -nDotV;
    lightProduct = gl_BackLightProduct[0];
    lightModelProduct = gl_BackLightModelProduct;
    material = gl_BackMaterial;
  }

  if (UseSoftShading) {
    nDotV = 0.5 * (nDotV + 1.0);
  } else {
    nDotV = clamp(nDotV, 0.0, 1.0);
  }

  vec4 ambColor = lightModelProduct.sceneColor + lightProduct.ambient;
  vec4 diffColor = nDotV * gl_Color * gl_LightSource[0].diffuse;
  gl_FragColor = ambColor + diffColor;
}
