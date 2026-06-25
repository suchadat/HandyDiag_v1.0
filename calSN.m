% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

function [dat_filt, filt_se] = calSN(signal, time)
% CALSN Applies signal-to-noise filtering and computes multiscale sample entropy.
% Purpose: Normalizes an input signal, applies a high-pass Butterworth filter based
%          on spectral analysis, and calculates multiscale sample entropy for the
%          filtered signal.
% Inputs:
%   signal - Vector of signal data (single column)
%   time - Vector of corresponding timestamps (ms)
% Outputs:
%   dat_filt - Filtered signal after high-pass filtering
%   filt_se - Multiscale sample entropy of the filtered signal
% Date: April 2025

% Normalize signal to range [-1, 1]
norm_signal = 2 * ((signal(:,1) - min(signal(:,1))) ./ (max(signal(:,1)) - min(signal(:,1)))) - 1;

% Calculate sampling frequency (points per ms)
fs = length(norm_signal) / time(end); % Total points divided by total duration

% Compute power spectral density using Welch's method
[pxxP, fP] = pwelch(norm_signal, [], [], [], fs); % Power spectrum and frequencies

% Convert power spectrum to decibels
db = pow2db(pxxP);

% Find peaks in the power spectrum
[~, locs] = findpeaks(db, fP); % Peak locations (frequencies)

% Select cutoff frequency (third peak, if available)
% fc = locs(3); % Third peak frequency for high-pass filter
if length(locs) >= 3
    fc = locs(3); % ใช้ Peak ที่ 3 ตามเดิมถ้ามี
elseif ~isempty(locs)
    fc = locs(end); % ถ้ามีไม่ถึง 3 ให้ใช้ Peak สุดท้ายที่หาได้
else
    fc = 0.1; % หากไม่พบ Peak เลย ให้ใช้ค่าต่ำๆ เพื่อไม่ให้ Filter ตัดสัญญาณทิ้งหมด
end

% Design a 2nd-order Butterworth high-pass filter
[b, a] = butter(2, fc / (fs / 2), 'high'); % Filter coefficients

% Apply zero-phase high-pass filter to normalized signal
dat_filt = filtfilt(b, a, norm_signal);

% Compute multiscale sample entropy for filtered signal
filt_se = mmse(dat_filt, 2, 1, 0.15, 10); % Parameters: m=2, r=1, tau=0.15, scales=10

end