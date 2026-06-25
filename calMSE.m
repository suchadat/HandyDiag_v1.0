% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

function [STD, VAR, MEAN, MED, Area, SE1, SE2, SE3, SE4, SE5, SE6, SE7, SE8, SE9, SE10] = calMSE(MSE)
% CALMSE Computes statistical and multiscale entropy metrics for input data.
% Purpose: Analyzes a multiscale entropy (MSE) data series to calculate standard
%          statistical metrics (standard deviation, variance, mean, median, area)
%          and extracts entropy values at scales 1 to 10.
% Inputs:
%   MSE - Vector of multiscale entropy values
% Outputs:
%   STD - Standard deviation of MSE data
%   VAR - Variance of MSE data
%   MEAN - Mean of MSE data
%   MED - Median of MSE data
%   Area - Area under the MSE curve (using trapezoidal integration)
%   SE1 - Entropy value at scale 1
%   SE2 - Entropy value at scale 2
%   SE3 - Entropy value at scale 3
%   SE4 - Entropy value at scale 4
%   SE5 - Entropy value at scale 5
%   SE6 - Entropy value at scale 6
%   SE7 - Entropy value at scale 7
%   SE8 - Entropy value at scale 8
%   SE9 - Entropy value at scale 9
%   SE10 - Entropy value at scale 10
% Date: April 2025

% Compute standard statistical metrics for MSE data
STD = std(MSE); % Standard deviation
VAR = var(MSE); % Variance
MEAN = mean(MSE); % Mean
MED = median(MSE); % Median
Area = trapz(MSE); % Area under the curve using trapezoidal integration

% Extract entropy values for scales 1 to 10
for i = 1:10
    eval(sprintf('SE%d = MSE(%d);', i, i)); % Assign MSE value at index i to SEi
end

end