function c = compressionVectorFromAngles(az, el, amt, transforms)
%COMPRESSIONVECTORFROMANGLES Create a compression vector.
%   C = COMPRESSIONVECTORFROMANGLES(AZ, EL, AMT, TFORMS) creates a
%   compression vector C given a direction (AZ and EL), an amount AMT, and
%   a string TFORMS containing transforms such as those found in a Radiance
%   scene description.  These transforms are applied to the vector after it
%   is created from AZ and EL, so that compression applied in bubbles.cal
%   can be easily converted for use with FORESHORTENINGFROMNORMALS.
%
%   See also FORESHORTENINGFROMNORMALS.

az = az*pi/180;
el = el*pi/180;
c = amt*[-sin(az)*cos(el) cos(az)*cos(el) sin(el)]';

commands = textscan(transforms, '%s', 'MultipleDelimsAsOne', true);
index = 1;
while index <= length(commands{1})
  switch commands{1}{index}
    case '-rx'
      index = index + 1;
      transform = makehgtform('xrotate', str2double(commands{1}{index})*pi/180);
    case '-ry'
      index = index + 1;
      transform = makehgtform('yrotate', str2double(commands{1}{index})*pi/180);
    case '-rz'
      index = index + 1;
      transform = makehgtform('zrotate', str2double(commands{1}{index})*pi/180);
  end
  
  c = transform(1:3, 1:3)*c;
  index = index + 1;
end