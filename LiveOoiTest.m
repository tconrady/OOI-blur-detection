%% 	Calculates blur scores for masked images of the LIVE database
%	Uses the following blur measure algorithms
%	BRISQUE, CPBD, FISH, S3, SVF
%
%   dependencies:   brisque_score.m, CPBD_compute.m, fish_bb.m,
%                   s3_map.m, msvf.m,
%                   'LIVE database release2', binary masks
%	input:
%	startpoint 	-	int	id of first image
%	endpoint	-	int	id of last image
%   bgColor     -   char flag decides which background is used
%                   options are
%                   'B' for black background
%                   'W' for white background
%                   'N' for noisy background
%	output:
%	scores		-	cell array saved in the folder of this script
%					obeys the following structure: {filename,
%                   subjectscore, BRISQUE, CPBD, FISH, S3, SVF}
function scores = maskTest(startpoint,endpoint,BWN)

BlackBG = 'B';
WhiteBG = 'W';
%NoiseBG = 'N';
maskFolder = 'masks2';

copyfile('brisquefiles/','/work/BRISQUE/');
try
    addpath /work/BRISQUE/
    
    load('dmos_gb.mat');
    
    %info has reference name, img index and sigma
    fileID = fopen('info.txt');
    info = textscan(fileID,'%s img%d %*4c %f');
    infoid = cell2mat(info(2));
    inforef = info(1);
    fclose(fileID);
    
    
    %%
    imgpath = fullfile('InputFolder','Linktodatabaserelease2','gblur');
    files = dir(fullfile(imgpath,'*.bmp'));
    nFiles = size(files,1);
    
    
    %%
    assert(startpoint > 0 && startpoint < endpoint,...
        'bad value for startpoint')
    assert(endpoint > startpoint && endpoint <= nFiles,...
        'bad value for endpoint')
    
    %all scores:
    %(filename, subjectscore, CPBD, BRISQUE, SVF, FISH, S3)
    scores = cell(nFiles,7);
    
    for i = startpoint:endpoint
        data = cell(1,7);
        
        
        data{1} = files(i).name;
        
        d = sscanf(files(i).name,'img %u');
        data{2} = dmos_gb(d);
        
        refname = char(inforef{1}(infoid==d));
        refname(refname==char(10))=[];  %linefeed at refname(1)
        imgwithoutmask = imread(fullfile(imgpath, files(i).name));
        mask = imread(fullfile(maskFolder,['maskof.' refname]));
        
        switch BWN
            case BlackBG
                if(size(imgwithoutmask,3) == 3) % color image
                    mask = repmat(mask,1,1,3);
                end
                img = imgwithoutmask.*uint8(mask);
            case WhiteBG
                if(size(imgwithoutmask,3) == 3) % color image
                    tmp1 = imgwithoutmask(:,:,1);
                    tmp1(~mask) = 255;
                    tmp2 = imgwithoutmask(:,:,2);
                    tmp2(~mask) = 255;
                    tmp3 = imgwithoutmask(:,:,3);
                    tmp3(~mask) = 255;
                    img = uint8(ones(size(imgwithoutmask)));
                    img(:,:,1) = tmp1;
                    img(:,:,2) = tmp2;
                    img(:,:,3) = tmp3;
                else % grey scale image
                    assert(size(imgwithoutmask,3) == 1,...
                        'weird image size encountered');
                    img = 255*ones(size(imgwithoutmask));
                    img(mask) = imgwithoutmask;
                end
            otherwise
                %NoiseBG
                if(size(imgwithoutmask,3) == 3) % color image
                    img1 = imgwithoutmask(:,:,1);
                    img2 = imgwithoutmask(:,:,2);
                    img3 = imgwithoutmask(:,:,3);
                    tmp1 = uint8(ceil(rand(size(imgwithoutmask,1),...
                        size(imgwithoutmask,2))*255));
                    tmp1(mask) = img1(mask);
                    tmp2 = uint8(ceil(rand(size(imgwithoutmask,1),...
                        size(imgwithoutmask,2))*255));
                    tmp2(mask) = img2(mask);
                    tmp3 = uint8(ceil(rand(size(imgwithoutmask,1),...
                        size(imgwithoutmask,2))*255));
                    tmp3(mask) = img3(mask);
                    img = uint8(zeros(size(imgwithoutmask)));
                    img(:,:,1) = tmp1;
                    img(:,:,2) = tmp2;
                    img(:,:,3) = tmp3;
                else % grey scale image
                    assert(size(imgwithoutmask,3) == 1,...
                        'weird image size encountered');
                    img = uint8(ceil(rand(size(imgwithoutmask))*255));
                    img(mask) = imgwithoutmask;
                end
        end
        
        oldPath = cd(fullfile(filesep,'work','BRISQUE'));
        try
            data{3} = brisquescore(img);
        catch err
            cd(oldPath);
            rmdir(fullfile(filesep, 'work','BRISQUE'),'s');
            rethrow(err);
        end
        cd(oldPath);
        
        data{4} = CPBD_compute(img);
        
        [data{5},~] = fish_bb(double(rgb2gray(img)));
        
        %calculate S3 measure according to the paper
        [~,~,s3] = s3_map(double(rgb2gray(img)));
        [y,~] = sort(reshape(s3,numel(s3),1),'descend');
        data{6} = mean(y(1:(numel(y)/100)));
        
        %Parameters k=6 ps=15
        [~,~,~,d] = msvf(img,6,15);
        data{7} = d;
        
        scores(i,:) = data;
    end
    rmpath /work/BRISQUE/
    rmdir(fullfile(filesep,'work','BRISQUE'),'s');
    
    save([maskFolder 'LIVE' BWN '.' num2str(startpoint) '.' ...
          num2str(endpoint) '.mat'],'scores');
    
catch err
    rmdir(fullfile(filesep, 'work','BRISQUE'),'s');
    rethrow(err);
end
end
