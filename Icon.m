classdef Icon < handle & matlab.mixin.CustomDisplay
    %ICONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Env = struct('Root', '', 'IconsDir', 'icons', 'DataDir', 'data',...
            'ColorsFile', 'html_colors.mat');
        Settings = struct('DispProps', ["Packs" "Name" "Color" "Scale"],...
            'DispAllProps', false, 'ImPref', 'icon-')
        Packs
        AllPacks
        Icons
        Colors
        Axes
        Name
        Image
        Color
        Scale = 1
    end
    
    methods
        function obj = Icon()
            %ICONS Construct an instance of this class
            obj.getRoot();
            obj.getPacks();
            obj.getIcons();
            obj.getColors();
        end
        
        function [packs, allpacks] = getPacks(obj)
            %Get icon packs
            ds = struct2table(dir(obj.getIRoot));
            ds = ds(3:end, :);
            ds = ds(ds.isdir, :);
            packs = string(ds.name);
            obj.AllPacks = packs;
            if isempty(obj.Packs)
                obj.Packs = packs;
            else
                packs = obj.Packs;
            end
            allpacks = obj.AllPacks;
        end
        
        function icons = getIcons(obj, packs)
            %Get icons list
            if nargin < 2 || isempty(packs)
                packs = string(obj.Packs);
            end
            icons = [];
            ps = [];
            if ~isempty(packs)
                for i = 1 : length(packs)
                    fs = dir(fullfile(obj.getIRoot, packs(i), '*.png'));
                    fs = string({fs.name})';
                    icons = [icons; erase(fs, '.png')];
                    ps = [ps; repmat(packs(i), length(fs), 1)];
                end
            end
            if isempty(icons)
                icons = {};
            end
            icons = table(icons, ps, 'VariableNames', {'Name', 'Pack'});
            obj.Icons = icons;
        end
        
        function colors = getColors(obj)
            %Load HTML colors
            res = load(fullfile(obj.Env.Root, obj.Env.DataDir, obj.Env.ColorsFile));
            colors = res.colors;
            colors = table(colors.keys', colors.values');
            colors.Properties.VariableNames = {'Name', 'Value'};
            obj.Colors = colors;
        end
        
        function [packs, icons] = usePacks(obj, packs)
            %Get icon packs
            if isnumeric(packs)
                packs = obj.AllPacks(packs);
            else
                packs = intersect(obj.AllPacks, packs);
            end
            obj.Packs = packs;
            icons = obj.getIcons();
        end
        
        function icons = search(obj, name)
            %Search icons by name
            if nargin > 0 && ~isempty(name)
                icons = obj.Icons.Name;
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
            n = colors.Name;
            c = colors.Value;
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
        
        function show(obj, ax)
            %Show icon
            obj.validateName();
            if nargin > 1
                obj.Axes = ax;
            end
            if isempty(obj.Axes) || ~isvalid(obj.Axes)
                f = figure('Name', obj.Name);
                obj.Axes = axes(f);
            end
            obj.load();
            h = imshow(obj.Image.im, 'Parent', obj.Axes);
            h.AlphaData = obj.Image.alpha;
            title(obj.Axes, obj.Name, 'Interpreter', 'none');
            axes(obj.Axes);
        end
        
        function obj = use(obj, icon)
            %Use specified icon
            obj.validateIcon(icon);
            if isnumeric(icon)
                obj.load(obj.Icons.Name{icon});
            else
                obj.load(icon);
            end
        end
        
        function obj = rand(obj)
            %Use random icon
            icon = randi(height(obj.Icons));
            obj.use(icon);
        end
        
        function pickColor(obj)
            %Pick color manually
            color = uisetcolor();
            if ~color
                color = [];
            end
            obj.Color = color;
        end
        
        function set.Name(obj, name)
            % Set Icon name
            obj.validateIcon(name);
            obj.Name = name;
        end
        
        function impath1 = save(obj, imdir)
            %Save icon to disk
            if nargin < 2
                imdir = pwd;
            end
            obj.load();
            obj.writeImage(imdir);
            if nargout > 0
                impath1 = impath;
            end
        end
        
        function dispAllProps(obj)
            %Display all properties
            obj.Settings.DispAllProps = true;
            disp(obj);
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
            obj.Env.Root = root;
        end
        
        function iroot = getIRoot(obj)
            %Get icon images root dir
            iroot = fullfile(obj.Env.Root, obj.Env.IconsDir);
        end
        
        function impath = getPath(obj, name, pack)
            %Get image path
            if nargin < 3
                pack = obj.Icons.Pack(obj.Icons.Name == name);
                pack = pack(1);
            end
            impath = fullfile(obj.getIRoot, pack, obj.addPng(name));
        end
        
        function load(obj, name)
            %Load icon image
            if nargin > 1
                obj.Name = name;
            end
            obj.validateName();
            obj.validateIcon();
            impath = obj.getPath(obj.Name);
            obj.readImage(impath);
            obj.colorizeImage();
            obj.resizeImage();
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
            obj.Image = struct('path', impath, 'im', im, 'map', map, 'alpha', alpha);
        end
        
        function impath = writeImage(obj, imdir)
            %Write loaded image to specified directory
            imname = obj.addPng(string(obj.Settings.ImPref) + obj.Name);
            impath = fullfile(imdir, imname);
            imwrite(obj.Image.im, impath, 'Alpha', obj.Image.alpha);
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
            idx = colors.Name == lower(string(color));
            if any(idx)
                color = colors.Value{idx};
                color = obj.hex2rgb(color);
            else
                error('Unknown color: %s', color);
            end
        end
        
    end
    
    methods (Access = protected)
        
        function validateIcon(obj, icon)
            %Validate icon exists
            if nargin < 2
                icon = obj.Name;
            end
            if isnumeric(icon)
                if icon < 1 || icon > height(obj.Icons)
                    error('No such icon');
                end
            else
                if ~ismember(icon, obj.Icons.Name)
                    error('No such icon: %s', icon);
                end
            end
        end
        
        function validateName(obj)
            %Validate icon specified
            if isempty(obj.Name)
                error('Icon not loaded. Load icon with ''use'' or ''rand'' command');
            end
        end
        
        function propgrp = getPropertyGroups(obj)
            if obj.Settings.DispAllProps
                props = properties(obj);
                obj.Settings.DispAllProps = false;
            else
                props = obj.Settings.DispProps;
            end
            propgrp = matlab.mixin.util.PropertyGroup(props);
        end
        
        function footer = getFooter(~)
            cname = mfilename('class');
            footer = sprintf(['<a href="matlab:disp(''Call dispAllProps method'')">All Properties</a>,'...
                ' <a href="matlab:methods(%s)">Methods</a>'], cname);
        end
    end
end

