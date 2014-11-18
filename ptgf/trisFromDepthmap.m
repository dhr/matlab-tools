function tris = trisFromDepthmap(mask)
%TRISFROMDEPTHMAP Triangulates a mask.
%   TRIS = TRISFROMDEPTHMAP(MASK) triangulates the mask MASK as if each
%   "true" element were a vertex.  Leaves ugly jagged edges if viewed too
%   closely, and does not connect disconnected components.

sz = size(mask);
tris = reshape(1:prod(sz), sz);
tris = reshape(tris(1:end - 1,1:end - 1), 1, []);
tris = [tris; tris + 1; tris + sz(1)];
tris = [tris [tris(2,:); tris(1,:) + sz(1) + 1; tris(3,:)]];
trisInsideMask = all([mask(tris(1,:)); mask(tris(2,:)); mask(tris(3,:))]);
tris = tris(:,trisInsideMask);