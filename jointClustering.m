clear;clc;
% pathname='D:\CT Data\Pan Hongyi\CDI-LCO\NanoDiffractionAnalysis\';

% samples = ["bare_LCO","bare_LCO_30C","bare_LCO_60C","bare_LCO_100C","TMA_pristine_chem","TMA_LCO_30C","TMA_LCO_60C","TMA_LCO_100C"];
% AllFeature = [];

samples = ["bare_LCO"];
AllFeature = [];
for jj=1:numel(samples)


    load(strcat("features_",samples(jj),".mat"));

    size(Feature,2)

    AllFeature = [AllFeature Feature];


end


%%

rng(0); % For reproducibility

[allidx, allcentriod] =kmeans_opt(AllFeature',80);

% allidx =kmeans(AllFeature',2);


%%
clear AllMap;
CorMap = zeros(max(xind),max(yind));
Centeriod = []
figure;

kt=1;
for jjj=1:numel(samples)
  

    load(strcat("features_",samples(jjj),".mat"));

    clear CorMap;
    for i=1:size(Feature,2)
        i
        CorMap(xind(i),yind(i)) = allidx(kt);
        
        kt=kt+1;
    end
    Centeriod = allcentriod;
    AllMap{jjj}=CorMap;

end
% 
% for i=1:numel(samples)
%     subplot(2,4,i);
%     imshow(AllMap{i},[]);colormap('jet');title(samples(i),'Interpreter','none')
% end