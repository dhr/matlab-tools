function [img, alpha] = readGray(pathname, wts)
%READGRAY Read a grayscale image
%   IMAGE = READGRAY(FILENAME, WTS) reads image data from FILENAME, and
%   converts it into grayscale image IMAGE with values lying in the range
%   [0, 1]. The WTS parameter can be supplied to specify the relative
%   weighting of each color channel. sum(WTS) should be 1, and WTS defaults
%   to [0.3, 0.59, 0.11].

  if ~exist('wts', 'var')
    wts = [0.3, 0.59, 0.11];
  end

  if ~isempty(regexpi(pathname, '\.pgm$', 'once'))
    img = readPGM(pathname);
    alpha = ones(size(image));
  else
    [img, ignore, alpha] = imread(pathname);
    alpha = im2double(alpha);
  end

  img = im2double(img);
  if size(img, 3) == 2
    img = img(:,:,1);
  elseif size(img, 3) >= 3
    img = sum(bsxfun(@times, img(:,:,1:3), shiftdim(wts(:), -2)), 3);
  end

  function image = readPGM(filename)
  %READPGM Read a raw pgm file as a matrix
  %   IMAGE = READPGM(FILENAME) reads the binary PGM image data from the
  %   file named FILENAME and returns the image as a 2-dimensional array of
  %   integers IMAGE. Assumes the file is a raw PGM file containing 8-bit
  %   unsigned character data to represent pixel values.
  %
  %   Matthew Dailey, 1997

    fid = fopen(filename, 'r');

    % Parse and check the header information.  No # comments allowed.
    A = fgets(fid);
    if strcmp(A(1:2), 'P5') ~= 1
      fclose(fid);
      error('File is not a raw PGM.');
    end;

    A = fgets(fid);
    sizes = sscanf(A, '%d');
    w = sizes(1);
    h = sizes(2);

    A = fgets(fid);
    max = sscanf(A, '%d');
    tlength = w*h;

    if max ~= 255
      fclose(fid);
      error('Cannot handle anything but 8-bit graymaps.');
    end;

    [v, count] = fread(fid, inf, 'uchar');
    fclose(fid);

    if count ~= tlength
      error('File size does not agree with specified dimensions.');
    end;

    image = reshape(v, w, h)'/max;
  end
end
