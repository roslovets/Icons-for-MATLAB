fasrc = 'C:\Users\roslovetspv\Downloads\Font-Awesome-SVG-PNG-master\black\png';
fasize = '256';
mattype = '_black_48dp';
idir = fullfile('..', 'icons', 'FontAwesome-fa');
ics = struct2table(dir(fullfile(fasrc, fasize, '*.png')));
if ~isempty(ics)
    for j = 1 : height(ics)
        iname = "fa-" + ics.name{j};
        copyfile(fullfile(ics.folder{j}, ics.name{j}), fullfile(idir, iname));
    end
end