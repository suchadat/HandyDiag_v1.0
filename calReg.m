% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

function [coef_y, coef_d, coef_a] = calReg(THLImage, THLBg)
% CALREG Computes regression coefficients for handwriting image data.
% Purpose: Analyzes a handwriting image and its background to extract regression
%          coefficients for the y-coordinate of letter centroids, distance between
%          consecutive centroids, and area of letter bounding boxes.
% Inputs:
%   THLImage - RGB image of handwritten text (sentence)
%   THLBg - RGB background image
% Outputs:
%   coef_y - Slope of linear regression for y-coordinates of letter centroids
%   coef_d - Slope of linear regression for distances between consecutive centroids
%   coef_a - Slope of linear regression for areas of letter bounding boxes
% Date: April 2025

% Define target region for cropping (in pixels: [x, y, width, height])
targetSize = [7.5, 32.5, 986, 595];

% Crop input image and background to the specified region
img = imcrop(THLImage, targetSize); % Handwriting image
bg = imcrop(THLBg, targetSize); % Background image

% Convert images to grayscale
grayImage = rgb2gray(img); % Convert handwriting image to grayscale
grayBG = rgb2gray(bg); % Convert background image to grayscale

% Compute initial difference image (not used after binary processing)
BN = grayBG - grayImage;

% Binarize grayscale images
binaryImage = imbinarize(grayImage); % Binarize handwriting image
binaryBG = imbinarize(grayBG); % Binarize background image

% Compute binary difference image and binarize result
binaryImage2 = binaryBG - binaryImage;
binaryImage2 = imbinarize(binaryImage2);
BN = binaryImage2; % Update BN with binary difference

% Refine binary image if mean intensity is non-zero
if mean(binaryImage2, 'all') ~= 0
    binaryImage3 = ~binaryImage; % Invert binarized handwriting image
    binaryImage4 = binaryImage3 - binaryImage2; % Subtract difference image
    binaryImage = binaryImage2 + binaryImage4; % Combine images
    binaryImage5 = imbinarize(binaryImage); % Binarize combined image
    BN = binaryImage5; % Update BN with refined binary image
end

% Filter small areas (1 to 100 pixels) to create a mask
mask = bwareafilt(BN, [1, 100]);
BN = BN - mask; % Remove small areas from binary image

% Label connected components in the binary image
labeledImage = bwlabel(BN);

% Dilate labeled image to connect nearby components
se = strel('rectangle', [1, 200]); % Structuring element for dilation
ImdiPicture2 = imdilate(labeledImage, se);
[Ldi, Nedi] = bwlabel(ImdiPicture2); % Label dilated components

% Initialize table to store properties of detected letters
allPics = table();

% Process each dilated component to extract letter properties
for ndi = 1:Nedi
    [rdi, cdi] = find(Ldi == ndi); % Find row and column indices for component ndi
    % Extract region of interest from labeled image
    pictureArea = labeledImage(min(rdi):max(rdi), min(cdi):max(cdi));
    pictureArea_mask = logical(pictureArea); % Convert to logical mask
    pictureArea_mask = bwareaopen(pictureArea_mask, 100); % Remove areas < 100 pixels
    [L, Ne] = bwlabel(pictureArea_mask); % Label connected components in mask
    % Extract bounding box and centroid properties
    pic = regionprops('table', L, 'BoundingBox', 'Centroid');
    allPics = [allPics; pic]; % Append properties to table
end

% Extract y-coordinates of centroids and compute linear regression
y = allPics.Centroid(:, 2); % Y-coordinates of letter centroids
x = (1:size(allPics,1))'; % Indices for regression
degree = 1; % Linear regression
coefficients_y = polyfit(x, y, degree);
coef_y = coefficients_y(1); % Slope of y-coordinate regression

% Compute distances between consecutive centroids and perform linear regression
Dx = diff(allPics.Centroid(:, 1)); % Differences in x-coordinates
Dy = diff(allPics.Centroid(:, 2)); % Differences in y-coordinates
distance = sqrt(Dx.^2 + Dy.^2); % Euclidean distances
X = (1:(size(allPics,1)-1))'; % Indices for regression
coefficients_d = polyfit(X, distance, degree);
coef_d = coefficients_d(1); % Slope of distance regression

% Compute areas of bounding boxes and perform linear regression
width = allPics.BoundingBox(:, 3); % Widths of bounding boxes
height = allPics.BoundingBox(:, 4); % Heights of bounding boxes
area = width .* height; % Areas of bounding boxes
A = (1:size(allPics,1))'; % Indices for regression
coefficients_a = polyfit(A, area, degree);
coef_a = coefficients_a(1); % Slope of area regression

end