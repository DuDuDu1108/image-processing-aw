function processColonyMovies(this,InputPath,varargin)
% process a live cell imaging micropatterning experiment. assumes one colony per movie
%%

in_struct = varargin2parameter(varargin);


if ~exist('InputPath','var')
    InputPath = this.maxpro_image_directory;
end


FileExtension = '.tif';
if isfield(in_struct,'FileExtension')
    FileExtension = in_struct.FileExtension;
end


%%
meta = this.meta_data;
DAPIChannel = meta.nuclearChannel;
findColoniesParameters = this.processing_parameters.clparameters;
adjustmentFactor = this.processing_parameters.adjustmentFactor;
Stain = this.stain;
time_info = this.split_folder_time_info;
FolderNum = max(size(time_info,1),1);


col_id = 0;
for plateIdx = 1:size(Stain,2)
    for wellIdx = 1:size(Stain{1,plateIdx},2)
        filePattern = sprintf([InputPath '/**/*Plate%d*Well%02d*' FileExtension],plateIdx,wellIdx);
        fileList = dir(filePattern);
        ImagesPerWell = size(fileList,1)/FolderNum;
        for objIdx = 1:ImagesPerWell
            filePattern = sprintf([InputPath '/**/*Plate%d*Well%02d*Obj%02d*' FileExtension],plateIdx,wellIdx,objIdx);
            fileList_obj = dir(filePattern);
            col_id = col_id+1; nT = 0;
            tic
            for mm = 1:size(fileList_obj,1)
                
                imgfile = fileList_obj(mm).name;
                disp(imgfile)
                rr = bfGetReader(fullfile(InputPath, imgfile));
                img = zeros(rr.getSizeY,rr.getSizeX,rr.getSizeC);
                nC = rr.getSizeC;
                for ci = 1:nC
                    img(:,:,ci) = bfGetPlaneAtZCT(rr,1,ci,1);
                end
                
                
                disp('determine threshold');
                forIlim = img(:,:,DAPIChannel);
                t = thresholdMP(forIlim, adjustmentFactor);
                if isfield(this.processing_parameters,'minThresh') && t < this.processing_parameters.minThresh
                    t = this.processing_parameters.minThresh;
                end
                mask = forIlim > t;
                
                
                disp('find colonies');
                %actually finds the colonies
                [newColonies, cleanmask] = findColonies(mask, [], meta, findColoniesParameters);
                if numel(newColonies) > 1
                    disp('Error: only one colony per image permitted in processColonyMovies')
                end
                
                % store the ID so the colony object knows its position in the
                % array (used to then load the image etc)
                newColonies.setID(col_id);
                newColonies.well = wellIdx;
                newColonies.plate = plateIdx;
                b = newColonies.boundingBox;
                colnucmask = mask(b(3):b(4),b(1):b(2));
                
                for tt = 1:rr.getSizeT
                    if tt  > 1 % get the image of next time point
                        for ci = 1:rr.getSizeC
                            if rr.getSizeZ > 1 && rr.getSizeT == 1
                                img(:,:,ci) = bfGetPlaneAtZCT(rr,tt,ci,1);
                            elseif rr.getSizeT > 1 && rr.getSizeZ == 1
                                img(:,:,ci) = bfGetPlaneAtZCT(rr,1,ci,tt);
                            else
                                disp('Error in processColonyMovies: getSizeZ and getSizeT cannot both be > 1')
                            end
                        end
                    end
                    colonyNow = copyObject(newColonies); % deep copy so we don't overwrite
                    colimg = img(b(3):b(4),b(1):b(2), :);
                    
                    
                    % make radial average
                    colonyNow.makeRadialAvgNoMask(colimg, meta.colMargin, [],[],false)
                    
                    
                    % display the preview
                    if mm == 1 && tt == 1
                        makePreview(img,mask,cleanmask,meta,newColonies,nC);
                        colonies(col_id) = colonyNow;
                    else
                        if tt == 1
                            makePreview(img,mask,cleanmask,meta,newColonies,nC);
                            colonies(col_id).radialProfile(tt+nT) = colonyNow.radialProfile;
                        else
                            colonies(col_id).radialProfile(tt+nT) = colonyNow.radialProfile;
                        end
                    end
                end
                nT = nT+rr.getSizeT;
            end
            toc
        end
    end
end
this.data = colonies;
disp('Done')
end                


function preview = makePreview(img,mask,cleanmask,meta,colonies,nC)

previewSize = 512;
% for preview (thumbnail)
preview = zeros(floor([previewSize previewSize*meta.xSize/meta.ySize 4]));
ymin = 1; xmin = 1;
ymax = meta.ySize; xmax = meta.xSize;

ymaxprev = ceil(size(preview,1)*double(ymax)/meta.ySize);
yminprev = ceil(size(preview,1)*double(ymin)/meta.ySize);
xmaxprev = ceil(size(preview,2)*double(xmax)/meta.xSize);
xminprev = ceil(size(preview,2)*double(xmin)/meta.xSize);



for ci = 1:nC
    preview(yminprev:ymaxprev,xminprev:xmaxprev, ci) = ...
        imresize(img(:,:,ci),[ymaxprev-yminprev+1, xmaxprev-xminprev+1]);
    % rescale lookup for easy preview
    preview(:,:,ci) = imadjust(mat2gray(preview(:,:,ci)));
end

% make overview image of results of this function
maskPreview = imresize(mask, [size(preview,1) size(preview,2)]);
cleanmaskPreview = imresize(cleanmask, [size(preview,1) size(preview,2)]);
maskPreviewRGB = cat(3,maskPreview,cleanmaskPreview,0*maskPreview);
scale = mean(size(mask)./[size(preview,1) size(preview,2)]);

figure(1),
imshow(maskPreviewRGB)
%imwrite(maskPreviewRGB, fullfile(dataDir,'preview',['previewMask_' vsinr '.tif']));
hold on
for ii=1:length(colonies)
    bbox = colonies(ii).boundingBox/scale;
    rec = [bbox(1), bbox(3), bbox(2)-bbox(1), bbox(4)-bbox(3)];
    rectangle('Position',rec,'LineWidth',2,'EdgeColor','g')
    text(bbox(1),bbox(3)-25, ['col ' num2str(colonies(ii).ID)],'Color','g','FontSize',15);
end
hold off
% saveas(gcf, fullfile(dataDir,'preview',['previewSeg_' vsinr '.tif']));
%close;
%
% imwrite(squeeze(preview(:,:,1)),fullfile(dataDir,'preview',['previewDAPI_' vsinr '.tif']));
% imwrite(preview(:,:,2:4),fullfile(dataDir,'preview',['previewRGB_' vsinr '.tif']));
end