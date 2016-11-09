%% 	Calculates blur scores for full images of the TID database
%	Uses the following blur measure algorithms
%	BRISQUE, CPBD, FISH, S3, SVF
%   
%   dependencies:   brisque_score.m, CPBD_compute.m, fish_bb.m, 
%                   s3_map.m, msvf.m, 'TID2013 database'
%	input:
%	startpoint 	-	int	id of first image
%	endpoint	-	int	id of last image 
%	output:
%	scores		-	cell array saved in the folder of this script 
%					obeys the following structure: {filename, 
%                   subjectscore, BRISQUE, CPBD, FISH, S3, SVF}
function scores = TIDTest(startpoint,endpoint)

% BRISQUE needs seperate folder on the machine for grid computing
copyfile('brisquefiles/','/work/BRISQUE/');
try
    addpath /work/BRISQUE/
    
    % subject scores of TID are supplied in a .txt file
    fileID = fopen('mos_with_names.txt');
    mos = textscan(fileID,'%f %s');
    fclose(fileID);
    
    %% get the images
    imgpath = fullfile('InputFolder','Linktogblur');
    files = dir(fullfile(imgpath,'*.bmp'));
    n = size(files,1);
    
    
    %% get scores for images between startpoint and endpoint
    assert(startpoint > 0 && startpoint < endpoint,...
           'bad value for startpoint')
    assert(endpoint > startpoint && endpoint <= n,...
           'bad value for endpoint')
    
    % matrix for all n scores contains:
    % (filename, subjectscore, BRISQUE, CPBD, FISH, S3, SVFD)
    scores = cell(n,7);
    
    for i = startpoint:endpoint
        img = imread(fullfile(imgpath, files(i).name));
        
        data = cell(1,7);
        data{1} = files(i).name;
        
        % find the opinion score in the txt file from the image name
        idx = strfind(mos{2},files(i).name);
        emptyIndex = cellfun(@isempty,idx); % some cells are empty
        idx(emptyIndex) = {0};             
        idx = logical(cell2mat(idx));      
        data{2} = mos{1}(idx);
        
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
        
        %CPBD
        data{4} = CPBD_compute(img);
        
        %FISH needs grayscale image cast in double
        grayimg = double(rgb2gray(img));
        
        [data{5},~] = fish_bb(grayimg);
        
        %calculate S3 measure according to the paper
        [~,~,s3] = s3_map(grayimg);
        [y,~] = sort(reshape(s3,numel(s3),1),'descend');
        data{6} = mean(y(1:(numel(y)/100)));
        
        % SVF withParameters k=6 ps=15
        [~,~,~,d] = msvf(img,6,15);
        data{7} = d;
        
        % saving name, subjects, and all five computed scores in the matrix
        scores(i,:) = data;
    end
    %% clean up and save
    % clean-up for BRISQUE
    rmpath /work/BRISQUE/
    rmdir(fullfile(filesep,'work','BRISQUE'),'s');
    
    % write the matrix for these images to the output file
    save(['masks0TIDC.' num2str(startpoint) '.'...
           num2str(endpoint) '.mat'],'scores');
    
catch err
    rmdir(fullfile(filesep, 'work','BRISQUE'),'s');
    rethrow(err);
end
end
