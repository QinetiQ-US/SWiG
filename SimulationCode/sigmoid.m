%> @brief sigmoid function used for almost-threshold failure behavior
%> @param [in] x input value for sigmode
%> @param [in] c the 50% failure point
%> @param [in] a sharpness coefficient
%> @returns sigmoid value between 0 and 1
function y = sigmoid(x,c,a)
% function y = sigmoid(x,c,a)
%   x is value
%   c is 50%failure point
%   a is sharpness

y = 1./(1 + exp(-a.*(x-c)));