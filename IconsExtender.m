classdef IconsExtender < handle
    % Contains core functions. Required for other classes and functionality
    % By Pavel Roslovets, ETMC Exponenta
    % https://github.com/ETMC-Exponenta/ToolboxExtender
    
    properties
        name % project name
        pname % name of project file
        type % type of project
        root % root dir
        remote % GitHub link
        vc % current installed version
        extv % Toolbox Extender version
    end
    
    properties (Hidden)
        config = 'ToolboxConfig.xml' % configuration file name
    end
    
    methods
        function obj = IconsExtender(root)
            % Init
            if nargin < 1
                obj.root = fileparts(mfilename('fullpath'));
            else
                obj.root = root;
            end
        end
        
        function set.root(obj, root)
            % Set root path
            obj.root = root;
            if ~obj.readconfig()
                obj.getpname();
                obj.gettype();
                obj.getname();
                obj.getremote();
            end
            obj.gvc();
        end
        
        function [vc, guid] = gvc(obj)
            % Get current installed version
            if obj.type == "toolbox"
                tbx = matlab.addons.toolbox.installedToolboxes;
                tbx = struct2table(tbx, 'AsArray', true);
                idx = strcmp(tbx.Name, obj.name);
                vcs = string(tbx.Version(idx));
                guid = tbx.Guid(idx);
                vc = '';
                for i = 1 : length(vcs)
                    if matlab.addons.isAddonEnabled(guid{i}, vcs(i))
                        vc = char(vcs(i));
                        break
                    end
                end
            else
                tbx = matlab.apputil.getInstalledAppInfo;
                vc = '';
                guid = '';
            end
            obj.vc = vc;
        end
        
        function res = install(obj, fpath)
            % Install toolbox or app
            if nargin < 2
                fpath = obj.getbinpath();
            end
            if obj.type == "toolbox"
                res = matlab.addons.install(fpath);
            else
                res = matlab.apputil.install(fpath);
            end
            obj.gvc();
            obj.echo('has been installed');
        end
        
        function uninstall(obj)
            % Uninstall toolbox or app
            [~, guid] = obj.gvc();
            if isempty(guid)
                disp('Nothing to uninstall');
            else
                guid = string(guid);
                for i = 1 : length(guid)
                    if obj.type == "toolbox"
                        matlab.addons.uninstall(char(guid(i)));
                    else
                        matlab.apputil.uninstall(char(guid(i)));
                    end
                end
                disp(obj.name + " was uninstalled");
                try
                    obj.gvc();
                end
            end
        end
        
        function doc(obj, name)
            % Open page from documentation
            if (nargin < 2) || isempty(name)
                name = 'GettingStarted';
            end
            if ~any(endsWith(name, {'.mlx' '.html'}))
                name = name + ".html";
            end
            docpath = fullfile(obj.root, 'doc', name);
            if endsWith(name, '.html')
                web(char(docpath));
            else
                open(char(docpath));
            end
        end
        
        function examples(obj)
            % cd to Examples dir
            expath = fullfile(obj.root, 'examples');
            cd(expath);
        end
        
        function web(obj)
            % Open GitHub page
            web(obj.remote, '-browser');
        end
        
        function addfav(obj, label, code, icon)
            % Add favorite
            favs = com.mathworks.mlwidgets.favoritecommands.FavoriteCommands.getInstance();
            nfav = com.mathworks.mlwidgets.favoritecommands.FavoriteCommandProperties();
            nfav.setLabel(label);
            nfav.setCategoryLabel(obj.name);
            nfav.setCode(code);
            if nargin > 3
                nfav.setIconPath(obj.root);
                nfav.setIconName(icon);
            end
            nfav.setIsOnQuickToolBar(true);
            favs.addCommand(nfav);
        end
        
        function rmfavs(obj)
            % Remove all favorites
            favs = com.mathworks.mlwidgets.favoritecommands.FavoriteCommands.getInstance();
            favs.removeCategory(obj.name)
        end
        
    end
    
    
    methods (Hidden)
        
        function echo(obj, msg)
            % Display service message
            fprintf('%s %s\n', obj.name, msg);
        end
        
        function name = getname(obj)
            % Get project name from project file
            name = '';
            ppath = obj.getppath();
            if isfile(ppath)
                txt = obj.readtxt(ppath);
                name = char(extractBetween(txt, '<param.appname>', '</param.appname>'));
            end
            obj.name = name;
        end
        
        function pname = getpname(obj)
            % Get project file name
            fs = dir(fullfile(obj.root, '*.prj'));
            if ~isempty(fs)
                names = {fs.name};
                isproj = false(1, length(names));
                for i = 1 : length(names)
                    txt = obj.readtxt(fullfile(obj.root, names{i}));
                    isproj(i) = ~contains(txt, '<MATLABProject');
                end
                if any(isproj)
                    names = names(isproj);
                    pname = names{1};
                    obj.pname = pname;
                else
                    %warning('Project file was not found in a current folder');
                end
            else
                %warning('Project file was not found in a current folder');
            end
        end
        
        function ppath = getppath(obj)
            % Get project file full path
            if ~isempty(obj.pname)
                ppath = fullfile(obj.root, obj.pname);
            else
                ppath = '';
            end
        end
        
        function type = gettype(obj)
            % Get project type (Toolbox/App)
            ppath = obj.getppath();
            txt = obj.readtxt(ppath);
            if contains(txt, 'plugin.toolbox')
                type = 'toolbox';
            elseif contains(txt, 'plugin.apptool')
                type = 'app';
            else
                type = '';
            end
            obj.type = type;
        end
        
        function remote = getremote(obj)
            % Get remote (GitHub) address via Git
            [~, cmdout] = system('git remote -v');
            remote = extractBetween(cmdout, 'https://', '.git', 'Boundaries', 'inclusive');
            if isempty(remote)
                remote = extractBetween(cmdout, 'https://', '(', 'Boundaries', 'inclusive');
                remote = strtrim(erase(remote, '('));
            end
            if ~isempty(remote)
                remote = remote(end);
            end
            remote = obj.cleargit(remote);
            obj.remote = remote;
        end
        
        function name = getvalidname(obj, cname)
            % Get valid variable name
            name = char(obj.name);
            name = name(isstrprop(name, 'alpha'));
            if nargin > 1
                name = char(name + string(cname));
            end
        end
        
        function txt = readtxt(~, fpath)
            % Read text from file
            if isfile(fpath)
                f = fopen(fpath, 'r', 'n', 'windows-1251');
                txt = fread(f, '*char')';
                fclose(f);
            else
                txt = '';
            end
        end
        
        function writetxt(~, txt, fpath)
            % Wtite text to file
            if isfile(fpath)
                fid = fopen(fpath, 'w', 'n', 'windows-1251');
                fwrite(fid, unicode2native(txt, 'windows-1251'));
                fclose(fid);
            end
        end
        
        function txt = txtrep(obj, fpath, old, new)
            % Replace in txt file
            txt = obj.readtxt(fpath);
            txt = replace(txt, old, new);
            obj.writetxt(txt, fpath);
        end
        
        function [bpath, bname] = getbinpath(obj)
            % Get generated binary file path
            [~, name] = fileparts(obj.pname);
            if obj.type == "toolbox"
                ext = ".mltbx";
            else
                ext = ".mlappinstall";
            end
            bname = name + ext;
            bpath = fullfile(obj.root, bname);
        end
        
        function ok = readconfig(obj)
            % Read config from xml file
            confpath = fullfile(obj.root, obj.config);
            ok = isfile(confpath);
            if ok
                xml = xmlread(confpath);
                conf = obj.getxmlitem(xml, 'config', 0);
                obj.name = obj.getxmlitem(conf, 'name');
                obj.pname = obj.getxmlitem(conf, 'pname');
                obj.type = obj.getxmlitem(conf, 'type');
                obj.remote = obj.cleargit(obj.getxmlitem(conf, 'remote'));
                obj.extv = obj.getxmlitem(conf, 'extv');
            end
        end
        
        function i = getxmlitem(~, xml, name, getData)
            % Get item from XML
            if nargin < 4
                getData = true;
            end
            i = xml.getElementsByTagName(name);
            i = i.item(0);
            if getData
                i = i.getFirstChild;
                if ~isempty(i)
                    i = i.getData;
                end
                i = char(i);
            end
        end
        
        function [nname, npath] = cloneclass(obj, classname, sourcedir, prename)
            % Clone Toolbox Extander class to current Project folder
            if nargin < 4
                prename = "Toolbox";
            end
            if nargin < 3
                sourcedir = pwd;
            end
            if nargin < 2
                classname = "Extender";
            else
                classname = lower(char(classname));
                classname(1) = upper(classname(1));
            end
            pname = obj.getvalidname;
            if isempty(pname)
                pname = 'Toolbox';
            end
            oname = string(prename) + classname;
            nname = pname + string(classname);
            npath = fullfile(obj.root, nname + ".m");
            opath = fullfile(sourcedir, oname + ".m");
            copyfile(opath, npath);
            obj.txtrep(npath, "obj = " + oname, "obj = " + nname);
            obj.txtrep(npath, "classdef " + oname, "classdef " + nname);
            obj.txtrep(npath, "obj.ext = IconsExtender", "obj.ext = " + obj.getvalidname + "Extender");
            obj.txtrep(npath, "upd = IconsUpdater", "upd = " + obj.getvalidname + "Updater");
        end
        
        function name = getselfname(~)
            % Get self class name
            name = mfilename('class');
        end
        
        function webrel(obj)
            % Open GitHub releases webpage
            web(obj.remote + "/releases", '-browser');
        end
        
        function repo = getrepo(obj)
            % Get repo string from remote URL
            repo = extractAfter(obj.remote, 'https://github.com/');
        end
        
        function url = getlatesturl(obj)
            % Get latest release URL
            url = obj.getapiurl() + "/releases/latest";
        end
        
        function url = getapiurl(obj)
            % Get GitHub API URL
            url = "https://api.github.com/repos/" + obj.getrepo();
        end
        
        function url = getrawurl(obj, fname)
            % Get GitHub raw source URL
            url = sprintf("https://raw.githubusercontent.com/%s/master/%s", obj.getrepo(), fname);
        end
        
    end
    
    methods (Hidden, Static)
        
        function remote = cleargit(remote)
            % Delete .git
            remote = char(remote);
            if endsWith(remote, '.git')
                remote = remote(1:end-4);
            end
        end
        
    end
end