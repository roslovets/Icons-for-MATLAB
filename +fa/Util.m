classdef Util
    %Utilities
    
    properties
        
    end
    
    methods (Static)
        function obj = Util()
            %Utilities
        end
        
        function [im, map, alpha] = imread(impath)
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
        
        function im = resize(im, size)
            %Change image size
            if numel(size) == 1
                size = [size size];
            end
            im = imresize(im, size, 'Method', 'bilinear');
        end
        
        function im = colorize(im, color)
            %Colorize image
            if ~isnumeric(color)
                if startsWith(color, '#')
                    color = fa.Util.hex2rgb(color);
                elseif startsWith(color, '[')
                    color = extractBetween(color, '[', ']');
                    color = str2num(color{1});
                else
                    color = fa.Util.color2rgb(color);
                end
            end
            color = color * 255;
            im(:,:,1) = color(1);
            im(:,:,2) = color(2);
            im(:,:,3) = color(3);
        end
        
        function color = hex2rgb(color)
            %Convert color from hex to 0-1 RGB
            c = [hex2dec(color(2:3)) hex2dec(color(4:5)) hex2dec(color(6:7))];
            color = c/255;
        end
        
        function color = color2rgb(color)
            %Convert color from name to 0-1 RGB
            colors = fa.Util.colors();
            idx = colors.name == lower(string(color));
            if any(idx)
                color = colors.value{idx};
                color = fa.Util.hex2rgb(color);
            else
                error('Unknown color: %s', color);
            end
        end
        
        function C = colors()
            %Load HTML colors
            res = load('html_colors.mat');
            colors = res.colors;
            C = table(colors.keys', colors.values');
            C.Properties.VariableNames = {'name', 'value'};
        end
        
        function showcolors()
            %Show HTML colors
            f = figure('Name', 'HTML Colors');
            a = axes(f);
            hold(a, 'on');
            colors = fa.Util.colors();
            n = colors.name;
            c = colors.value;
            c2 = [];
            ncols = 6;
            nrows = length(c) / ncols;
            for i = 1 : length(c)
                c2 = [c2; rgb2hsv( fa.Util.hex2rgb(c{i}))];
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
    
    methods (Static, Hidden=true)
        
        function imname = addpng(name)
            %Add .png to icon name
            if ~endsWith(name, '.png')
                imname = name + ".png";
            else
                imname = name;
            end
        end
        
        function name = rmpng(imname)
            %Remove .png from icon name
            imname = char(imname);
            if endsWith(imname, '.png')
                name = imname(1:end-4);
            else
                name = imname;
            end
        end
        
        function root = getroot()
            %Get toolbox root path
            root = fileparts(mfilename('fullpath'));
        end
        
        function root = getimroot()
            %Get icon images root dir
            root = fullfile(fa.Util.getroot(), '..', 'icons', 'FontAwesome-fa');
        end
        
        function impath = getpath(name)
            %Get image path
            impath = fullfile(fa.Util.getimroot(), fa.Util.addpng(name));
        end
        
    end
end

