function [short, bina] = calcuShort(goal, fact)
% DESCRIPTION:
%   This is a subfunction of mlad.m. The function is calculate the shortage
%   between two numbers and output a binary switch to represent short or
%   no short

% AUTHOR:
%   Zhiyi Tang
%   tangzhi1@hit.edu.cn
%   Center of Structural Monitoring and Control
% 
% DATE CREATED:
%   09/04/2017

short = goal - fact;
if short < 0
    bina = 1;
    short = 0;
elseif short >= 0
    bina = 2;
end
end