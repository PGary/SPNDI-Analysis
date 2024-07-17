clear
clc

expname = 'LCO'
pathname= ['.\data\' expname '\']

files = dir([pathname 'rock_*.tif']);
scan_list = [];
for i=1:3:numel(files)
    scan_list=[scan_list str2num(files(i).name(6:11))];
end

num_scan = size(scan_list,2);
%scan_list = scan_list();

scan_list = scan_list(1:2:end) %memory limitation, just process part of the data;


theta_list = linspace(-39.7,-37.7,21); %modify
num_scan = size(scan_list,2);


size_xrf = imfinfo([pathname 'rock_' num2str(scan_list(1)) '_xrf.tif']);  % modify
m = size_xrf.Height;
n = size_xrf.Width;

% load data
Img_xrf = zeros(num_scan,m,n);
Img_roi = zeros(num_scan,m,n);
for i = 1 : num_scan
    disp(i);
    Img_xrf(i,:,:) = double(imread(strcat(pathname, 'rock_',num2str(scan_list(i)),'_xrf.tif')));
    Img_roi(i,:,:) = double(imread(strcat(pathname, 'rock_',num2str(scan_list(i)),'_roi.tif')));
end

figure,imshow(squeeze(Img_roi(10,:,:)),[])
title('roi')
figure,imshow(squeeze(Img_xrf(10,:,:)),[])
title('xrf')

% alignment
% offset_x_int = zeros(num_scan,1);
% offset_y_int = zeros(num_scan,1);
% offset_x_tmp = zeros(num_scan,1);
% offset_y_tmp = zeros(num_scan,1);
align_xrf = zeros(size(Img_xrf));
align_xrf(1,:,:) = Img_xrf(1,:,:);
align_roi = zeros(size(Img_roi));
align_roi(1,:,:) = Img_roi(1,:,:);
for s = 1 : num_scan
    disp(s);
    [optimizer, metric] = imregconfig('multimodal');
    if s==1
        ref = log(squeeze(Img_xrf(s,:,:)));
    else
        ref = log(squeeze(Img_xrf(s-1,:,:)));
    end
    ref(~isfinite(ref)) = 0;
    moving = log(squeeze(Img_xrf(s,:,:)));
    moving(~isfinite(moving)) = 0;

    [MOVINGREG] = registerImages(moving,ref);
    align_xrf(s,:,:) = MOVINGREG.RegisteredImage;
    align_roi(s,:,:) = imwarp(squeeze(Img_roi(s,:,:)),MOVINGREG.Transformation,'OutputView',imref2d(size(squeeze(Img_roi(1,:,:)))));
    %
    %     tform = imregtform(moving, ref, 'translation', optimizer, metric);
    %     align_xrf(s,:,:) = imwarp(squeeze(Img_xrf(s,:,:)),tform,'OutputView',imref2d(size(squeeze(Img_xrf(1,:,:)))));
    %     align_roi(s,:,:) = imwarp(squeeze(Img_roi(s,:,:)),tform,'OutputView',imref2d(size(squeeze(Img_roi(1,:,:)))));
    %     offset_x_int(s) = floor(tform.T(3,1));
    %     offset_y_int(s) = floor(tform.T(3,2));
    %     offset_x_tmp(s) = tform.T(3,1);
    %     offset_y_tmp(s) = tform.T(3,2);
end
roi_aligned_sum = squeeze(sum(log(align_roi+0.01),1));
% figure,imshow(squeeze(roi_aligned_sum),[])

Img_xrf = permute(align_xrf,[2 3 1]);
Img_roi = permute(align_roi, [2 3 1]);


%%
mask = imread([pathname expname '_diff_mask.tif']);
figure,imshow(mask,[])
title('mask')
%%

info = imfinfo([pathname '\rock_' num2str(scan_list(1)) '_diff_data.tif']); % modify
slice_diff = size(info,1);
width_diff = info.Width;
height_diff = info.Height;



%%
data_slice = zeros(height_diff,width_diff,slice_diff,num_scan);

for ii = 1:num_scan
    %     ii = 1;
    ii
    parfor iii = 1:slice_diff
        disp(ii);
        disp(iii);
        data_slice(:,:,iii,ii) = double(imread(strcat(pathname, '\rock_',num2str(scan_list(ii)),'_diff_data.tif'),iii));
    end

end

%save allPixel_heat -v7.3;

%%
% figure;
for a = 1:m
    for b = 1:n
        if mask(a,b) == 1 && ~isfile([pathname 'mat/pixel_' num2str(a,'%03d') '_' num2str(b,'%03d') '.mat'])
            disp(['pixel ' num2str(a) '_' num2str(b) '']);
            data_frame = squeeze(data_slice(:,(a-1)*n+b,:,:));
            if ~exist([pathname 'mat/'], 'dir')
                mkdir([pathname 'mat/'])
            end
            save([pathname 'mat/pixel_' num2str(a,'%03d') '_' num2str(b,'%03d') '.mat'], 'data_frame');
            %aux_stackwrite(uint16(data_frame),['heat_movies/pixel_' num2str(a,'%03d') '_' num2str(b,'%03d') '.tif']);

            data_frame(data_frame>0.05)=0.05;

            selectpixel = [];
            w = 1;
            for i=1:height_diff 
                for j=1:slice_diff
                    for k=1:num_scan
                        if data_frame(i,j,k)>0.0001
                            selectpixel(w,:) = [i j k*10];
                            %values(w,:) = data_frame(i,j,k);
                            w=w+1;
                        end
                    end
                end
            end
            ptCloudB = pcdenoise(pointCloud(selectpixel),'NumNeighbors',100,'Threshold',0.8);
            [pcd_de] = PCD_Filtering_LPAICI_mex(single(ptCloudB.Location),single(5),single(2));
            [pcd_de] = PCD_Filtering_LPAICI_mex(single(pcd_de),single(5),single(0.2));
            ptCloudB = pcdenoise(pointCloud(pcd_de),'NumNeighbors',100,'Threshold',0.8);
            %figure; pcshow(ptCloudB);

            if ~exist([pathname 'ply/'], 'dir')
                mkdir([pathname 'ply/'])
            end
            write_ply_only_pos(ptCloudB.Location, [pathname 'ply/pixel_' num2str(a,'%03d') '_' num2str(b,'%03d') '.ply']);

        end
    end
end


return
