#ifndef POISSON_SOLVER_RGB_H
#define POISSON_SOLVER_RGB_H

#include "framebufferObject.h"
#include "gpuProgram.h"
#include "texture2D.h"
#include "utils.h"

class PoissonLevelRGB {
 public:
  PoissonLevelRGB(int level,int w,int h,FloatTexture2D *output=NULL);
  ~PoissonLevelRGB();
  
  void initShaders(PoissonLevelRGB *prev,PoissonLevelRGB *next);
  void reloadShaders();

  inline int   level() const {return _level;}
  inline int   w()     const {return _w;    }
  inline int   h()     const {return _h;    }
  inline float sw()    const {return _sw;   }
  inline float sh()    const {return _sh;   }
  inline float m()     const {return _m;    }
  inline float e()     const {return _e;    }
  inline float c()     const {return _c;    }

  inline FramebufferObject *fbo() const {return _fbo;}

  inline FloatTexture2D *fTex() const {return _fTex;}
  inline FloatTexture2D *cTex() const {return _cTex;}
  inline FloatTexture2D *uTex() const {return _uTex;}
  inline FloatTexture2D *tTex() const {return _tTex;}
  
  inline GPUProgram *restrictShader()    const {return _restrict;   } 
  inline GPUProgram *interpolateShader() const {return _interpolate;} 
  inline GPUProgram *refine1Shader()     const {return _refine1;    } 
  inline GPUProgram *refine2Shader()     const {return _refine2;    } 
  
 private:
  PoissonLevelRGB *_prev;
  PoissonLevelRGB *_next;

  int   _level;
  int   _w;
  int   _h;
  float _sw;
  float _sh;
  bool  _no;
  float _m;
  float _e;
  float _c;
  float _x0;
  float _x1;
  float _t0;
  float _t1;

  FramebufferObject *_fbo;

  FloatTexture2D    *_fTex;
  FloatTexture2D    *_cTex;
  FloatTexture2D    *_uTex;
  FloatTexture2D    *_tTex;
  
  GPUProgram        *_restrict;
  GPUProgram        *_interpolate;
  GPUProgram        *_refine1;
  GPUProgram        *_refine2;

  void sendUniforms();
};

class PoissonSolverRGB {
 public:
  PoissonSolverRGB();
  ~PoissonSolverRGB();

  // inputs are two simple gradient textures, and a dirichlet constraint texture 
  void initialize(unsigned int w,
		  unsigned int h,
		  FloatTexture2D *gx,
		  FloatTexture2D *gy,
		  FloatTexture2D *dc,
		  FloatTexture2D *output=NULL);

  // compute/update solution 
  void update(bool tonemap=false,bool init=true);
  
  // clean all
  void finalize();

  // reload (usefull for test) 
  void reloadShaders();

  // output: reconstructed fonction u so that laplace(u) = divergence(_gx,_gy) 
  inline FloatTexture2D *output() const {return _output;}

  // test functions 
  inline unsigned int nbLevels()  const {return _nb;}
  inline FloatTexture2D *getResidual(unsigned int l) const {return _levels[l]->fTex();}
  inline FloatTexture2D *getSolution(unsigned int l) const {return _levels[l]->uTex();}
  inline FloatTexture2D *getTmp(unsigned int l) const {return _levels[l]->tTex();}
  inline FloatTexture2D *getGx() const {return _gx;}
  inline FloatTexture2D *getGy() const {return _gy;}
  inline FloatTexture2D *getDc() const {return _dc;}

 private:
  // input textures 
  FloatTexture2D *_gx;
  FloatTexture2D *_gy;
  FloatTexture2D *_dc;
  
  // output texture 
  FloatTexture2D *_output;

  // average tex and fbo (for tone mapping)
  FloatTexture2D    *_avTex;
  FramebufferObject *_avFbo;

  GPUProgram *_residual;
  GPUProgram *_divergence;
  GPUProgram *_average;
  GPUProgram *_tonemap;

  // initial texture size 
  unsigned int _w;
  unsigned int _h;
  unsigned int _aw;
  unsigned int _ah;
  unsigned int _nb;

  std::vector<PoissonLevelRGB *> _levels;

  // init and delete functions 
  void initShaders();
  void cleanShaders();
  void initLevels(FloatTexture2D *output=NULL);
  void cleanLevels();
  void sendUniforms();

  // common functions 
  int _v[4]; // viewport
  inline void resizeViewport(int w,int h);
  inline void setTexWrap(FloatTexture2D *tex,GLint wrap);
  inline void drawQuad(GLenum buf,GPUProgram *p);
  inline void drawQuads(unsigned int nb,GLenum *bufs,GPUProgram *p);
  
};


inline void PoissonSolverRGB::resizeViewport(int w,int h) {
  glViewport(_v[0],_v[1],w,h);
}

inline void PoissonSolverRGB::drawQuad(GLenum buf,GPUProgram *p) {
  glDrawBuffer(buf);
  p->enable();
  Utils::drawTexturedQuad();
  p->disable();
}

inline void PoissonSolverRGB::drawQuads(unsigned int nb,GLenum *bufs,GPUProgram *p) {
  glDrawBuffers(nb,bufs);
  p->enable();
  Utils::drawTexturedQuad();
  p->disable();
}

inline void PoissonSolverRGB::setTexWrap(FloatTexture2D *tex,GLint wrap) {
  tex->bind();
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,wrap);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,wrap);
}

#endif // POISSON_SOLVER_RGB_H
