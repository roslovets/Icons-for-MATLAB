function is = icons(packs)
if nargin > 0 && ~isempty(packs)
    packs = string(packs);
else
    packs = string(fa.packs);
end
is = [];
if ~isempty(packs)
    for i = 1 : length(packs)
        fs = dir(fullfile(fa.Util.getiroot, packs(i), '*.png'));
        fs = string({fs.name})';
        is = [is; erase(fs, '.png')];
    end
end