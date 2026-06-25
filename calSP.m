% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

function [distance, velocity, acceleration, jerk, Ratio_pause, total_duration, smoothness, Min_dlocs, Max_dlocs] = calSP(X, Y, T)
% CALSP Computes kinematic and temporal features for spiral handwriting data.
% Purpose: Analyzes X and Y coordinates and timestamps of spiral handwriting data to
%          calculate kinematic features (distance, velocity, acceleration, jerk),
%          pause ratio, total duration, smoothness, and displacement characteristics.
% Inputs:
%   X - Vector of X-coordinates of spiral handwriting data
%   Y - Vector of Y-coordinates of spiral handwriting data
%   T - Vector of timestamps corresponding to handwriting data (ms)
% Outputs:
%   distance - Vector of Euclidean distances between consecutive points
%   velocity - Vector of velocities (distance per ms)
%   acceleration - Vector of accelerations (velocity change per ms)
%   jerk - Vector of jerks (acceleration change per ms)
%   Ratio_pause - Ratio of pause instances (zero-distance points) to total points
%   total_duration - Total duration of handwriting (ms)
%   smoothness - Sum of absolute angular differences (radians)
%   Min_dlocs - Minimum displacement between peak locations
%   Max_dlocs - Maximum displacement between peak locations
% Date: April 2025

% Compute differences in coordinates and time
dx = diff(X); % Differences in X-coordinates
dy = diff(Y); % Differences in Y-coordinates
dt = diff(T); % Time differences

% Calculate kinematic features
distance = sqrt(dx.^2 + dy.^2); % Euclidean distance between consecutive points
velocity = distance ./ dt; % Velocity (distance per ms)
dv = diff(velocity); % Velocity differences
acceleration = dv ./ dt(1:end-1); % Acceleration (velocity change per ms)
da = diff(acceleration); % Acceleration differences
jerk = da ./ dt(1:end-2); % Jerk (acceleration change per ms)

% Calculate pause ratio (proportion of zero-distance points)
N_zeros = nnz(~distance); % Number of zero-distance points
Ratio_pause = N_zeros / length(distance); % Ratio of pauses to total points

% Calculate total duration
total_duration = T(end) - T(1); % Difference between last and first timestamp (ms)

% Calculate smoothness based on angular changes
angles = atan2(dy, dx); % Angles of movement direction (radians)
angularDiff = abs(diff(angles)); % Absolute angular differences
smoothness = sum(angularDiff); % Total angular change as smoothness measure

% Detect significant peaks in distance for displacement analysis
meanSignal = mean(distance); % Mean distance
[pks, locs] = findpeaks(distance, 'MinPeakHeight', 2*meanSignal, 'MinPeakDistance', 1); % Find peaks
locs(end+1) = length(distance); % Append last point as a pseudo-peak
dlocs = abs(diff(locs)); % Differences between peak locations

% Calculate minimum and maximum displacements
Min_dlocs = min(dlocs, [], 'omitnan'); % Minimum displacement
Max_dlocs = max(dlocs, [], 'omitnan'); % Maximum displacement

end