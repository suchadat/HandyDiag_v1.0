% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

function [total_duration_sl, MeanFrequency, MeanVelo, MaxVelo, MeanAcc, MaxAcc, MeanJerk, MaxJerk, RDP] = calSL(slX, slY, slT)
% CALSL Computes kinematic and temporal features for handwriting spiral data.
% Purpose: Analyzes X and Y coordinates and timestamps of spiral handwriting data to
%          calculate total duration, frequency, velocity, acceleration, jerk, and ratio
%          of deceleration phase.
% Inputs:
%   slX - Vector of X-coordinates of spiral handwriting data
%   slY - Vector of Y-coordinates of spiral handwriting data
%   slT - Vector of timestamps corresponding to handwriting data (ms)
% Outputs:
%   total_duration_sl - Total duration of handwriting (ms)
%   MeanFrequency - Mean frequency of data points (points per ms)
%   MeanVelo - Mean velocity (distance per ms)
%   MaxVelo - Maximum velocity (distance per ms)
%   MeanAcc - Mean acceleration (velocity change per ms)
%   MaxAcc - Maximum acceleration (velocity change per ms)
%   MeanJerk - Mean jerk (acceleration change per ms)
%   MaxJerk - Maximum jerk (acceleration change per ms)
%   RDP - Ratio of deceleration phase (%)
% Date: April 2025

% Calculate total duration of handwriting
total_duration_sl = slT(end) - slT(1); % Difference between last and first timestamp (ms)

% Compute mean frequency (points per ms)
MeanFrequency = length(slY) / total_duration_sl; % Number of points divided by duration

% Initialize arrays for distance, time differences, velocity, acceleration, and jerk
d = zeros(1, length(slX)-1); % Distance between consecutive points
t = zeros(1, length(slX)-1); % Time differences
v = zeros(1, length(slX)-1); % Velocity

% Compute distance, time differences, and velocity
for j = 1:length(slX)-1
    x1 = slX(j); y1 = slY(j); % Current point
    x2 = slX(j+1); y2 = slY(j+1); % Next point
    d(j) = sqrt((x2 - x1)^2 + (y2 - y1)^2); % Euclidean distance
    t(j) = slT(j+1) - slT(j); % Time difference
    v(j) = d(j) / t(j); % Velocity (distance per ms)
end

% Compute mean and maximum velocity
MeanVelo = mean(v, 'omitnan'); % Mean velocity, ignoring NaN values
MaxVelo = max(v, [], 'omitnan'); % Maximum velocity, ignoring NaN values

% Find index of maximum velocity
index = find(v == MaxVelo, 1, 'first'); % First occurrence of maximum velocity

% Compute acceleration
a = zeros(1, length(v)-1); % Acceleration array
for k = 1:length(v)-1
    a(k) = (v(k+1) - v(k)) / (t(k+1) + t(k)); % Acceleration (velocity change per ms)
end

% Compute mean and maximum acceleration
MeanAcc = mean(a, 'omitnan'); % Mean acceleration, ignoring NaN values
MaxAcc = max(a, [], 'omitnan'); % Maximum acceleration, ignoring NaN values

% Compute jerk
j = zeros(1, length(a)-1); % Jerk array
for l = 1:length(a)-1
    % Jerk: acceleration change divided by time interval
    j(l) = (a(l+1) - a(l)) / (t(l) + t(l+1) + t(l+2)); % Use three time intervals
end

% Compute mean and maximum jerk
MeanJerk = mean(j, 'omitnan'); % Mean jerk, ignoring NaN values
MaxJerk = max(j, [], 'omitnan'); % Maximum jerk, ignoring NaN values

% Calculate time to maximum velocity
tvmax = sum(t(1:index)); % Sum of time intervals up to max velocity

% Compute ratio of deceleration phase (percentage)
RDP = ((total_duration_sl - tvmax) / total_duration_sl) * 100; % Deceleration phase ratio

end