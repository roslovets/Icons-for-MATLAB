matsrc = 'C:\Users\roslovetspv\Downloads\material-design-icons-master\material-design-icons-master';
matsize = 'drawable-xxxhdpi';
mattype = '_black_48dp';
idir = fullfile('..', 'icons', 'GoogleMaterial-mat');
fs = struct2table(dir(matsrc));
fs = fs(3:end, :);
fs = fs(fs.isdir, :);
for i = 1 : height(fs)
    ics = struct2table(dir(fullfile(matsrc, fs.name{i}, matsize, ['*' mattype '.png'])));
    if ~isempty(ics)
        for j = 1 : height(ics)
            iname = "mat" + ics.name{j}(3:end);
            iname = erase(iname, mattype);
            iname = replace(iname, '_', '-');
            copyfile(fullfile(ics.folder{j}, ics.name{j}), fullfile(idir, iname));
        end
    end
end
% fs = dir(fullfile(idir, '*.png'));
% fs = {fs.name}';