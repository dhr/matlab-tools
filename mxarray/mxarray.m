classdef mxarray < double
  methods
    function obj = mxarray(data)
      obj = obj@double(data);
      
      if ismatrix(obj) && ~isscalar(obj)
        obj = shiftdim(obj, -2);
      elseif ndims(obj) == 3
        obj = shiftdim(obj, -1).';
      end
    end
    
    function c = subsindex(a)
      c = double(a) - 1;
    end
    
    function c = plus(a, b)
      if isscalar(a) || isscalar(b)
        c = mxarray(double(a) + double(b));
      else
        c = mxarray(mdbasicop(double(a), double(b), '+'));
      end
    end
    
    function c = minus(a, b)
      if isscalar(a) || isscalar(b)
        c = mxarray(double(a) - double(b));
      else
        c = mxarray(mdbasicop(double(a), double(b), '-'));
      end
    end
    
    function c = times(a, b)
      if isscalar(a) || isscalar(b)
        c = mxarray(double(a).*double(b));
      else
        c = mxarray(mdbasicop(double(a), double(b), '*'));
      end
    end
    
    function c = rdivide(a, b)
      if isscalar(a) || isscalar(b)
        c = mxarray(double(a)./double(b));
      else
        c = mxarray(mdbasicop(double(a), double(b), '/'));
      end
    end
    
    function c = mtimes(a, b)
      if isscalar(a) || isscalar(b)
        c = mxarray(double(a)*double(b));
      elseif size(a, 1)*size(a, 2) == 1 || size(b, 1)*size(b, 2) == 1
        c = a.*b;
      else
        c = mxarray(mdmtimes(double(a), double(b)));
      end
    end
    
    function c = det(a)
      c = mxarray(mddet(double(a)));
    end
    
    function c = inv(a)
      c = mxarray(mdinv(double(a)));
    end
    
    function [v, d] = eig(a)
      if any(~isfinite(a))
        error('Input to EIG must not contain NaN or Inf.');
      elseif nargout > 1
        [v, d] = mdeig(double(a));
        v = mxarray(v);
        d = mxarray(d);
      else
        v = mxarray(mdeig(double(a)));
      end
    end
    
    function c = ldivide(a, b)
      c = b./a;
    end
    
    function c = mldivide(a, b)
      c = inv(a)*b; %#ok<*MINV>
    end
    
    function c = mrdivide(a, b)
      c = a*inv(b);
    end
    
    function c = transpose(a)
      c = mxarray(permute(a, [2 1 3:ndims(a)]));
    end
    
    function c = ctranspose(a)
      c = mxarray(conj(a.'));
    end
  end
end
