#ifndef POISSON_RGB_H
#define POISSON_RGB_H

#include "filter.h"
#include "poissonSolverRGB.h"

class PoissonRGB : public Filter {
 public:
  PoissonRGB();

  FILTER_API void apply();
  FILTER_API void connected();
  FILTER_API void disconnected();
  FILTER_API void reloadShaders();
  FILTER_API inline unsigned int nbInputs () const {return 3;}
  FILTER_API inline unsigned int nbOutputs() const {return 1;}

  FILTER_API inline QString inputName(int i) const {
    switch(i) {
    case 0: return "Gx (Gx(r),Gx(b),Gx(b))";
    case 1: return "Gy (Gy(r),Gy(b),Gy(b))";
    case 2: return "Dirichlet - if(v>=0) (D(r),D(b),D(b))";
    default: return "";
    }
  }

  // we wont use our FBOs here 
  FILTER_API virtual void initFBO() {}
  FILTER_API virtual void cleanFBO() {}

  FILTER_API std::ostream &save(std::ostream &stream);
  FILTER_API std::istream &load(std::istream &stream);

 private:
  PoissonSolverRGB _p;
  bool             _initialized;
};

extern "C" {
  FILTER_API Filter      *createFilter();
  FILTER_API std::string  filterName();
  FILTER_API std::string  filterDescription();
}

#endif // POISSON_RGB_H
