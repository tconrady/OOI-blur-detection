%%Blur region measure using Singular Value Function 
% based on the 2011 paper by Su et al. 
% Input:
%   image       -   in RGB or grayscale
%   k           -   number of singular values to consider
%   patchsize   -   the size of the sliding window
%
% Outputs:
%   scoremap    -   an array of blur scores with 
%                   the same size as the input image
%   dScore      -   a scalar score representing the blurriness
%                   of the whole image

function [scoremap, dScore] = svf(image, k, patchsize)

% converts rgb images into hsv and only take the value dimension
if (size(image,3) == 3)
    image = rgb2hsv(image);
    image = image(:,:,3);
end
image = double(image);

% padding of the image avoids cropping
halfpatch = floor(patchsize/2);
imgPadded = padarray(image,[halfpatch halfpatch],'symmetric');
[padHeight, padWidth] = size(imgPadded);

% inner start and end indexes because of padding
startH = halfpatch+1;
startW = halfpatch+1;
endH = padHeight - halfpatch;
endW = padWidth - halfpatch;

betamap = zeros(size(imgPadded));
parfor h = startH:endH;
    for w = startW:endW;
        
        % svd window
        h1 = h-halfpatch;
        w1 = w-halfpatch;
        h2 = h+halfpatch;
        w2 = w+halfpatch;
        
        s = svd(imgPadded(h1:h2,w1:w2));
        
        % beta score for pixel(h,w) 
        betamap(h,w) = sum(s(1:k))/sum(s);
    end
end
scoremap = betamap(startH:endH, startW:endW);

% d, beta, and omega calculations according to the paper by Su et al.
s = svd(image);
beta = sum(s(1:k))/sum(s);

omega = numel(scoremap);
omegab = nnz(scoremap>0.75);
omeg = omegab/omega;

dScore = 0.5 * beta + 0.5 * omeg;
end
