clear, clc, close all

%% THRESHOLD
Gthresh = 10;
CellSize = 4;

%% Load in the image
[IMGfiles, IMGpath] = uigetfile({'*.*','All Files'},'Choose an Image File', 'MultiSelect', 'on');

if ~iscell(IMGfiles) % check if a file was selected
    if IMGfiles == 0
        disp('No File Was Selected')
        return
    end
    IMGfilecell = cell(1,1); IMGfilecell{1} = IMGfiles;
    IMGfiles = IMGfilecell;
end     


for ii = 1:length(IMGfiles)
    
    IMG = imread(strcat(IMGpath, IMGfiles{ii})); % Read in the image data
    Gimg = IMG(:,:,2); % Extract green channel
    ExScaleBar = IMG(:,:,1) > 0; % Figure out which pixels are not part of scale bar based on red channel
    Gimg(ExScaleBar) = 0;

    % Gaussian filter to smooth out noise
    gaussfilt = fspecial('gaussian', [5 5], 1.2);
    Filtered_Gimg = imfilter(Gimg, gaussfilt);

    % Apply global threshold and display
    Gmask = Filtered_Gimg >= Gthresh;
    G_maskedimg = imoverlay(Filtered_Gimg, Gmask, [1,0,0]);
    figure(1), subplot(2,2,1), imshow(Filtered_Gimg), title('Original, Filtered ')
    figure(1), subplot(2,2,2), imshow(G_maskedimg), title('Global Threshold')

    % Use active contouring algorithm based on edge detection to refine global
    % threshold segmentation
    Segmented = activecontour(Filtered_Gimg,Gmask, 100);
    segmentedimg = imoverlay(Filtered_Gimg, Segmented, [1 0 1]);
    figure(1), subplot(2,2,3), imshow(segmentedimg), title('Contoured')

    % Determine which segmented pixels are connected
    ConnectedSegments = bwconncomp(Segmented,4);
    count = 0;
    for jj = 1:length(ConnectedSegments.PixelIdxList)

        if length(ConnectedSegments.PixelIdxList{jj}) > CellSize
            count = count + 1;
        else
            Segmented(ConnectedSegments.PixelIdxList{jj}) = 0;
        end

    end
    
    segmentedimg2 = imoverlay(Filtered_Gimg, Segmented, [0 0 1]);
    figure(1), subplot(2,2,4), imshow(segmentedimg2), title('Contoured - Small Areas')
    
    CellCount(ii) = count;
    
    % % Exclude any connected segments that touch the edges
    % kk = 0;
    % for ii = [1 size(Bimg,1)]
    %     for jj = 1:size(Bimg,2)
    %         if Bmask(ii,jj) == 1 && ConnectedSegments(ii,jj) ~= 0
    %             kk = kk+1;
    %             ExcludeList(kk) = ConnectedSegments(ii,jj);
    %         end
    %     end
    % end
    % 
    % for jj = [1 size(Bimg,2)]
    %     for ii = 1:size(Bimg,1)
    %         if Bmask(ii,jj) == 1 && ConnectedSegments(ii,jj) ~= 0
    %             kk = kk+1;
    %             ExcludeList(kk) = ConnectedSegments(ii,jj);
    %         end
    %     end
    % end
    
%     fprintf(['\nNumber of cells = ', num2str(CellCount),'\n\n'])

pause

end

TotalCount = sum(CellCount);