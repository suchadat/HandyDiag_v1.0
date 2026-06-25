% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

function [STD, VAR, MEAN, MED, maxime, PRC_10, PRC_90, PRC_range, Area] = calStats(data)
% CALSTATS Computes basic statistical features from input data.
% Purpose: Extracts standard descriptive statistics from a vector of numerical data,
%          useful for analyzing distributions in handwriting signals.
% Inputs:
%   data - Vector of numerical values (e.g., velocity, acceleration, pressure)
% Outputs:
%   STD - Standard deviation of the data
%   VAR - Variance of the data
%   MEAN - Mean (average) value of the data
%   MED - Median value of the data
%   maxime - Maximum value in the data
%   PRC_10 - 10th percentile of the data
%   PRC_90 - 90th percentile of the data
%   PRC_range - Difference between 90th and 10th percentiles (inter-percentile range)
%   Area - Approximate area under the curve using trapezoidal numerical integration
% Date: April 2025

% Calculate standard deviation
STD = std(data); % Standard deviation of the data

% Calculate variance
VAR = var(data); % Variance of the data

% Calculate mean
MEAN = mean(data); % Mean value of the data

% Calculate median
MED = median(data); % Median value of the data

% Calculate percentiles
PRC_10 = prctile(data, 10, 'all'); % 10th percentile of the data
PRC_90 = prctile(data, 90, 'all'); % 90th percentile of the data
PRC_range = PRC_90 - PRC_10; % Inter-percentile range (90th - 10th)

% Calculate area under the curve
Area = trapz(data); % Trapezoidal numerical integration for area

% Calculate maximum
maxime = max(data); % Maximum value in the data

end