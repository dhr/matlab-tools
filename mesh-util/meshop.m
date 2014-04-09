function [vs, tris, ns] = meshop(command, vs, tris, ns)

if ~exist('ns', 'var')
  ns = [];
end

[vs, tris, ns] = meshopmex(command, vs', uint32(tris - 1)', ns');
vs = vs';
tris = double(tris + 1)';
ns = ns';
