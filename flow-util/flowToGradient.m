function [gx, gy] = flowToGradient(ts, rs)

[gy, gx] = pol2cart(ts, rs);
gx = -gx;
