function normals = normalsToOpenGLCoords(normals)

normals = permute(normals, [2 3 1]);
normals = normals(:,:,[1 3 2]);
normals(:,:,3) = -normals(:,:,3);
