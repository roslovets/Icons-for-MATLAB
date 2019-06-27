classdef IconUtils < handle & matlab.mixin.CustomDisplay
    % Utilities class for work with icons
    % By Pavel Roslovets, ETMC Exponenta
    % https://github.com/roslovets/Icons-for-MATLAB
    
    properties
        Env = struct('Root', '', 'IconsDir', 'icons', 'DataDir', 'data',...
            'ColorsFile', 'html_colors.mat')
        Icons
        Colors
        Packs
        AllPacks
    end
    
    methods
        function obj = IconUtils()
            %ICONS Construct an instance of this class
            obj.getRoot();
            obj.getPacks();
            obj.getIcons();
            obj.getColors();
        end
        
        function lib(obj)
            %Open library
            winopen(obj.getIRoot());
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
        
    end
    
    
    methods (Hidden = true)
        
        function root = getRoot(obj)
            %Get toolbox root path
            root = fileparts(mfilename('fullpath'));
            obj.Env.Root = root;
        end
        
        function iroot = getIRoot(obj)
            %Get icon images root dir
            iroot = fullfile(obj.Env.Root, obj.Env.IconsDir);
        end
        
        function color = color2rgb(obj, color)
            % Convert color from RGB or text to hex format
            if ~isnumeric(color)
                if startsWith(color, '#')
                    color = obj.hex2rgb(color);
                elseif startsWith(color, '[') && endsWith(color, ']')
                    color = extractBetween(color, '[', ']');
                    color = str2num(color{1});
                else
                    colors = obj.Colors;
                    idx = colors.Name == lower(string(color));
                    if any(idx)
                        color = colors.Value{idx};
                        color = obj.hex2rgb(color);
                    else
                        error('Unknown color: %s', color);
                    end
                end
            elseif any(color > 1)
                color = color / 255;
            end
        end
        
        function color = hex2rgb(~, color)
            %Convert color from hex to 0-1 RGB
            c = [hex2dec(color(2:3)) hex2dec(color(4:5)) hex2dec(color(6:7))];
            color = c/255;
        end
        
        function color = rgb2hex(~, color)
            %Convert color from 0-1 RGB to hex
            color = round(color * 255);
            color = "#" + join(string(dec2hex(color, 2)), '');
        end
        
    end
    
    
    methods (Access = protected)
        
        function footer = getFooter(~)
            cname = mfilename('class');
            footer = sprintf('<a href="matlab:methods(%s)">Methods</a>', cname);
        end
    end
    
end

