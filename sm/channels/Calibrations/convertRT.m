function [ T ] = convertRT( R , calibration)
%CONVERTRT Summary of this function goes here
%   Detailed explanation goes here

thispath = mfilename('fullpath');
[path,~,~] = fileparts(thispath);
C = load(sprintf('%s/%s.txt', path, calibration), '-ascii');

T = interp1(C(:,1), C(:,2), R, 'pchip') / 1000;

end

