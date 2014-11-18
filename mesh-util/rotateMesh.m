function vs = rotateMesh(vs, r)
%ROTATEMESH Rotates a set of vertices given a quaternion.
%   VS = ROTATEMESH(VS, QUAT) rotates the vertices VS given the quaternion,
%   set of rotation angles, or direction cosine matrix R.
%
%   VS should be an m x 3 array of vertices.
%
%   R should be either a quaternion, a set of rotation angles, or a direction
%   cosine matrix.
%
%   S can be the rotation sequence to be used should R be a set of rotation
%   angles (defaults to 'ZYX').
%
%   See also QUAT2DCM, ANGLE2DCM.

if numel(r) == 4
  r = quat2dcm(r);
elseif numel(r) == 3;
%   if nargin < 3
%     s = 'zyx';
%   end
  
  q = angle2quat(r(1), r(2), r(3));
  r = quat2dcm(q);
end

vs = vs*r;
