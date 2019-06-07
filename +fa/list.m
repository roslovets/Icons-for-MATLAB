function icons = list()
fs = dir(fullfile(fa.Util.getimroot, '*.png'));
fs = string({fs.name})';
icons = erase(fs, '.png');
end