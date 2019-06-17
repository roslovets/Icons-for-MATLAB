classdef Icon < handle & matlab.mixin.CustomDisplay
    %ICONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Root
        IRoot
        Packs
        AllPacks
        Icons
        Colors
        Name
        Image
        Color
        Scale = 1
    end
    
    methods
        function obj = Icon()
            %ICONS Construct an instance of this class
            obj.getRoot();
            obj.getIRoot();
            obj.getPacks();
            obj.getIcons();
            obj.getColors();
        end
        
        function [packs, icons] = usePacks(obj, packs)
            %Get icon packs
            packs = intersect(obj.AllPacks, packs);
            obj.Packs = packs;
            icons = obj.getIcons();
        end
        
        function icons = search(obj, name)
            %Search icons by name
            if nargin > 0 && ~isempty(name)
                icons = obj.Icons.name;
                icons = obj.Icons(contains(icons, lower(name)), :);
            else
                icons = obj.Icons;
            end
        end
        
        function showColors(obj)
            %Show HTML colors
            f = figure('Name', 'HTML Colors');
            a = axes(f);
            hold(a, 'on');
            colors = obj.Colors;
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
        
        function show(obj, axes)
            if nargin < 2
                argadd = {};
            else
                argadd = {'Parent', axes};
            end
            if isempty(obj.Image)
                obj.load();
            end
            h = imshow(obj.Image.im, argadd{:});
            h.AlphaData = obj.Image.alpha;
            if nargin < 2
                axes = h.Parent;
            end
            title(axes, obj.Name, 'Interpreter', 'none');
        end
        
        function load(obj, name)
            if nargin < 2
                name = obj.Name;
            else
                obj.Name = name;
            end
            impath = obj.getPath(name);
            imname = obj.addPng(name);
            if ~isfile(impath)
                error('Icon %s is not found', imname)
            end
            obj.readImage(impath);
            obj.Name = name;
            obj.colorizeImage();
            obj.resizeImage();
        end
        
        function rand(obj)
            icons = obj.Icons.name;
            name = icons(randi(length(icons)));
            obj.load(name);
        end
        
        function set.Color(obj, color)
            % Set Icon color
            obj.Color = color;
            if ~isempty(obj.Image)
                obj.load();
            end
        end
        
        function pickColor(obj)
            color = uisetcolor();
            if ~color
                color = [];
            end
            obj.Color = color;
        end
        
        function set.Scale(obj, scale)
            % Set Icon color
            obj.Scale = scale;
            if ~isempty(obj.Image)
                obj.load();
            end
        end
        
        function resname1 = use(obj, name, size, color)
            if nargin < 2
                icons = obj.Icons.name;
                name = icons(randi(length(icons)));
            end
            impath = obj.getPath(name);
            imname = obj.addPng(name);
            if ~isfile(impath)
                error('Icon %s is not found', imname)
            end
            [im, ~, alpha] = obj.readImage(impath);
            if nargin > 2 && ~isempty(size)
                im2 = obj.resizeImage(im, size);
                alpha2 = obj.resizeImage(alpha, size);
            else
                im2 = im;
                alpha2 = alpha;
            end
            resname = "icon-" + imname;
            resdir = pwd;
            respath = fullfile(resdir, resname);
            if nargin > 3 && ~isempty(color)
                im2 = obj.colorizeImage(im2, color);
            end
            imwrite(im2, respath, 'Alpha', alpha2);
            if nargout > 0
                resname1 = resname;
            end
        end
        
    end
    
    methods (Hidden = true)
        function imname = addPng(~, name)
            %Add .png to icon name
            if ~endsWith(name, '.png')
                imname = name + ".png";
            else
                imname = name;
            end
        end
        
        function name = rmPng(~, imname)
            %Remove .png from icon name
            imname = char(imname);
            if endsWith(imname, '.png')
                name = imname(1:end-4);
            else
                name = imname;
            end
        end
        
        function root = getRoot(obj)
            %Get toolbox root path
            root = fileparts(mfilename('fullpath'));
            obj.Root = root;
        end
        
        function iroot = getIRoot(obj)
            %Get icon images root dir
            iroot = fullfile(obj.Root, 'icons');
            obj.IRoot = iroot;
        end
        
        function impath = getPath(obj, name, pack)
            %Get image path
            if nargin < 3
                pack = obj.Icons.pack(obj.Icons.name == name);
                pack = pack(1);
            end
            impath = fullfile(obj.IRoot, pack, obj.addPng(name));
        end
        
        function packs = getPacks(obj)
            %Get icon packs
            ds = struct2table(dir(obj.IRoot));
            ds = ds(3:end, :);
            ds = ds(ds.isdir, :);
            packs = string(ds.name);
            obj.AllPacks = packs;
            obj.Packs = packs;
        end
        
        function icons = getIcons(obj, packs)
            if nargin < 2 || isempty(packs)
                packs = string(obj.Packs);
            end
            icons = [];
            ps = [];
            if ~isempty(packs)
                for i = 1 : length(packs)
                    fs = dir(fullfile(obj.IRoot, packs(i), '*.png'));
                    fs = string({fs.name})';
                    icons = [icons; erase(fs, '.png')];
                    ps = [ps; repmat(packs(i), length(fs), 1)];
                end
            end
            if isempty(icons)
                icons = {};
            end
            obj.Icons = table(icons, ps, 'VariableNames', {'name', 'pack'});
        end
        
        
        function readImage(obj, impath)
            %Read image as RGBA
            [im, map, alpha] = imread(impath);
            if ismatrix(im)
                im(:) = 0;
                im = cat(3, im, im, im);
            end
            if class(alpha) == "double"
                alpha = uint8(alpha * 255);
            end
            obj.Image = struct('im', im, 'map', map, 'alpha', alpha);
        end
        
        function resizeImage(obj, scale)
            %Change image size
            if nargin < 2
                scale = obj.Scale;
            end
            if scale ~= 1
                obj.Image.im = imresize(obj.Image.im, scale, 'Method', 'bilinear');
                obj.Image.alpha = imresize(obj.Image.alpha, scale, 'Method', 'bilinear');
            end
        end
        
        function colorizeImage(obj, color)
            %Colorize image
            if nargin < 2
                color = obj.Color;
            end
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
            if ~isempty(obj.Image) && ~isempty(color)
                obj.Image.im(:,:,1) = color(1);
                obj.Image.im(:,:,2) = color(2);
                obj.Image.im(:,:,3) = color(3);
            end
        end
        
        function color = hex2rgb(~, color)
            %Convert color from hex to 0-1 RGB
            c = [hex2dec(color(2:3)) hex2dec(color(4:5)) hex2dec(color(6:7))];
            color = c/255;
        end
        
        function color = color2rgb(obj, color)
            %Convert color from name to 0-1 RGB
            colors = obj.Colors;
            idx = colors.name == lower(string(color));
            if any(idx)
                color = colors.value{idx};
                color = obj.hex2rgb(color);
            else
                error('Unknown color: %s', color);
            end
        end
        
        function colors = getColors(obj)
            %Load HTML colors
            res = load('html_colors.mat');
            colors = res.colors;
            colors = table(colors.keys', colors.values');
            colors.Properties.VariableNames = {'name', 'value'};
            obj.Colors = colors;
        end
        
    end
    
    methods (Access = protected)
        function propgrp = getPropertyGroups(obj)
            proplist = {'Name', 'Color', 'Scale'};
            propgrp = matlab.mixin.util.PropertyGroup(proplist);
        end
        
        function footer = getFooter(~)
            cname = mfilename('class');
            
            footer = sprintf('<a href="matlab:methods(%s)">Methods</a>', cname);
        end
    end
end

