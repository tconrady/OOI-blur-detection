%% 	Calculates blur scores for full images of the LIVE database
%	Uses the following blur measure algorithms
%	BRISQUE, CPBD, FISH, S3, SVF
%   
%   dependencies:   brisque_score.m, CPBD_compute.m, fish_bb.m, 
%                   s3_map.m, msvf.m, 'LIVE database release2'
%	input:
%	startpoint 	-	int	id of first image
%	endpoint	-	int	id of last image 
%	output:
%	scores		-	cell array saved in the folder of this script 
%					obeys the following structure: {filename, 
%                   subjectscore, BRISQUE, CPBD, FISH, S3, SVF}

function scores = LIVETest(startpoint,endpoint)

% BRISQUE needs a seperate folder on the machine for grid computing
copyfile('brisquefiles/','/work/BRISQUE/');
try
    addpath /work/BRISQUE/
    
    % subject scores of LIVE are supplied in a .mat file
    load('dmos_gb.mat');
        
    %% get the images of the database
    imgpath = fullfile('InputFolder','Linktodatabaserelease2','gblur');
    files = dir(fullfile(imgpath,'*.bmp'));
    nFiles = size(files,1);
    
    %% get scores for images between startpoint and endpoint	
    assert(startpoint > 0 && startpoint < endpoint,...
           'bad value for startpoint')
    assert(endpoint > startpoint && endpoint <= nFiles,...
           'bad value for endpoint')
    
    %cell array for all scores contains:
    %(filename, subjectscore, BRISQUE, CPBD, FISH, S3, SVF)
    scores = cell(nFiles,7);
    
    for i = startpoint:endpoint
        img = imread(fullfile(imgpath, files(i).name));
		data = cell(1,7);
        
        % name
        data{1} = files(i).name;
        
        % opinion score by subjects
        d = sscanf(files(i).name,'img %u');
        data{2} = dmos_gb(d);
        
        % BRISQUE needs seperate folder on the machine for 
        % grid computing
        oldPath = cd(fullfile(filesep,'work','BRISQUE'));
        try
            data{3} = brisquescore(img);
        catch err
            cd(oldPath);
            rmdir(fullfile(filesep, 'work','BRISQUE'),'s');
            rethrow(err);
        end
        cd(oldPath);
        
        % CPBD
        data{4} = CPBD_compute(img);
        
        % FISH needs grayscale image cast in double
        grayimg = double(rgb2gray(img));
        [data{5},~] = fish_bb(grayimg);
        
        % calculate S3 measure according to the paper
        [~,~,s3] = s3_map(grayimg);
        [y,~] = sort(reshape(s3,numel(s3),1),'descend');
        data{6} = mean(y(1:(numel(y)/100)));
        
        % SVF with parameters k=6 ps=15
        [~,~,~,d] = msvf(img,6,15);
        data{7} = d;
        
        % saving name, MOS, and all five computed 
        % scores in the array
        scores(i,:) = data;
    end
    %% clean up and save
    % clean-up for BRISQUE
    rmpath /work/BRISQUE/
    rmdir(fullfile(filesep,'work','BRISQUE'),'s');
    
    % write the matrix for these images to the output file
    save(['masks0LIVEC.' num2str(startpoint) '.'...
          num2str(endpoint) '.mat'],'scores');
    
catch err
	% clean up in case of error
    rmdir(fullfile(filesep, 'work','BRISQUE'),'s');
    rethrow(err);
end
end
