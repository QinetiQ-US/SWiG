function y = sigmoid(x,c,a)
% function y = sigmoid(x,c,a)
%   x is value
%   c is 50%failure point
%   a is sharpness

y = 1./(1 + exp(-a.*(x-c)));