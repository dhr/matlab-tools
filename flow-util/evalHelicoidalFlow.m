function ts = evalHelicoidalFlow(xs, ys, t, kt, kn, sign)
%EVALHELICOIDALFLOW Evaluate a helicoid to obtain a kt/kn flow
%   TS = EVALHELICOIDALFLOW(XS, YS, T, KT, KN, SIGN) creates a helicoidal
%   flow with orientation T (theta) and curvatures KT and KN. XS and YS
%   should be centered at zero (scale is up to you). SIGN controls whether
%   the helicoid is left or right.

if nargin < 6
  sign = 1;
end

rxs = cos(t)*xs + sin(t)*ys;
rys = cos(t)*ys - sin(t)*xs;

vy = kt*rxs + kn*rys;
vx = 1 + sign*kn*rxs - sign*kt*rys;

ts = t + atan2(vy, vx);
