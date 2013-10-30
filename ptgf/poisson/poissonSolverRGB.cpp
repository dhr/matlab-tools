#include "poissonSolverRGB.h"

using namespace std;
string rgbPath = "filters/poissonRGB/shaders/";

PoissonSolverRGB::PoissonSolverRGB() 
  : _gx(NULL),
    _gy(NULL),
    _dc(NULL),
    _output(NULL),
    _avTex(NULL),
    _avFbo(NULL),
    _residual(NULL),
    _divergence(NULL),
    _average(NULL),
    _tonemap(NULL),
    _w(0), 
    _h(0),
    _aw(64), 
    _ah(64), 
    _nb(0) {
  
}

PoissonSolverRGB::~PoissonSolverRGB() {
  finalize();
}

void PoissonSolverRGB::initialize(unsigned int w,
				  unsigned int h,
				  FloatTexture2D *gx,
				  FloatTexture2D *gy,
				  FloatTexture2D *dc,
				  FloatTexture2D *output) {
  // clean all first
  finalize();

  // get texture and sizes 
  _gx = gx;
  _gy = gy;
  _dc = dc;
  
  _w = w;
  _h = h;

  glGetIntegerv(GL_VIEWPORT,_v);

  // init gpu data 
  initLevels(output);
  initShaders();

  glClearColor(0.0f,0.0f,0.0f,0.0f);

  // init solution 
  Utils::swapToQuadMode(_w,_h);
  _levels[0]->fbo()->bind();
  glDrawBuffer(GL_COLOR_ATTACHMENT2_EXT);
  glClear(GL_COLOR_BUFFER_BIT);
  Utils::swapToWorldMode();
  FramebufferObject::unbind();
}

void PoissonSolverRGB::update(bool tonemap,bool init) {
  glClearColor(0.0f,0.0f,0.0f,0.0f);

  GLenum bufs[2] = {GL_COLOR_ATTACHMENT0_EXT,
		    GL_COLOR_ATTACHMENT1_EXT};

  Utils::swapToQuadMode(_w,_h);
  setTexWrap(_gx,GL_CLAMP_TO_BORDER);
  setTexWrap(_gy,GL_CLAMP_TO_BORDER);
  setTexWrap(_dc,GL_CLAMP_TO_BORDER);

  _levels[0]->fbo()->bind();

  if(init) {
    // init solution to zero 
    glDrawBuffer(GL_COLOR_ATTACHMENT2_EXT);
    glClear(GL_COLOR_BUFFER_BIT);
  }

  // residual   
  drawQuads(2,bufs,_residual);

  // top-down process 
  for(unsigned int i=1;i<_nb;++i) {
    resizeViewport(_levels[i]->w(),_levels[i]->h());
    _levels[i]->fbo()->bind();

    // restriction from level i to i+1 
    drawQuads(2,bufs,_levels[i]->restrictShader());
  }

  // init last level solution to black
  _levels[_nb-1]->fbo()->bind();
  glDrawBuffer(GL_COLOR_ATTACHMENT2_EXT);
  glClear(GL_COLOR_BUFFER_BIT);
 
  // first relaxation (tmp solution at last level)
  drawQuad(GL_COLOR_ATTACHMENT3_EXT,_levels[_nb-1]->refine1Shader());  

  // second relaxation (final solution at last level)
  drawQuad(GL_COLOR_ATTACHMENT2_EXT,_levels[_nb-1]->refine2Shader()); 

  if(!init) {
    // We need to re-initialize divergence for the 1st level
    _levels[0]->fbo()->bind();
    resizeViewport(_levels[0]->w(),_levels[0]->h());
    drawQuads(2,bufs,_divergence);
  }

  // bottom-up process
  for(int i=_nb-2;i>=0;--i) {
    resizeViewport(_levels[i]->w(),_levels[i]->h());
    _levels[i]->fbo()->bind();
    
    // interpolation from level i+1 to i
    drawQuad(GL_COLOR_ATTACHMENT2_EXT,_levels[i]->interpolateShader()); 

    // first relaxation (tmp solution at level i)
    drawQuad(GL_COLOR_ATTACHMENT3_EXT,_levels[i]->refine1Shader()); 

    // second relaxation (final solution at level i)
    drawQuad(GL_COLOR_ATTACHMENT2_EXT,_levels[i]->refine2Shader()); 
  }

  // rescale the result for each color 
  if(tonemap) {

    // copy result in a small texture 
    resizeViewport(_aw,_ah);
    _avFbo->bind();
    drawQuad(GL_COLOR_ATTACHMENT0_EXT,_average);  

    // compute mipmaps 
    _avTex->bind();
    glGenerateMipmapEXT(GL_TEXTURE_2D);
    
    // rescale 
    resizeViewport(_levels[0]->w(),_levels[0]->h());
    _levels[0]->fbo()->bind();
    drawQuad(GL_COLOR_ATTACHMENT2_EXT,_tonemap);  
  }

  Utils::swapToWorldMode();
  FramebufferObject::unbind();
}

void PoissonSolverRGB::finalize() {
  // clean all 
  cleanLevels();
  cleanShaders();
}

void PoissonSolverRGB::initShaders() {
  // framebuffer object for tone mapping 
  TextureFormat tf = TextureFormat(GL_TEXTURE_2D,_aw,_ah,GL_RGBA16F_ARB,GL_RGBA,GL_FLOAT,0,TextureFormat::MIPMAP_FBO_AUTOM);
  TextureParams tp = TextureParams(GL_LINEAR_MIPMAP_LINEAR,GL_LINEAR);
  
  _avFbo = new FramebufferObject();
  _avTex = new FloatTexture2D(tf,tp);
  
  _avFbo->bind();
  _avTex->bind();
  _avFbo->attachTexture(GL_TEXTURE_2D,_avTex->id(),GL_COLOR_ATTACHMENT0_EXT);
  _avFbo->isValid();

  // shader creation 
  _residual   = new GPUProgram(rgbPath+"null.vs",rgbPath+"psrgb_residual.fs");
  _divergence = new GPUProgram(rgbPath+"null.vs",rgbPath+"psrgb_divergence.fs");
  _average    = new GPUProgram(rgbPath+"null.vs",rgbPath+"psrgb_average.fs");
  _tonemap    = new GPUProgram(rgbPath+"null.vs",rgbPath+"psrgb_tonemap.fs");

  _residual->enable();
  _residual->addUniform("gx");
  _residual->addUniform("gy");
  _residual->addUniform("dc");
  _residual->addUniform("u");
  _residual->addUniform("sw");
  _residual->addUniform("sh");
  _residual->addUniform("m");
  _residual->addUniform("c");
  _residual->addUniform("e");
  _residual->disable();

  _divergence->enable();
  _divergence->addUniform("gx");
  _divergence->addUniform("gy");
  _divergence->addUniform("dc");
  _divergence->addUniform("sw");
  _divergence->addUniform("sh");
  _divergence->disable();

  _average->enable();
  _average->addUniform("u");
  _average->disable();

  _tonemap->enable();
  _tonemap->addUniform("u");
  _tonemap->addUniform("a");
  _tonemap->addUniform("level");
  _tonemap->disable();

  for(unsigned int i=0;i<_nb;++i) {
   
    PoissonLevelRGB *prev = i==0     ? NULL : _levels[i-1];
    PoissonLevelRGB *next = i==_nb-1 ? NULL : _levels[i+1];
    
    _levels[i]->initShaders(prev,next);
  }

  sendUniforms();
}

void PoissonSolverRGB::cleanShaders() {
  // delete shaders 
  delete _residual;   _residual   = NULL;
  delete _divergence; _divergence = NULL;
  delete _average;    _average    = NULL;
  delete _tonemap;    _tonemap    = NULL;
  delete _avTex;      _avTex      = NULL;
  delete _avFbo;      _avFbo      = NULL;
}

void PoissonSolverRGB::sendUniforms() {
  if(_levels.empty()) 
    return;

  _residual->enable();
  _residual->setUniformTexture("gx",GL_TEXTURE_2D,_gx->id());
  _residual->setUniformTexture("gy",GL_TEXTURE_2D,_gy->id());
  _residual->setUniformTexture("dc",GL_TEXTURE_2D,_dc->id());
  _residual->setUniformTexture("u",GL_TEXTURE_2D,_levels[0]->uTex()->id());
  _residual->setUniform1f("sw",_levels[0]->sw());
  _residual->setUniform1f("sh",_levels[0]->sh());
  _residual->setUniform1f("m",_levels[0]->m());
  _residual->setUniform1f("c",_levels[0]->c());
  _residual->setUniform1f("e",_levels[0]->e());
  _residual->disable();

  _divergence->enable();
  _divergence->setUniformTexture("gx",GL_TEXTURE_2D,_gx->id());
  _divergence->setUniformTexture("gy",GL_TEXTURE_2D,_gy->id());
  _divergence->setUniformTexture("dc",GL_TEXTURE_2D,_dc->id());
  _divergence->setUniform1f("sw",_levels[0]->sw());
  _divergence->setUniform1f("sh",_levels[0]->sh());
  _divergence->disable();

  _average->enable();
  _average->setUniformTexture("u",GL_TEXTURE_2D,_levels[0]->uTex()->id());
  _average->disable();

  _tonemap->enable();
  _tonemap->setUniformTexture("u",GL_TEXTURE_2D,_levels[0]->uTex()->id());
  _tonemap->setUniformTexture("a",GL_TEXTURE_2D,_avTex->id());
  _tonemap->setUniform1f("level",log2((float)_aw));
  _tonemap->disable();
}

void PoissonSolverRGB::reloadShaders() {
  _residual->reload();
  _divergence->reload();
  _average->reload();
  _tonemap->reload();

  for(unsigned int i=0;i<_nb;++i) {
    _levels[i]->reloadShaders();
  }

  sendUniforms();
}

void PoissonSolverRGB::initLevels(FloatTexture2D *output) {
  int w = _w;
  int h = _h;
  int i =  0;

  if(_w<=0 || _h<=0) 
    return;

  do {    
    if(i==0) 
      _levels.push_back(new PoissonLevelRGB(i,w,h,output));
    else 
      _levels.push_back(new PoissonLevelRGB(i,w,h));
 
    w = std::max(1,w/2)+w%2;
    h = std::max(1,h/2)+h%2;
    i ++;
    
  } while(w!=1 && h!=1);

  _levels.push_back(new PoissonLevelRGB(i,1,1));
  _nb     = _levels.size();
  _output = _levels[0]->uTex();
}

void PoissonSolverRGB::cleanLevels() {
  for(unsigned int i=0;i<_nb;++i) {
    delete _levels[i];
  }
  _levels.clear();
}

PoissonLevelRGB::PoissonLevelRGB(int level,int w,int h,FloatTexture2D *output) 
  : _prev(NULL),
    _next(NULL),
    _level(level),
    _w(w),
    _h(h),
    _sw(1.0f/(float)w),
    _sh(1.0f/(float)h),
    _no(false) {
  
  // init other params 
  float s  = (float)(1 << level);
  float s2 = s*s;
  float m  = -8.0f*s2-4.0f;
  float e  = s2 + 2.0f;
  float c  = s2 - 1.0f;
  
  m /= 3*s2;
  e /= 3*s2;
  c /= 3*s2;
  
  _m = m;
  _e = e;
  _c = c;
  
  _x0 = -2.1532f + 0.5882f / s2 + 1.5070f / s;
  _x1 = 0.1138f + 1.5065f / s2 + 0.9529f / s;
  _t0 = 1.0f/(_m-_x0);
  _t1 = 1.0f/(_m-_x1);

  // init fbo and textures 
  GLint  filter = GL_LINEAR;
  GLint  wrap1  = GL_CLAMP_TO_BORDER;
  GLint  wrap2  = GL_CLAMP_TO_EDGE;
  GLenum format = GL_RGBA16F_ARB;
  
  TextureFormat tf1 = TextureFormat(GL_TEXTURE_2D,_w,_h,format,GL_RGBA,GL_FLOAT);
  TextureParams tp1 = TextureParams(filter,filter,wrap1,wrap1,wrap1);
  TextureParams tp2 = TextureParams(filter,filter,wrap2,wrap2,wrap2);
  
  _fbo  = new FramebufferObject();
  _fTex = new FloatTexture2D(tf1,tp1);
  _cTex = new FloatTexture2D(tf1,tp1);
  _tTex = new FloatTexture2D(tf1,tp2);
  _uTex = output ? output : new FloatTexture2D(tf1,tp2);

  if(_uTex==output) {
    // init parameters 
    _uTex->setData(tf1,tp2,NULL);
    _no = true;
  }

  // attach textures 
  _fbo->bind();
  _fbo->attachTexture(GL_TEXTURE_2D,_fTex->id(),GL_COLOR_ATTACHMENT0_EXT);
  _fbo->attachTexture(GL_TEXTURE_2D,_cTex->id(),GL_COLOR_ATTACHMENT1_EXT);
  _fbo->attachTexture(GL_TEXTURE_2D,_uTex->id(),GL_COLOR_ATTACHMENT2_EXT);
  _fbo->attachTexture(GL_TEXTURE_2D,_tTex->id(),GL_COLOR_ATTACHMENT3_EXT);
  _fbo->isValid();
  FramebufferObject::unbind();

  // creates shader programs 
  _restrict = new GPUProgram(rgbPath+"null.vs",rgbPath+"psrgb_restrict.fs");
  _refine1  = new GPUProgram(rgbPath+"null.vs",rgbPath+"psrgb_refine.fs");
  _refine2  = new GPUProgram(rgbPath+"null.vs",rgbPath+"psrgb_refine.fs");
 
  _restrict->enable();
  _restrict->addUniform("f");
  _restrict->addUniform("dc");
  _restrict->addUniform("sw2");
  _restrict->addUniform("sh2");
  _restrict->addUniform("sw4");
  _restrict->addUniform("sh4");
  _restrict->disable();

  if(level>0) {
    _interpolate = new GPUProgram(rgbPath+"null.vs",rgbPath+"psrgb_interpolate0.fs");
    _interpolate->enable();
    _interpolate->addUniform("u");
    _interpolate->addUniform("sw2");
    _interpolate->addUniform("sh2");
    _interpolate->disable();

  } else {
    _interpolate = new GPUProgram(rgbPath+"null.vs",rgbPath+"psrgb_interpolate1.fs");
    _interpolate->enable();
    _interpolate->addUniform("u");
    _interpolate->addUniform("u0");
    _interpolate->addUniform("sw2");
    _interpolate->addUniform("sh2");
    _interpolate->disable();
  }
 
  _refine1->enable();
  _refine1->addUniform("f");
  _refine1->addUniform("u");
  _refine1->addUniform("dc");
  _refine1->addUniform("sw");
  _refine1->addUniform("sh");
  _refine1->addUniform("c");
  _refine1->addUniform("e");
  _refine1->addUniform("x");
  _refine1->addUniform("t");
  _refine1->disable();

  _refine2->enable();
  _refine2->addUniform("f");
  _refine2->addUniform("u");
  _refine2->addUniform("dc");
  _refine2->addUniform("sw");
  _refine2->addUniform("sh");
  _refine2->addUniform("c");
  _refine2->addUniform("e");
  _refine2->addUniform("x");
  _refine2->addUniform("t");
  _refine2->disable();
}

void PoissonLevelRGB::initShaders(PoissonLevelRGB *prev,PoissonLevelRGB *next) {
  _prev = prev;
  _next = next;
  
  sendUniforms();
}

void PoissonLevelRGB::reloadShaders() {
  _restrict->reload();
  _interpolate->reload();
  _refine1->reload();
  _refine2->reload();
  
  sendUniforms();
}

void PoissonLevelRGB::sendUniforms() {
  
  // restriction only if this is not the first level
  if(_prev!=NULL) {
    _restrict->enable();
    _restrict->setUniform1f("sw2",_sw*0.5f);
    _restrict->setUniform1f("sh2",_sh*0.5f);
    _restrict->setUniform1f("sw4",_sw*0.25f);
    _restrict->setUniform1f("sh4",_sh*0.25f);
    _restrict->setUniformTexture("f" ,GL_TEXTURE_2D,_prev->fTex()->id());
    _restrict->setUniformTexture("dc",GL_TEXTURE_2D,_prev->cTex()->id());
    _restrict->disable();
  }
  
  // interpolation only if this is not the last level
  if(_next!=NULL) {
    _interpolate->enable();
    _interpolate->setUniform1f("sw2",_sw*0.5f);
    _interpolate->setUniform1f("sh2",_sh*0.5f);
    _interpolate->setUniformTexture("u",GL_TEXTURE_2D,_next->uTex()->id());

    if(_prev==NULL) 
      _interpolate->setUniformTexture("u0",GL_TEXTURE_2D,_uTex->id());
    
    _interpolate->disable();
  }
  
  // relaxation 1 & 2
  _refine1->enable();
  _refine1->setUniform1f("sw",_sw);
  _refine1->setUniform1f("sh",_sh);
  _refine1->setUniform1f("c",_c);
  _refine1->setUniform1f("e",_e);
  _refine1->setUniform1f("x",_x0);
  _refine1->setUniform1f("t",_t0);
  _refine1->setUniformTexture("f" ,GL_TEXTURE_2D,_fTex->id());
  _refine1->setUniformTexture("u" ,GL_TEXTURE_2D,_uTex->id());
  _refine1->setUniformTexture("dc",GL_TEXTURE_2D,_cTex->id());
  _refine1->disable();

  _refine2->enable();
  _refine2->setUniform1f("sw",_sw);
  _refine2->setUniform1f("sh",_sh);
  _refine2->setUniform1f("c",_c);
  _refine2->setUniform1f("e",_e);
  _refine2->setUniform1f("x",_x1);
  _refine2->setUniform1f("t",_t1);
  _refine2->setUniformTexture("f" ,GL_TEXTURE_2D,_fTex->id());
  _refine2->setUniformTexture("u" ,GL_TEXTURE_2D,_tTex->id());
  _refine2->setUniformTexture("dc",GL_TEXTURE_2D,_cTex->id());
  _refine2->disable();
}

PoissonLevelRGB::~PoissonLevelRGB() {
  delete _fTex;
  delete _cTex;
  delete _tTex;
  delete _fbo;
  delete _restrict;
  delete _interpolate;
  delete _refine1;
  delete _refine2;
  // if I did not create this texture 
  if(!_no) delete _uTex;
}
