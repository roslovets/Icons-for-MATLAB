classdef Icons < handle
    %ICONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        root
        iroot
        packs
        allpacks
        icons
        colors
    end
    
    methods
        function obj = Icons()
            %ICONS Construct an instance of this class
            obj.getroot();
            obj.getiroot();
            obj.getpacks();
            obj.geticons();
            obj.getcolors();
        end
        
        function [packs, icons] = usepacks(obj, packs)
            %Get icon packs
            packs = intersect(obj.allpacks, packs);
            obj.packs = packs;
            icons = obj.geticons();
        end
        
        function icons = search(obj, name)
            %Search icons by name
            if nargin > 0 && ~isempty(name)
                icons = obj.icons.name;
                icons = obj.icons(contains(icons, lower(name)), :);
            else
                icons = obj.icons;
            end
        end
        
        function showcolors(obj)
            %Show HTML colors
            f = figure('Name', 'HTML Colors');
            a = axes(f);
            hold(a, 'on');
            colors = obj.colors;
            n = colors.name;
            c = colors.value;
            c2 = [];
            ncols = 6;
            nrows = length(c) / ncols;
            for i = 1 : length(c)
                c2 = [c2; rgb2hsv(obj.hex2rgb(c{i}))];
            end
            [c2, ids] = sortrows(c2);
            c2 = hsv2rgb(c2);
            n = n(ids);
            for i = 0 : length(c)-1
                nc = floor(i / nrows);
                nr = mod(i, nrows);
                plot(a, [0 1] + nc, [nr nr], 'Color', c2(i+1, :), 'LineWidth', 20)
                text(nc, nr, n{i+1}, 'Interpreter', 'none');
            end
            hold(a, 'off');
            ylim(a, [0 nrows])
            axis(a, 'off')
        end
        
        function show(obj, name, color, size, axes)
            impath = obj.getpath(name);
            if nargin < 5
                argadd = {};
            else
                argadd = {'Parent', axes};
            end
            [im, ~, alpha] = obj.imread(impath);
            if nargin > 2 && ~isempty(color)
                if nargin > 3 && ~isempty(size)
                    im = obj.resize(im, size);
                    alpha = obj.resize(alpha, size);
                end
                im = obj.colorize(im, color);
            end
            h = imshow(im, argadd{:});
            h.AlphaData = alpha;
            if nargin < 5
                axes = h.Parent;
            end
            title(axes, name, 'Interpreter', 'none');
        end
        
        function resname1 = use(obj, name, size, color)
            if nargin < 2
                icons = obj.icons.name;
                name = icons(randi(length(icons)));
            end
            impath = obj.getpath(name);
            imname = obj.addpng(name);
            if ~isfile(impath)
                error('Icon %s is not found', imname)
            end
            [im, ~, alpha] = obj.imread(impath);
            if nargin > 2 && ~isempty(size)
                im2 = obj.resize(im, size);
                alpha2 = obj.resize(alpha, size);
            else
                im2 = im;
                alpha2 = alpha;
            end
            resname = "icon-" + imname;
            resdir = pwd;
            respath = fullfile(resdir, resname);
            if nargin > 3 && ~isempty(color)
                im2 = obj.colorize(im2, color);
            end
            imwrite(im2, respath, 'Alpha', alpha2);
            if nargout > 0
                resname1 = resname;
            end
        end
        
    end
    
    methods (Hidden = true)
        function imname = addpng(obj, name)
            %Add .png to icon name
            if ~endsWith(name, '.png')
                imname = name + ".png";
            else
                imname = name;
            end
        end
        
        function name = rmpng(obj, imname)
            %Remove .png from icon name
            imname = char(imname);
            if endsWith(imname, '.png')
                name = imname(1:end-4);
            else
                name = imname;
            end
        end
        
        function root = getroot(obj)
            %Get toolbox root path
            root = fileparts(mfilename('fullpath'));
            obj.root = root;
        end
        
        function iroot = getiroot(obj)
            %Get icon images root dir
            iroot = fullfile(obj.root, 'icons');
            obj.iroot = iroot;
        end
        
        function impath = getpath(obj, name, pack)
            %Get image path
            if nargin < 3
                pack = obj.icons.pack(obj.icons.name == name);
                pack = pack(1);
            end
            impath = fullfile(obj.iroot, pack, obj.addpng(name));
        end
        
        function packs = getpacks(obj)
            %Get icon packs
            ds = struct2table(dir(obj.iroot));
            ds = ds(3:end, :);
            ds = ds(ds.isdir, :);
            packs = string(ds.name);
            obj.allpacks = packs;
            obj.packs = packs;
        end
        
        function icons = geticons(obj, packs)
            if nargin < 2 || isempty(packs)
                packs = string(obj.packs);
            end
            icons = [];
            ps = [];
            if ~isempty(packs)
                for i = 1 : length(packs)
                    fs = dir(fullfile(obj.iroot, packs(i), '*.png'));
                    fs = string({fs.name})';
                    icons = [icons; erase(fs, '.png')];
                    ps = [ps; repmat(packs(i), length(fs), 1)];
                end
            end
            if isempty(icons)
                icons = {};
            end
            obj.icons = table(icons, ps, 'VariableNames', {'name', 'pack'});
        end
        
        
        function [im, map, alpha] = imread(obj, impath)
            %Read image as RGBA
            [im, map, alpha] = imread(impath);
            if ndims(im) == 2
                im(:) = 0;
                im = cat(3, im, im, im);
            end
            if class(alpha) == "double"
                alpha = uint8(alpha * 255);
            end
        end
        
        function im = resize(obj, im, size)
            %Change image size
            if numel(size) == 1
                size = [size size];
            end
            im = imresize(im, size, 'Method', 'bilinear');
        end
        
        function im = colorize(obj, im, color)
            %Colorize image
            if ~isnumeric(color)
                if startsWith(color, '#')
                    color = obj.hex2rgb(color);
                elseif startsWith(color, '[')
                    color = extractBetween(color, '[', ']');
                    color = str2num(color{1});
                else
                    color = obj.color2rgb(color);
                end
            end
            color = color * 255;
            im(:,:,1) = color(1);
            im(:,:,2) = color(2);
            im(:,:,3) = color(3);
        end
        
        function color = hex2rgb(obj, color)
            %Convert color from hex to 0-1 RGB
            c = [hex2dec(color(2:3)) hex2dec(color(4:5)) hex2dec(color(6:7))];
            color = c/255;
        end
        
        function color = color2rgb(obj, color)
            %Convert color from name to 0-1 RGB
            colors = obj.colors;
            idx = colors.name == lower(string(color));
            if any(idx)
                color = colors.value{idx};
                color = obj.hex2rgb(color);
            else
                error('Unknown color: %s', color);
            end
        end
        
        function colors = getcolors(obj)
            %Load HTML colors
            res = load('html_colors.mat');
            colors = res.colors;
            colors = table(colors.keys', colors.values');
            colors.Properties.VariableNames = {'name', 'value'};
            obj.colors = colors;
        end
        
    end
end

