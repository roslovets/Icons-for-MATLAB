str = extractFileText('Html True Color Chart.pdf');
s = split(str, newline);
s = s(11:end);
s = s(arrayfun(@(x) length(char(x)), s) > 21);
s = extractAfter(s, ' ');
names0 = extractBefore(s, '#');
names = extractBefore(names0, '(');
ism = ismissing(names);
names(ism) = names0(ism);
names = cellfun(@(x) x(isstrprop(x, 'upper') | x == 32), cellstr(names), 'un', 0);
names = string(strtrim(names));
names = replace(lower(names), ' ', '_');
hex = "#" + extractBetween(s, '#', ' ');
colors = containers.Map(names, hex);
save html_colors colors