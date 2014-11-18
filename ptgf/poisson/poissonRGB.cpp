#include "poissonRGB.h" 
#include "utils.h"
#include "poissonRGBWidget.h" 

using namespace std;

PoissonRGB::PoissonRGB() 
  : Filter(new PoissonRGBWidget(this)),
    _p(),
    _initialized(false) {

}

void PoissonRGB::connected() {
  _initialized = false;
}

void PoissonRGB::apply() {
  PoissonRGBWidget *w = (PoissonRGBWidget *)_widget;
  bool tm = w->tonemap();

  if(!_initialized) {

    // we need to reinitialize 
    _p.initialize(_inputs[0]->w,
		  _inputs[0]->h,
		  _inputs[0]->tex,
		  _inputs[1]->tex,
		  _inputs[2]->tex,
		  _outputs[0]->tex);

    _p.update(tm,true);
    _initialized = true;
  }    
    
  
  for(int i=0;i<w->getNbCycles();++i) {
    _p.update(tm,false);
  }  
}

void PoissonRGB::disconnected() {
  _initialized = false;
}

void PoissonRGB::reloadShaders() {
  _p.reloadShaders();
}

std::ostream &PoissonRGB::save(std::ostream &stream) {
  PoissonRGBWidget *w = (PoissonRGBWidget *)_widget;

  stream << w->getNbCycles() << endl;
  stream << w->tonemap() << endl;

  return stream;
}

std::istream &PoissonRGB::load(std::istream &stream) {
  PoissonRGBWidget *w = (PoissonRGBWidget *)_widget;
  int v;
  bool t;
  
  stream >> v; w->setNbCycles(v);
  stream >> t; w->setTonemap(t);

  return stream;
}

Filter *createFilter() {
  return new PoissonRGB();
}

string filterName() {
  return "Diffusion/PoissonRGB";
}

string filterDescription() {
  return "RGB Poisson reconstruction with Gx, Gy and Dirichlet boundary constraints";
}
