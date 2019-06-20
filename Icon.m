classdef Icon < IconUtils
    % Main class for work with icons
    % By Pavel Roslovets, ETMC Exponenta
    % https://github.com/roslovets/Icons-for-MATLAB
    
    properties
        Settings = struct('DispProps', ["Name" "Color" "Scale"],...
            'DispAllProps', false, 'ImPref', 'icon-')
        Name
        Image
        Color
        Scale = 1
        Axes
    end
    
    methods
        function obj = Icon(name)
            %ICONS Construct an instance of this class
            obj@IconUtils();
            if nargin > 0
                obj.use(name);
            end
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
            obj.process();
            h = imshow(obj.Image.Im, 'Parent', obj.Axes);
            h.AlphaData = obj.Image.Alpha;
            if class(obj.Axes) == "matlab.graphics.axis.Axes"
                axes(obj.Axes);
            end
            s = obj.getSize();
            xlim(obj.Axes, [0 s(2)]);
            ylim(obj.Axes, [0 s(1)]);
        end
        
        function obj = use(obj, icon)
            %Use specified icon
            obj.validateIcon(icon);
            if isnumeric(icon)
                obj.Name = obj.Icons.Name{icon};
            else
                obj.Name = icon;
            end
            obj.process();
        end
        
        function obj = rand(obj)
            %Use random icon
            icon = randi(height(obj.Icons));
            obj.use(icon);
        end
        
        function set.Name(obj, name)
            % Set Icon name
            obj.validateIcon(name);
            obj.Name = name;
        end
        
        function set.Color(obj, color)
            % Set Icon name
            obj.validateColor(color);
            obj.Color = color;
        end
        
        function obj = setColor(obj, color)
            %Set color
            obj.Color = color;
        end
        
        function obj = setScale(obj, scale)
            %Set color
            obj.Scale = scale;
        end
        
        function s = getSize(obj)
            %Get image size
            s = size(obj.Image.Im);
            s = s(1:2);
        end
        
        function impath1 = save(obj, imdir)
            %Save icon to disk
            if nargin < 2
                imdir = pwd;
            end
            obj.process();
            obj.writeImage(imdir);
            if nargout > 0
                impath1 = impath;
            end
        end
        
        function [obj, color] = pickColor(obj)
            %Pick color manually
            color = uisetcolor();
            if ~color
                color = [];
            end
            obj.Color = color;
        end
        
        function dispAllProps(obj)
            %Display all properties
            obj.Settings.DispAllProps = true;
            disp(obj);
        end
        
    end
    
    
    methods (Hidden = true)
        
        function impath = getPath(obj, name, pack)
            %Get image path
            obj.validateName();
            if nargin < 2
                name = obj.Name;
            end
            if nargin < 3
                pack = obj.Icons.Pack(obj.Icons.Name == name);
                pack = pack(1);
            end
            impath = fullfile(obj.getIRoot, pack, name + ".png");
        end
        
        function process(obj)
            %Load icon image
            obj.validateName();
            obj.readImage();
            if ~isempty(obj.Color)
                obj.colorizeImage();
            end
            if obj.Scale ~= 1
                obj.resizeImage();
            end
        end
        
        function readImage(obj)
            %Read image as RGBA
            impath = obj.getPath();
            [im, map, alpha] = imread(impath);
            if ismatrix(im)
                im(:) = 0;
                im = cat(3, im, im, im);
            end
            if class(alpha) == "double"
                alpha = uint8(alpha * 255);
            end
            obj.Image = struct('path', impath, 'Im', im, 'Map', map, 'Alpha', alpha);
        end
        
        function impath = writeImage(obj, imdir)
            %Write loaded image to specified directory
            imname = string(obj.Settings.ImPref) + obj.Name + ".png";
            impath = fullfile(imdir, imname);
            imwrite(obj.Image.Im, impath, 'Alpha', obj.Image.Alpha);
        end
        
        function resizeImage(obj)
            %Change image size
            scale = obj.Scale;
            obj.Image.Im = imresize(obj.Image.Im, scale, 'Method', 'bilinear');
            obj.Image.Alpha = imresize(obj.Image.Alpha, scale, 'Method', 'bilinear');
        end
        
        function colorizeImage(obj)
            %Colorize image
            color = obj.Color;
            if ~isnumeric(color)
                if startsWith(color, '#')
                    color = obj.hex2rgb(color);
                elseif startsWith(color, '[') && endsWith(color, ']')
                    color = extractBetween(color, '[', ']');
                    color = str2num(color{1});
                else
                    color = obj.color2rgb(color);
                end
            end
            color = color * 255;
            if ~isempty(obj.Image) && ~isempty(color)
                obj.Image.Im(:,:,1) = color(1);
                obj.Image.Im(:,:,2) = color(2);
                obj.Image.Im(:,:,3) = color(3);
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
                error('Icon not loaded. Load icon with ''use'' or ''rand'' method');
            end
        end
        
        function validateColor(obj, color)
            %Validate color exists
            if nargin < 2
                color = obj.Color;
            end
            if ~isempty(color)
                if isnumeric(color)
                    assert(length(color) == 3, 'Invalid color: %s', num2str(color));
                else
                    if startsWith(color, '#')
                        assert(length(char(color)) == 7, 'Invalid color: %s', color);
                    elseif startsWith(color, '[') && endsWith(color, ']')
                        color = extractBetween(color, '[', ']');
                        color = str2num(color{1});
                        assert(length(color) == 3, 'Invalid color: %s', num2str(color));
                    else
                        if ~ismember(color, obj.Colors.Name)
                            error('Unknown color: %s', color);
                        end
                    end
                end
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
            footer = sprintf(['<a href="matlab:disp(''Call dispAllProps method to see all properties'')">All Properties</a>,'...
                ' <a href="matlab:methods(%s)">Methods</a>'], cname);
        end
        
    end
    
    methods (Static)
        
        function doc(varargin)
            TE = IconsExtender();
            TE.doc(varargin{:})
        end
        
    end
end

