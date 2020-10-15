clear, clc, close all

%% Thresholds
GlobalThresh = 35;
EdgeThresh = 0.02;
SizeThresh = .01;


%% Load in the image
[IMGfile, IMGpath] = uigetfile({'*.*','All Files'},'Choose an Image File', 'MultiSelect', 'off');

% Check if a file was selected
if IMGfile == 0
    disp('No File Was Selected')
    return
end    

IMG = imread(strcat(IMGpath, IMGfile)); % Read in the image data
Gimg = IMG(:,:,1) == 255 | IMG(:,:,3) == 255; % Extract the green channel only
%% Process Image

% Draw Cell ROI
figure(1)
imshow(IMG) % Display the image in Figure 1
cellROI = roipoly; % Draw polygon around the cell of interest


figure(1), subplot(1,2,1), imshow(Gimg), title('Original')

% Apply light Gaussian smoothing to reduce noise effects
gaussfilt = fspecial('gaussian', [3 3], 1);
Filtered_Gimg = imfilter(Gimg, gaussfilt);

% Using global threshold
Gmask = Gimg >= GlobalThresh;
Thresh_img = imoverlay(Filtered_Gimg, Gmask, [1,0,0]); % overlay mask onto the image

%% Using Sobel Edge Detection
EdgeMask = edge(Filtered_Gimg, 'sobel', EdgeThresh, 'nothinning');
Edged_img = imoverlay(Thresh_img, EdgeMask, [0,0,1]);
figure(1), subplot(1,2,2), imshow(Edged_img), title('Edge (Blue) + Global (Red) Threshold Image')

EdgeGlobalMask = Edged_img(:,:,1) == 255 | Edged_img(:,:,3) == 255;
EdgeGlobalMask = logical(EdgeGlobalMask.*cellROI);

% Use active contouring algorithm based on edge detection to refine global
    % % threshold segmentation
    Segmented = activecontour(Filtered_Gimg,EdgeGlobalMask, 1);
    segmentedimg = imoverlay(Filtered_Gimg, Segmented, [1 0 1]);
    figure(2), subplot(1,2,1), imshow(segmentedimg), title('Contoured Mask')
    
% Exclude regions that are too small
ConnectedSegments = bwconncomp(Segmented,8);
    count = 0;
    for jj = 1:length(ConnectedSegments.PixelIdxList)

        if length(ConnectedSegments.PixelIdxList{jj}) > SizeThresh
            count = count + 1;
        else
            Segmented(ConnectedSegments.PixelIdxList{jj}) = 0;
        end

    end
    
    segmentedimg2 = imoverlay(Gimg, Segmented, [0 1 0]);
    figure(2), subplot(1,2,2), imshow(segmentedimg2), title('Contoured - Small Areas')

fprintf(['\nVinculin Count = ', num2str(count),'\n\n'])