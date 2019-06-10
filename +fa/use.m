function resname1 = use(name, size, color)
if nargin < 1
    icons = fa.list();
    name = icons(randi(length(icons)));
end
impath = fa.Util.getpath(name);
imname = fa.Util.addpng(name);
if ~isfile(impath)
    error('Icon %s is not found', imname)
end
fileinfo = imfinfo(impath);
[im, map, alpha] = imread(impath);
if nargin > 1 && ~isempty(size)
    im2 = fa.Util.resize(im, size);
    alpha2 = fa.Util.resize(alpha, size);
else
    im2 = im;
    alpha2 = alpha;
end
resname = "icon-fa-" + imname;
resdir = pwd;
respath = fullfile(resdir, resname);
if nargin > 2 && ~isempty(color)
    im2 = fa.Util.colorize(im2, color);
    imwrite(im2, respath, 'Alpha', alpha2);
else
    imwrite(im2, map, respath, 'Transparency', fileinfo.SimpleTransparencyData);
end
if nargout > 0
    resname1 = resname;
end
end