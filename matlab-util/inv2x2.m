function [im11, im21, im12, im22] = inv2x2(m11, m21, m12, m22)

d = m11.*m22 - m12.*m21;
im11 = m22./d;
im21 = -m21./d;
im12 = -m12./d;
im22 = m11./d;
