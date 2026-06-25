% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

function [total_duration_wl, MeanWidthl, MeanHeightl, MeanWidthle, MeanHeightle, dflWl, dflHl, dflWle, dflHle] = calLetters(wlX, wlY, wlT)
% CALLETTERS Computes temporal and spatial features for handwriting data of letters.
% Purpose: Analyzes X and Y coordinates and timestamps of handwriting data to calculate
%          total duration, mean width and height of letter segments, and differences
%          in width and height between specific segments.
% Inputs:
%   wlX - Vector of X-coordinates of handwriting data
%   wlY - Vector of Y-coordinates of handwriting data
%   wlT - Vector of timestamps corresponding to handwriting data
% Outputs:
%   total_duration_wl - Total duration of handwriting (ms)
%   MeanWidthl - Mean width of the first five letter segments
%   MeanHeightl - Mean height of the first five letter segments
%   MeanWidthle - Mean width of the last five letter segments
%   MeanHeightle - Mean height of the last five letter segments
%   dflWl - Absolute difference in width between the first and fifth segments
%   dflHl - Absolute difference in height between the first and fifth segments
%   dflWle - Absolute difference in width between the sixth and tenth segments
%   dflHle - Absolute difference in height between the sixth and tenth segments
% Date: April 2025

% Calculate total duration of handwriting
total_duration_wl = wlT(end) - wlT(1); % Difference between last and first timestamp (ms)

% Identify indices of NaN values in X-coordinates to segment data
index = find(isnan(wlX)); % Logical array: 1 for NaN, 0 for non-NaN

% Initialize start and end points for the first segment
stp(1) = 1; % Start of first segment
edp(1) = index(1) - 1; % End of first segment (index before first NaN)

% Determine start and end points for remaining segments
for i = 2:length(index)
    stp(i) = index(i-1) + 1; % Start after previous NaN
    edp(i) = index(i) - 1; % End before current NaN
end

% Extract X and Y coordinates for each segment and compute width and height
for j = 1:length(index)
    sX{j} = wlX(stp(j):edp(j)); % X-coordinates for segment j
    sY{j} = wlY(stp(j):edp(j)); % Y-coordinates for segment j
    width{j} = max(sX{1,j}) - min(sX{1,j}); % Width: max X - min X
    height{j} = max(sY{1,j}) - min(sY{1,j}); % Height: max Y - min Y
end

% Convert cell arrays to numeric arrays
width = cell2mat(width); % Array of segment widths
height = cell2mat(height); % Array of segment heights

% Calculate mean width and height for specific segments
MeanWidthl = mean(width(1:5)); % Mean width of first five segments
MeanHeightl = mean(height(1:5)); % Mean height of first five segments
MeanWidthle = mean(width(6:10)); % Mean width of last five segments
MeanHeightle = mean(height(6:10)); % Mean height of last five segments

% Calculate absolute differences in width and height between specific segments
dflWl = abs(width(1) - width(5)); % Width difference between first and fifth segments
dflWle = abs(width(6) - width(10)); % Width difference between sixth and tenth segments
dflHl = abs(height(1) - height(5)); % Height difference between first and fifth segments
dflHle = abs(height(6) - height(10)); % Height difference between sixth and tenth segments

end