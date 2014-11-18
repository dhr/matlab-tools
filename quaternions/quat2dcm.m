function dcm = quat2dcm(q)
%QUAT2DCM Convert quaternions into direction cosine matrices.
%   DCM = QUAT2DCM(Q) calculates the direction cosine matrices, DCM, for
%   given quaternions, Q (should be n x 4).

qn = quatnormalize(q);

dcm = zeros(3,3,size(qn,1));

dcm(1,1,:) = qn(:,1).^2 + qn(:,2).^2 - qn(:,3).^2 - qn(:,4).^2;
dcm(1,2,:) = 2.*(qn(:,2).*qn(:,3) + qn(:,1).*qn(:,4));
dcm(1,3,:) = 2.*(qn(:,2).*qn(:,4) - qn(:,1).*qn(:,3));
dcm(2,1,:) = 2.*(qn(:,2).*qn(:,3) - qn(:,1).*qn(:,4));
dcm(2,2,:) = qn(:,1).^2 - qn(:,2).^2 + qn(:,3).^2 - qn(:,4).^2;
dcm(2,3,:) = 2.*(qn(:,3).*qn(:,4) + qn(:,1).*qn(:,2));
dcm(3,1,:) = 2.*(qn(:,2).*qn(:,4) + qn(:,1).*qn(:,3));
dcm(3,2,:) = 2.*(qn(:,3).*qn(:,4) - qn(:,1).*qn(:,2));
dcm(3,3,:) = qn(:,1).^2 - qn(:,2).^2 - qn(:,3).^2 + qn(:,4).^2;
