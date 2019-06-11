function ps = packs()
ds = struct2table(dir(fullfile(fa.Util.getiroot)));
ds = ds(3:end, :);
ds = ds(ds.isdir, :);
ps = ds.name;
end