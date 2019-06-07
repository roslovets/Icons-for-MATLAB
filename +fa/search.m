function icons = search(name)
icons = fa.list();
if nargin > 0 && ~isempty(name)
    icons = icons(contains(icons, lower(name)));
end
end