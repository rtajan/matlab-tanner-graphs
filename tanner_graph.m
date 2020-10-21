classdef tanner_graph < handle
    % tanner_graph is a class for representing Tanner graphs from parity check matrices.
    
    properties
        interpreter = 'latex'    % Interpreter for display
        color = 'r'
        tikz_params = struct(... % Parameters Tikz export
            'backgound_color'         , 'white',...
            'variable_node_draw_color', 'blue',...
            'variable_node_fill_color', 'blue!30!white',...
            'check_node_draw_color'   , 'green!50!black',...
            'check_node_fill_color'   , 'green!30!white',...
            'edge_color'              , 'black',...
            'edge_width'              , '1pt'...
            );
    end
    
    properties(SetAccess = 'private', GetAccess = 'public')
        H
        
        variable_nbr
        check_nbr
        
        variable_statuses
        variable_names
        variable_keys
        
        check_statuses
        check_names
        check_keys
        
        graph_
        
        %end
        
        %properties(Access = 'private')
        axes
        
        node_styles
        node_labels
        
        xd
        yd
        
        h_vn
        h_vn_txt
        h_vn_egal
        
        h_pn
        h_pn_plus
        h_pn_txt
        
        node_menu
        edge_menu
        back_menu
        
        edge_table
        edge_lines
        
        selected_variables
        selected_checks
        
        selection_style
        
        last_click_pos
    end
    
    
    
    methods
        %% Constructor
        function obj = tanner_graph(H, variable_names, check_names)
            n = size(H,2);
            p = size(H,1);
            
            if nargin < 2 || isempty(variable_names)
                variable_names = cell(1,n);
                for i = 1:n
                    variable_names{i} = ['$x_{', num2str(i-1), '}$'];
                end
            end
            
            if ~iscell(variable_names) || numel(variable_names) ~= n
                warning('variable_names should be a cell of n (number of columns of H) names, default values are used instead.')
                variable_names = cell(1,n);
                for i = 1:n
                    variable_names{i} = ['$x_{', num2str(i-1), '}$'];
                end
            end
            
            variable_keys = cell(1,n);
            for i = 1:n
                variable_keys{i} = regexprep(variable_names{i},'[^a-zA-Z0-9]', '');
            end
            
            
            if nargin < 3 || isempty(check_names)
                check_names = cell(1,p);
                for i = 1:p
                    check_names{i} = ['$c_{', num2str(i-1), '}$'];
                end
            end
            
            if ~iscell(check_names) || numel(check_names) ~= p
                warning('check_names should be a cell of p (number of lines of H) names, default values are used instead.')
                check_names = cell(1,p);
                for i = 1:p
                    check_names{i} = ['$c_{', num2str(i - 1), '}$'];
                end
            end
            
            check_keys = cell(1,p);
            for i = 1:p
                check_keys{i} = regexprep(check_names{i},'[^a-zA-Z0-9]', '');
            end
            
            
            A = [[zeros(size(H,2)) H.'] ; [H zeros(size(H,1))]];
            obj.graph_ = graph(A);
            
            obj.H = H;
            obj.variable_names = variable_names;
            obj.variable_keys  = variable_keys;
            obj.check_names    = check_names;
            obj.check_keys     = check_keys;
            
            obj.variable_nbr = n;
            obj.check_nbr = p;
            
            obj.variable_statuses = zeros(1,size(H,2));
            obj.check_statuses    = zeros(1,size(H,1));
            obj.selected_variables = zeros(1,size(obj.H,2));
            obj.selected_checks = zeros(1,size(obj.H,1));
            
            obj.edge_table = zeros(nnz(obj.H), 2);
            [obj.edge_table(:,2), obj.edge_table(:,1)] = find(obj.H);
            
            obj.selection_style = 'new';
        end
        %%
        function add_check(obj)
            node_name = ['$c_{', num2str(obj.check_nbr), '}$'];
            new_key = regexprep(node_name,'[^a-zA-Z0-9]', '');
            while ~isempty(obj.find_check(new_key))
                obj.check_nbr = obj.check_nbr + 1;
                node_name = ['$c_{', num2str(obj.check_nbr), '}$'];
                new_key = regexprep(node_name,'[^a-zA-Z0-9]', '');
            end
            
            new_line = zeros(1,size(obj.H,2));
            
            obj.check_nbr = obj.check_nbr + 1;
            
            obj.check_names{numel(obj.check_names)+1} = node_name;
            obj.check_keys = [obj.check_keys, new_key];
            obj.check_statuses = [obj.check_statuses, 0];
            obj.selected_checks = [obj.selected_checks, 0];
            
            obj.H = [obj.H; new_line];
            A = [[zeros(size(obj.H,2)) obj.H.'] ; [obj.H zeros(size(obj.H,1))]];
            obj.graph_ = graph(A);
            
            chk_idx = size(obj.H,1);
            node_idx = chk_idx+size(obj.H,2);
            
            obj.xd = [obj.xd(1:node_idx-1) obj.last_click_pos(1) obj.xd(node_idx:end)];
            obj.yd = [obj.yd(1:node_idx-1) obj.last_click_pos(2) obj.yd(node_idx:end)];
            
            hold on
            p = plot(obj.xd(node_idx),obj.yd(node_idx), ...
                's','Color',[0,0.45,0.74],...
                'MarkerFaceColor',[0,0.45,0.74], ...
                'MarkerSize', 18, ...
                'XDataSource', ['obj.xd(obj.find_check(''' obj.check_keys{chk_idx} ''')+size(obj.H,2))'], ...
                'YDataSource', ['obj.yd(obj.find_check(''' obj.check_keys{chk_idx} ''')+size(obj.H,2))']);
            hold off
            obj.h_pn = [obj.h_pn {p}];
            ctxt_menu = uicontextmenu;
            obj.node_menu = [obj.node_menu(1:node_idx-1), {ctxt_menu}, obj.node_menu(node_idx:end)];
            
            uimenu(obj.node_menu{node_idx}, 'Label', 'color', 'Callback',@(~,~)obj.highlight(node_idx));
            uimenu(obj.node_menu{node_idx}, 'Label', 'delete', 'Callback',@(~,~)obj.delete_check(chk_idx));
            m = uimenu(obj.node_menu{node_idx}, 'Label', 'status');
            uimenu(m,'Text','Normal', 'Callback', @(~,~)obj.set_check_status(chk_idx, 0));
            uimenu(m,'Text','disabled', 'Callback', @(~,~)obj.set_check_status(chk_idx, 1));
            
            obj.h_pn_plus{chk_idx} = text(obj.xd(node_idx), obj.yd(node_idx),'+', 'EdgeColor',[1 1 0],'Color',[1 1 1],'FontSize',18, 'HorizontalAlignment','center', 'VerticalAlignment','middle','Interpreter',obj.interpreter,'UIContextMenu', obj.node_menu{node_idx},'Interruptible','off', 'PickableParts', 'all');
            obj.h_pn_txt{chk_idx} = text(obj.xd(node_idx), obj.yd(node_idx), obj.check_names{chk_idx}, 'FontSize',18, 'HorizontalAlignment','center', 'VerticalAlignment','bottom','Interpreter',obj.interpreter);
            obj.set_check_status(chk_idx, obj.check_statuses(chk_idx));
        end
        
        %%
        function add_variable(obj)
            node_name = ['$x_{', num2str(obj.variable_nbr), '}$'];
            new_key = regexprep(node_name,'[^a-zA-Z0-9]', '');
            while ~isempty(obj.find_variable(new_key))
                obj.variable_nbr = obj.variable_nbr + 1;
                node_name = ['$x_{', num2str(obj.check_nbr), '}$'];
                new_key = regexprep(node_name,'[^a-zA-Z0-9]', '');
            end
            
            new_column = zeros(size(obj.H,1),1);
            
            obj.variable_nbr = obj.variable_nbr + 1;
            obj.variable_names{numel(obj.variable_names)+1} = node_name;
            obj.variable_keys = [obj.variable_keys, new_key];
            obj.variable_statuses = [obj.variable_statuses, 0];
            obj.selected_variables= [obj.selected_variables, 0];
            
            obj.H = [obj.H, new_column];
            
            A = [[zeros(size(obj.H,2)) obj.H.'] ; [obj.H zeros(size(obj.H,1))]];
            
            obj.graph_ = graph(A);
            
            node_idx = size(obj.H,2);
            
            obj.xd = [obj.xd(1:node_idx-1) obj.last_click_pos(1) obj.xd(node_idx:end)];
            obj.yd = [obj.yd(1:node_idx-1) obj.last_click_pos(2) obj.yd(node_idx:end)];
            
            hold on
            p = plot(obj.xd(node_idx),obj.yd(node_idx), ...
                'o','Color',[0,0.45,0.74],...
                'MarkerFaceColor',[0,0.45,0.74], ...
                'MarkerSize', 18, ...
                'XDataSource', ['obj.xd(obj.find_variable(''' obj.variable_keys{node_idx} '''))'], ...
                'YDataSource', ['obj.yd(obj.find_variable(''' obj.variable_keys{node_idx} '''))']);
            hold off
            obj.h_vn = [obj.h_vn {p}];
            
            ctxt_menu = uicontextmenu;
            obj.node_menu = [obj.node_menu(1:node_idx-1), {ctxt_menu}, obj.node_menu(node_idx:end)];
            
            uimenu(obj.node_menu{node_idx}, 'Label', 'delete', 'Callback',@(~,~)obj.delete_variable(node_idx));
            m = uimenu(obj.node_menu{node_idx}, 'Label', 'status');
            uimenu(m,'Text','Normal', 'Callback', @(~,~)obj.set_variable_status(node_idx, 0));
            uimenu(m,'Text','Hidden', 'Callback', @(~,~)obj.set_variable_status(node_idx, 1));
            uimenu(m,'Text','Locked', 'Callback', @(~,~)obj.set_variable_status(node_idx, 3));
            uimenu(m,'Text','Frozen', 'Callback', @(~,~)obj.set_variable_status(node_idx, 2));
            
            uimenu(obj.node_menu{node_idx}, 'Label', 'color', 'Callback',@(~,~)obj.highlight(node_idx));
            
            obj.h_vn_egal{node_idx} = text(obj.xd(node_idx), obj.yd(node_idx), '\bf =', 'Color',[1, 1 ,1],'FontSize',16, 'HorizontalAlignment','center', 'VerticalAlignment','middle','Interpreter',obj.interpreter,'UIContextMenu', obj.node_menu{node_idx},'Interruptible','off', 'PickableParts', 'all');
            obj.h_vn_txt{node_idx}  = text(obj.xd(node_idx), obj.yd(node_idx), obj.variable_names{node_idx},'FontSize',20, 'HorizontalAlignment','center', 'VerticalAlignment','bottom','Interpreter',obj.interpreter);
            obj.set_variable_status(node_idx, obj.variable_statuses(node_idx));
        end
        
        %% Delete a check
        function delete_check(obj, chk_key)
            if ischar(chk_key)
                chk_idx = obj.find_check(chk_key);
                if isempty(chk_idx)
                    error(['No existing check node with key "' chk_key '".'])
                end
            elseif isscalar(chk_key)
                chk_idx = chk_key;
                if chk_key < 1 || chk_key > size(obj.H,1)
                    error(['No existing check node with index "' num2str(chk_key) '".'])
                end
            end
            
            obj.check_names = [obj.check_names(1:chk_idx-1) obj.check_names(chk_idx+1:end)];
            obj.check_keys = [obj.check_keys(1:chk_idx-1) obj.check_keys(chk_idx+1:end)];
            obj.check_statuses = [obj.check_statuses(1:chk_idx-1) obj.check_statuses(chk_idx+1:end)];
            obj.selected_checks = [obj.selected_checks(1:chk_idx-1) obj.selected_checks(chk_idx+1:end)];
            
            node_idx = size(obj.H,2) + chk_idx;
            obj.node_menu = [obj.node_menu(1:node_idx-1) obj.node_menu(node_idx+1:end)];
            neighbors = find(obj.H(chk_idx,:));
            for v_ = 1:length(neighbors)
                edge_idx = find((obj.edge_table(:,1) == neighbors(v_)) & (obj.edge_table(:,2) == chk_idx));
                obj.edge_menu{edge_idx}.delete;
                obj.edge_menu = [obj.edge_menu(1:edge_idx-1), obj.edge_menu(edge_idx+1:end)];
                obj.edge_lines{edge_idx}.delete;
                obj.edge_lines = [obj.edge_lines(1:edge_idx-1), obj.edge_lines(edge_idx+1:end)];
                obj.edge_table(edge_idx,:) = [];
            end
            
            obj.edge_table(obj.edge_table(:,2) > chk_idx, 2) = obj.edge_table(obj.edge_table(:,2) > chk_idx, 2) - 1;
            
            obj.h_pn{chk_idx}.delete();
            obj.h_pn = [obj.h_pn(1:chk_idx-1), obj.h_pn(chk_idx+1:end)];
            
            obj.h_pn_plus{chk_idx}.delete();
            obj.h_pn_plus = [obj.h_pn_plus(1:chk_idx-1), obj.h_pn_plus(chk_idx+1:end)];
            
            obj.h_pn_txt{chk_idx}.delete();
            obj.h_pn_txt = [obj.h_pn_txt(1:chk_idx-1), obj.h_pn_txt(chk_idx+1:end)];
            
            obj.H(chk_idx,:) = [];
            A = [[zeros(size(obj.H,2)) obj.H.'] ; [obj.H zeros(size(obj.H,1))]];
            obj.graph_ = graph(A);
            
            obj.xd(node_idx) = [];
            obj.yd(node_idx) = [];
            
            %            obj.plot('XData',x,'YData',y);
        end
        
        %% Delete a variable
        function delete_variable(obj, var_key)
            if ischar(var_key)
                var_idx = obj.find_variable(var_key);
                if isempty(var_idx)
                    error(['No existing variable node with key "' var_key '".'])
                end
            elseif isscalar(var_key)
                var_idx = var_key;
                if var_key < 1 || var_key > size(obj.H,2)
                    error(['No existing variable node with index "' num2str(var_key) '".'])
                end
            end
            
            obj.variable_names = [obj.variable_names(1:var_idx-1) obj.variable_names(var_idx+1:end)];
            obj.variable_keys = [obj.variable_keys(1:var_idx-1) obj.variable_keys(var_idx+1:end)];
            obj.variable_statuses = [obj.variable_statuses(1:var_idx-1) obj.variable_statuses(var_idx+1:end)];
            obj.selected_variables= [obj.selected_variables(1:var_idx-1) obj.selected_variables(var_idx+1:end)];
            obj.node_menu = [obj.node_menu(1:var_idx-1) obj.node_menu(var_idx+1:end)];
            neighbors = find(obj.H(:,var_idx));
            for c_ = 1:length(neighbors)
                edge_idx = find((obj.edge_table(:,1) == var_idx) & (obj.edge_table(:,2) == neighbors(c_)));
                obj.edge_menu{edge_idx}.delete;
                obj.edge_menu = [obj.edge_menu(1:edge_idx-1), obj.edge_menu(edge_idx+1:end)];
                obj.edge_lines{edge_idx}.delete;
                obj.edge_lines = [obj.edge_lines(1:edge_idx-1), obj.edge_lines(edge_idx+1:end)];
                obj.edge_table(edge_idx,:) = [];
            end
            
            obj.edge_table(obj.edge_table(:,1) > var_idx, 1) = obj.edge_table(obj.edge_table(:,1) > var_idx, 1) - 1;
            
            obj.h_vn{var_idx}.delete();
            obj.h_vn = [obj.h_vn(1:var_idx-1), obj.h_vn(var_idx+1:end)];
            
            obj.h_vn_egal{var_idx}.delete();
            obj.h_vn_egal = [obj.h_vn_egal(1:var_idx-1), obj.h_vn_egal(var_idx+1:end)];
            
            obj.h_vn_txt{var_idx}.delete();
            obj.h_vn_txt = [obj.h_vn_txt(1:var_idx-1), obj.h_vn_txt(var_idx+1:end)];
            
            obj.H(:,var_idx) = [];
            A = [[zeros(size(obj.H,2)) obj.H.'] ; [obj.H zeros(size(obj.H,1))]];
            obj.graph_ = graph(A);
            
            obj.xd(var_idx) = [];
            obj.yd(var_idx) = [];
        end
        
        %% Find a check
        function chk_idx = find_check(obj,node_key)
            index = cellfun(@(x) strcmp(x,node_key), obj.check_keys, 'UniformOutput', 1);
            chk_idx = find(index,1);
        end
        
        %% Find a variable
        function var_idx = find_variable(obj,node_key)
            index = cellfun(@(x) strcmp(x,node_key), obj.variable_keys, 'UniformOutput', 1);
            var_idx = find(index,1);
        end
        
        %% Plot the graph_
        function plot(obj, varargin)
            % Plots the underlying tanner_graph and returns the object.
            
            n = size(obj.H,2);
            p = size(obj.H,1);
            
            obj.node_styles  = cell(1,n+p);
            obj.node_labels = cell(1,n+p);
            
            for i = 1:n
                obj.node_styles{i} = 'o';
                obj.node_labels{i} = ' ';
            end
            
            for i = n+1:n+p
                obj.node_styles{i} = 's';
                obj.node_labels{i} = ' ';
            end
            
            
            hdl = plot(obj.graph_, varargin{:});
            obj.axes = gca;
            this_fig = gcf;
            
            obj.back_menu = uicontextmenu;
            uimenu(obj.back_menu, 'Label', 'Add variable', 'Callback',@(~,~)obj.add_variable);
            uimenu(obj.back_menu, 'Label', 'Add check', 'Callback',@(~,~)obj.add_check);
            uimenu(obj.back_menu, 'Label', 'Delete selection', 'Enable','off');
            
            set(gca,'uicontextmenu',obj.back_menu)
            obj.xd = get(hdl, 'XData');
            obj.yd = get(hdl, 'YData');
            
            current_xlim = get(gca,'XLim');
            current_ylim = get(gca,'YLim');
            
            delta_xlim = current_xlim(2)-current_xlim(1);
            delta_ylim = current_ylim(2)-current_ylim(1);
            
            hdl.delete;
            
            end_nodes = obj.graph_.Edges.EndNodes;
            edge_nbr = size(end_nodes,1);
            obj.edge_menu = cell(1,edge_nbr);
            obj.edge_lines = cell(1,edge_nbr);
            for edge_idx = 1:edge_nbr
                obj.edge_menu{edge_idx} = uicontextmenu;
                uimenu(obj.edge_menu{edge_idx}, 'Label', 'delete', 'Callback',@obj.delete_edge_callback, 'Tag',[obj.variable_keys{obj.edge_table(edge_idx,1)}, ' ', obj.check_keys{obj.edge_table(edge_idx,2)}]);
                
                obj.edge_lines{edge_idx} = line([obj.xd(end_nodes(edge_idx,1)) obj.xd(end_nodes(edge_idx,2))],...
                    [obj.yd(end_nodes(edge_idx,1)) obj.yd(end_nodes(edge_idx,2))],...
                    'Color',[0,0.45,0.74],...
                    'Visible','on',...
                    'PickableParts', 'all',...
                    'UIContextMenu', obj.edge_menu{edge_idx});
            end
            
            obj.h_vn      = cell(1,n);
            obj.h_vn_txt  = cell(1,n);
            obj.h_vn_egal = cell(1,n);
            
            obj.h_pn      = cell(1,p);
            obj.h_pn_plus = cell(1,p);
            obj.h_pn_txt  = cell(1,p);
            
            obj.node_menu = cell(1,n+p);
            hold on;
            
            for v_ = 1:n
                obj.h_vn{v_} = plot(obj.xd(v_),obj.yd(v_), ...
                    'o','Color',[0,0.45,0.74],...
                    'MarkerFaceColor',[0,0.45,0.74], ...
                    'MarkerSize', 18, ...
                    'XDataSource', ['obj.xd(obj.find_variable(''' obj.variable_keys{v_} '''))'], ...
                    'YDataSource', ['obj.yd(obj.find_variable(''' obj.variable_keys{v_} '''))']);
            end
            
            for p_ = 1:p
                n_ = p_ + size(obj.H,2);
                obj.h_pn{p_} = plot(obj.xd(n_),obj.yd(n_), ...
                    's','Color',[0,0.45,0.74],...
                    'MarkerFaceColor',[0,0.45,0.74], ...
                    'MarkerSize', 18, ...
                    'XDataSource', ['obj.xd(obj.find_check(''' obj.check_keys{p_} ''')+size(obj.H,2))'], ...
                    'YDataSource', ['obj.yd(obj.find_check(''' obj.check_keys{p_} ''')+size(obj.H,2))']);
            end
            hold off
            
            set(gca,'XLim', [current_xlim(1) - 0.2*delta_xlim, current_xlim(2) + 0.2*delta_xlim]);
            set(gca,'YLim', [current_ylim(1) - 0.2*delta_ylim, current_ylim(2) + 0.2*delta_ylim]);
            
            for i = 1:n
                obj.node_menu{i} = uicontextmenu;
                
                uimenu(obj.node_menu{i}, 'Label', 'delete', 'Callback', @obj.delete_variable_callback,'Tag',obj.variable_keys{i});
                m = uimenu(obj.node_menu{i}, 'Label', 'status');
                uimenu(m,'Text','Normal', 'Callback', @obj.set_vn_status_callback, 'Tag',[obj.variable_keys{i} ' normal' ]);
                uimenu(m,'Text','Hidden', 'Callback', @obj.set_vn_status_callback, 'Tag',[obj.variable_keys{i} ' hidden' ]);
                uimenu(m,'Text','Locked', 'Callback', @obj.set_vn_status_callback, 'Tag',[obj.variable_keys{i} ' locked' ]);
                uimenu(m,'Text','Frozen', 'Callback', @obj.set_vn_status_callback, 'Tag',[obj.variable_keys{i} ' frozen' ]);
                
                uimenu(obj.node_menu{i}, 'Label', 'color', 'Callback',@obj.highlight,'Tag',obj.variable_keys{i});
                
                obj.h_vn_egal{i} = text(obj.xd(i), obj.yd(i), '\bf =', 'Color',[1, 1 ,1],'FontSize',16, 'HorizontalAlignment','center', 'VerticalAlignment','middle','Interpreter',obj.interpreter,'UIContextMenu', obj.node_menu{i},'Interruptible','off', 'PickableParts', 'all');
                obj.h_vn_txt{i}  = text(obj.xd(i), obj.yd(i), obj.variable_names{i},'FontSize',20, 'HorizontalAlignment','center', 'VerticalAlignment','bottom','Interpreter',obj.interpreter);
                obj.set_variable_status(i, obj.variable_statuses(i));
            end
            for i = 1:p
                obj.node_menu{i+n} = uicontextmenu;
                uimenu(obj.node_menu{i+n}, 'Label', 'color', 'Callback',@obj.highlight,'Tag',obj.check_keys{i});
                uimenu(obj.node_menu{i+n}, 'Label', 'delete', 'Callback',@obj.delete_check_callback,'Tag',obj.check_keys{i});
                m = uimenu(obj.node_menu{i+n}, 'Label', 'status');
                uimenu(m,'Text','Normal', 'Callback', @(~,~)obj.set_check_status(i, 0));
                uimenu(m,'Text','disabled', 'Callback', @(~,~)obj.set_check_status(i, 1));
                
                obj.h_pn_plus{i} = text(obj.xd(i+n), obj.yd(i+n),'+','Color',[1 1 1],'FontSize',18, 'HorizontalAlignment','center', 'VerticalAlignment','middle','Interpreter',obj.interpreter,'UIContextMenu', obj.node_menu{i+n},'Interruptible','off', 'PickableParts', 'all');
                obj.h_pn_txt{i} = text(obj.xd(i+n), obj.yd(i+n), obj.check_names{i}, 'FontSize',18, 'HorizontalAlignment','center', 'VerticalAlignment','bottom','Interpreter',obj.interpreter);
                obj.set_check_status(i, obj.check_statuses(i));
            end
            set(this_fig,'WindowButtonDownFcn',@obj.edit_graph);
            set(this_fig,'KeyPressFcn',@obj.key_press_callback);
            set(this_fig,'KeyReleaseFcn',@obj.key_release_callback);
            set(this_fig,'DeleteFcn',@(~,~)obj.reset_selection);
            obj.reset_selection;
        end
        
        %% Add edge
        function add_edge(obj,node1_idx,node2_idx)
            var_idx = min(node1_idx,node2_idx);
            chk_idx = max(node1_idx,node2_idx) - size(obj.H,2);
            
            if chk_idx > 0 && var_idx <= size(obj.H,2)
                if obj.H(chk_idx, var_idx) == 0
                    obj.H(chk_idx, var_idx) = 1;
                    A = [[zeros(size(obj.H,2)) obj.H.'] ; [obj.H zeros(size(obj.H,1))]];
                    obj.graph_ = graph(A);
                    obj.edge_table = [obj.edge_table; [var_idx, chk_idx]];
                    edge_idx = size(obj.edge_table,1);
                    obj.edge_menu = [obj.edge_menu, {uicontextmenu}];
                    uimenu(obj.edge_menu{edge_idx}, 'Label', 'delete', 'Callback',@(~,~)obj.delete_edge(edge_idx));
                    edge = line([obj.xd(var_idx), obj.xd(chk_idx + size(obj.H,2))],...
                        [obj.yd(var_idx) obj.yd(chk_idx + size(obj.H,2))],...
                        'Color',[0,0.45,0.74],...
                        'Visible','on',...
                        'PickableParts', 'all',...
                        'UIContextMenu', obj.edge_menu{edge_idx});
                    obj.edge_lines = [obj.edge_lines, {edge}];
                    uistack(edge, 'bottom');
                end
            end
        end
        
        %% Delete edge
        function delete_edge(obj,edge_idx)
            var_idx = obj.edge_table(edge_idx,1);
            chk_idx = obj.edge_table(edge_idx,2);
            
            if chk_idx > 0 && var_idx <= size(obj.H,2)
                
                obj.H(chk_idx, var_idx) = 0;
                A = [[zeros(size(obj.H,2)) obj.H.'] ; [obj.H zeros(size(obj.H,1))]];
                obj.graph_ = graph(A);
                
                obj.edge_table(edge_idx,:) = [];
                
                obj.edge_menu{edge_idx}.delete;
                obj.edge_menu = [obj.edge_menu(1:edge_idx-1), obj.edge_menu(edge_idx+1:end)];
                obj.edge_lines{edge_idx}.delete;
                obj.edge_lines = [obj.edge_lines(1:edge_idx-1), obj.edge_lines(edge_idx+1:end)];
            end
        end
        
        function edge_idx = find_edge(obj,vn_idx,cn_idx)
            edge_idx = find((obj.edge_table(:,1) == vn_idx) & (obj.edge_table(:,2) == cn_idx));
        end
        %% layout
        function layout(obj,varargin)
            % layout is a wrapper to call the @layout function for the @PlotGraph
            % object underlying the tanner_graph object
            n = size(obj.H,2);
            p = size(obj.H,1);
            hold on
            set(gca,'XLimMode','auto')
            set(gca,'YLimMode','auto')
            
            hdl = plot(gca, obj.graph_, 'XData', obj.xd, 'YData', obj.yd, 'Visible','on');
            hold off
            layout(hdl,varargin{:});
            
            obj.xd = get(hdl, 'XData');
            obj.yd = get(hdl, 'YData');
            
            refreshdata(obj.h_vn, 'caller')
            refreshdata(obj.h_pn, 'caller')
            
            for i = 1:n
                obj.h_vn_egal{i}.Position = [obj.xd(i), obj.yd(i)];
                obj.h_vn_txt{i}.Position = [obj.xd(i), obj.yd(i)];
            end
            for i = 1:p
                obj.h_pn_plus{i}.Position = [obj.xd(n+i), obj.yd(n+i)];
                obj.h_pn_txt{i}.Position = [obj.xd(n+i), obj.yd(n+i)];
            end
            for edge_idx = 1:size(obj.edge_table,1)
                obj.edge_lines{edge_idx}.XData = [obj.xd(obj.edge_table(edge_idx,1)) obj.xd(obj.edge_table(edge_idx,2)+n)];
                obj.edge_lines{edge_idx}.YData = [obj.yd(obj.edge_table(edge_idx,1)) obj.yd(obj.edge_table(edge_idx,2)+n)];
            end
            
            hdl.delete;
            current_xlim = get(gca,'XLim');
            current_ylim = get(gca,'YLim');
            delta_xlim = current_xlim(2)-current_xlim(1);
            delta_ylim = current_ylim(2)-current_ylim(1);
            set(gca,'XLim', [current_xlim(1) - 0.2*delta_xlim, current_xlim(2) + 0.2*delta_xlim]);
            set(gca,'YLim', [current_ylim(1) - 0.2*delta_ylim, current_ylim(2) + 0.2*delta_ylim]);
        end
        
        %% highlight
        function highlight(obj, src, ~)
            vn_idx = obj.find_variable(src.Tag);
            cn_idx = obj.find_check(src.Tag);
            
            if ~isempty(vn_idx)
                c = uisetcolor('Select a color');
                if ~isequal(c,0)
                    node_connected_edges = find(obj.edge_table(:,1)==vn_idx);
                    set(obj.h_vn{vn_idx},'MarkerFaceColor',c);
                    set(obj.h_vn{vn_idx},'Color',c);
                    for edge_ = node_connected_edges(:).'
                        set(obj.edge_lines{edge_},'Color',c);
                    end
                end
            elseif ~isempty(cn_idx)
                c = uisetcolor('Select a color');
                if ~isequal(c,0)
                    node_connected_edges = find(obj.edge_table(:,2)==cn_idx);
                    set(obj.h_pn{cn_idx},'Color',c);
                    set(obj.h_pn{cn_idx},'MarkerFaceColor',c);
                    for edge_ = node_connected_edges(:).'
                        set(obj.edge_lines{edge_},'Color',c);
                    end
                end
            else
                error('Unknown node');
            end
            
        end
        
        %% Set variable status
        function set_variable_status(obj, var_idx, status)
            
            switch status
                case 0
                    c = [0,0.45,0.74];
                case 1
                    c = [0.47,0.67,0.19];
                case 2
                    c = [0.47,0.67,0.19];
                case 3
                    c = [0.85,0.33,0.1];
                otherwise
                    error('Unknown variable status');    
            end
            
            obj.variable_statuses(var_idx) = status;
            node_connected_edges = find(obj.edge_table(:,1)==var_idx);
            set(obj.h_vn{var_idx},'MarkerFaceColor',c);
            set(obj.h_vn{var_idx},'Color',c);
            for edge_ = node_connected_edges(:).'
                %if obj.variable_statuses(obj.edge_table(edge_,1)) > obj.check_statuses(obj.edge_table(edge_,2))
                set(obj.edge_lines{edge_},'Color',c);
                %end
            end
        end
        
        %% Set check status
        function set_check_status(obj, chk_key, status)
            if ischar(chk_key)
                chk_idx = obj.find_check(chk_key);
                if isempty(chk_idx)
                    error(['No existing check node with key "' chk_key '".'])
                end
            elseif isscalar(chk_key)
                chk_idx = chk_key;
                if chk_key < 1 || chk_key > size(obj.H,1)
                    error(['No existing check node with index "' num2str(chk_key) '".'])
                end
            end
            
            switch status
                case 0
                    c = [0,0.45,0.74];
                case 1
                    c = [0.74,0.89,1];
                otherwise
                    error('Unknown check status');
                    
            end
            
            obj.check_statuses(chk_idx) = status;
            node_connected_edges = find(obj.edge_table(:,2)==chk_idx);
            set(obj.h_pn{chk_idx},'Color',c);
            set(obj.h_pn{chk_idx},'MarkerFaceColor',c);
            for edge_ = node_connected_edges(:).'
                set(obj.edge_lines{edge_},'Color',c);
            end
        end
        
        %% to_tikz
        function to_tikz(obj,file_name)
            % to_tikz writes the Tanner graph_ display into a tex file
            % using tikz language for drawing
            
            n = size(obj.H,2);
            p = size(obj.H,1);
            
            %
            FID = fopen(file_name,'w');
            
            PREAMBULE = '\\documentclass[tikz]{standalone}\n\\usepackage{pgfplots}\n\\usepackage{grffile}\n\\usepackage{pgfplots,tikz}\n\\usetikzlibrary{shapes,decorations,arrows,positioning,fit}\n\\pgfplotsset{compat=newest}\n\n\\begin{document}\n';
            COLORB_GND = ['\\pagecolor{',obj.tikz_params.backgound_color,'}\n\n'];
            
            BEGIN_TIKZ = '\\begin{tikzpicture} \n';
            
            VARIABLE_NODE_STYLE = '\\tikzset{variable_node_style/.style={circle,draw=VARIABLE_NODE_DRAW_COLOR,fill=VARIABLE_NODE_FILL_COLOR, inner sep = 0.1pt}};\n';
            VARIABLE_NODE = '\\node [variable_node_style, label=above:{%s}] (x%d) at (%f,%f) {$=$};\n';
            
            CHECK_NODE_STYLE = '\\tikzset{check_node_style/.style={regular polygon,regular polygon sides=4,draw=CHECK_NODE_DRAW_COLOR,fill=CHECK_NODE_FILL_COLOR, inner sep = 0.1pt}};\n';
            CHECK_NODE = '\\node [check_node_style,label=above:{%s}] (c%d) at (%f,%f) {$+$};\n';
            
            EDGE_STYLE = '\\tikzset{edge_style/.style={draw=EDGE_COLOR,line width=EDGE_WIDTH }};\n';
            EDGE = '\\path [edge_style] (x%d) -- (c%d);\n';
            
            END_TIKZ = '\\end{tikzpicture}\n';
            END_DOC = ' \\end{document}';
            
            VARIABLE_NODE_STYLE = strrep(VARIABLE_NODE_STYLE,'VARIABLE_NODE_DRAW_COLOR',obj.tikz_params.variable_node_draw_color);
            VARIABLE_NODE_STYLE = strrep(VARIABLE_NODE_STYLE,'VARIABLE_NODE_FILL_COLOR',obj.tikz_params.variable_node_fill_color);
            
            CHECK_NODE_STYLE    = strrep(CHECK_NODE_STYLE,   'CHECK_NODE_DRAW_COLOR'   ,obj.tikz_params.check_node_draw_color);
            CHECK_NODE_STYLE    = strrep(CHECK_NODE_STYLE,   'CHECK_NODE_FILL_COLOR'   ,obj.tikz_params.check_node_fill_color);
            
            
            EDGE_STYLE = strrep(EDGE_STYLE,'EDGE_COLOR',obj.tikz_params.edge_color);
            EDGE_STYLE = strrep(EDGE_STYLE,'EDGE_WIDTH',obj.tikz_params.edge_width);
            
            
            %
            fprintf(FID, PREAMBULE);
            fprintf(FID,COLORB_GND);
            fprintf(FID,BEGIN_TIKZ);
            fprintf(FID, '\n%% Style definitions\n');
            fprintf(FID, VARIABLE_NODE_STYLE);
            fprintf(FID, CHECK_NODE_STYLE);
            fprintf(FID, EDGE_STYLE);
            
            fprintf(FID, '\n%% Variable Nodes\n');
            
            for vn = 1:n
                fprintf(FID, VARIABLE_NODE, obj.variable_names{vn}, vn, obj.xd(vn)*2, obj.yd(vn)*2);
            end
            
            fprintf(FID, '\n%% Check Nodes\n');
            for cn = 1:p
                fprintf(FID, CHECK_NODE, obj.check_names{cn}, cn, obj.xd(cn+n)*2, obj.yd(cn+n)*2);
            end
            
            fprintf(FID, '\n%% Edges\n');
            for vn = 1:n
                for cn = 1:p
                    if obj.H(cn,vn) == 1
                        fprintf(FID, EDGE, vn, cn);
                    end
                end
            end
            
            fprintf(FID, END_TIKZ);
            
            fprintf(FID, END_DOC);
            fclose(FID);
            
        end
        
        function vn_pos_x = get_variable_xd(obj)
            vn_pos_x = obj.xd(1:size(obj.H,2));
        end
        
        function vn_pos_y = get_variable_yd(obj)
            vn_pos_y = obj.yd(1:size(obj.H,2));
        end
        
        function cn_pos_x = get_check_xd(obj)
            cn_pos_x = obj.xd(size(obj.H,2) + (1:size(obj.H,1)));
        end
        
        function cn_pos_y = get_check_yd(obj)
            cn_pos_y = obj.yd(size(obj.H,2) + (1:size(obj.H,1)));
        end
    end
    
    methods (Access = protected)
        
               %% Set variable status
        function set_vn_status_callback(obj, src, ~)
            newStr = split(src.Tag,' ');
            var_idx = obj.find_variable(newStr{1});
            status_str = newStr{2};
            
            if strcmp(status_str,'normal')
                obj.set_variable_status(var_idx,0);
            elseif strcmp(status_str,'hidden')
                obj.set_variable_status(var_idx,1);
            elseif strcmp(status_str,'locked')
                obj.set_variable_status(var_idx,2);
            elseif strcmp(status_str,'frozen')
                obj.set_variable_status(var_idx,3);
            else
                error('Unknown status for a variable node.')
            end                
        end
        
        function delete_variable_callback(obj,src,~)
            obj.delete_variable(src.Tag);
        end
        
        function delete_check_callback(obj,src,~)
            obj.delete_check(src.Tag);
        end
        
        function delete_edge_callback(obj,src,~)
            newStr = split(src.Tag,' ');
            vn_idx = obj.find_variable(newStr{1});
            cn_idx = obj.find_check(newStr{2});
            
            edge_idx = obj.find_edge(vn_idx,cn_idx);
            
            obj.delete_edge(edge_idx);
            
        end
        
        function key_press_callback(obj, ~, event)
            pressed_modifier = {event.Modifier{:}};
            if any(strcmp(pressed_modifier, 'control') | strcmp(pressed_modifier, 'command'))
                obj.selection_style = 'add';
            end
        end
        
        function key_release_callback(obj, ~, ~)
            if strcmp(obj.selection_style, 'add')
                obj.selection_style = 'new';
            end
        end
        
        %% edit_graph
        function edit_graph(obj,source, eventdata)
            % For moving nodes whithin the Tanner graph_ plot
            a = obj.axes;
            pt = a.CurrentPoint(1,1:2);
            obj.last_click_pos = pt;
            
            if strcmp(eventdata.Source.SelectionType, 'alt')
                obj.reset_selection();
                return;
            end
            
            dx = obj.xd - pt(1);%obj.plot_handler.XData
            dy = obj.yd - pt(2);%obj.plot_handler.YData
            len = sqrt(dx.^2/diff(a.XLim).^2 + dy.^2/diff(a.YLim).^2);
            [lmin,idx] = min(len);
            
            tol = 1/30;
            
            if lmin > tol || isempty(idx)
                source.WindowButtonMotionFcn = @rbbox_motion_fcn;
                source.WindowButtonUpFcn     = @rbbox_release_fcn;
                temp_selected_variables = zeros(1, size(obj.H,2));
                temp_selected_checks = zeros(1, size(obj.H,1));
                if strcmp(obj.selection_style,'add')
                    temp_selection_style = 'add';
                else
                    temp_selection_style = 'new';
                end
                temp_rect = rectangle('Position',[pt(1), pt(2), 0 , 0],'Curvature',0.2, 'LineWidth', 2, 'FaceColor',[0.5 0 1,0.1], 'EdgeColor',[0 0 1],'LineStyle','--');
                return
            end
            node = idx(1);
            
            if node > size(obj.H,2)
                if ~obj.selected_checks(node-size(obj.H,2))
                    if strcmp(obj.selection_style,'new')
                        obj.reset_selection();
                    end
                    obj.selected_checks(node-size(obj.H,2)) = 1;
                    obj.h_pn_plus{node-size(obj.H,2)}.EdgeColor = [1 0 0];
                    
                else
                    if strcmp(obj.selection_style,'add')
                        obj.selected_checks(node-size(obj.H,2)) = 0;
                        obj.h_pn_plus{node-size(obj.H,2)}.EdgeColor = 'none';
                    end
                end
            else
                if ~obj.selected_variables(node)
                    if strcmp(obj.selection_style,'new')
                        obj.reset_selection();
                    end
                    obj.selected_variables(node) = 1;
                    obj.h_vn_egal{node}.EdgeColor = [1 0 0];
                else
                    if strcmp(obj.selection_style,'add')
                        obj.selected_variables(node) = 0;
                        obj.h_vn_egal{node}.EdgeColor = 'none';
                    end
                end
            end
            
            if strcmp(eventdata.Source.SelectionType, 'normal')
                oldx = obj.xd(node);
                oldy = obj.yd(node);
                vnd_list  = find(obj.selected_variables);
                cnd_list  = find(obj.selected_checks);
                edge_list = zeros(1,size(obj.edge_table,1));
                for edge_idx = 1:length(edge_list)
                    edge_list(edge_idx) = any(obj.edge_table(edge_idx,1) == vnd_list) | any(obj.edge_table(edge_idx,2) == cnd_list);
                end
                edge_list = find(edge_list);
                edge_ends = mat2cell([obj.edge_table(edge_list(:),1), obj.edge_table(edge_list(:),2) + size(obj.H,2)],ones(1,length(edge_list)),2)';
                edge_cell = obj.edge_lines(edge_list);
                node_cell = [obj.h_vn_txt(vnd_list), obj.h_vn_egal(vnd_list),obj.h_pn_txt(cnd_list),obj.h_pn_plus(cnd_list)];
                nde_list = [vnd_list, cnd_list + size(obj.H,2)];
                node_plot_cell = [obj.h_vn(vnd_list), obj.h_pn(cnd_list)];
                vec_delta = zeros(1,3);
                %source.BusyAction = 'cancel';
                source.WindowButtonMotionFcn = @node_motion_fcn;
                source.WindowButtonUpFcn     = @node_release_fcn;
            elseif strcmp(eventdata.Source.SelectionType, 'extend')
                temp_edge = line([pt(1),pt(1)], [pt(2),pt(2)]);
                source.WindowButtonMotionFcn = @edge_motion_fcn;
                source.WindowButtonUpFcn     = @edge_release_fcn;
            else
                return;
            end
            
            function edge_motion_fcn(~,~)
                newx = a.CurrentPoint(1,1);
                newy = a.CurrentPoint(1,2);
                temp_edge.XData = [pt(1), newx];
                temp_edge.YData = [pt(2), newy];
                drawnow;
            end
            function edge_release_fcn(~,~)
                
                pt = a.CurrentPoint(1,1:2);
                
                dx = obj.xd - pt(1);%obj.plot_handler.XData
                dy = obj.yd - pt(2);%obj.plot_handler.YData
                len = sqrt(dx.^2/diff(a.XLim).^2 + dy.^2/diff(a.YLim).^2);
                [lmin,idx] = min(len);
                                
                if lmin < tol && ~isempty(idx)
                    node2 = idx(1);
                    obj.add_edge(node, node2);
                end
                
                source.WindowButtonMotionFcn = [];
                source.WindowButtonUpFcn = [];
                delete(temp_edge)
                drawnow;
            end
            
            function node_motion_fcn(~,~)
                newx = a.CurrentPoint(1,1);
                newy = a.CurrentPoint(1,2);
                deltax = newx - oldx;
                deltay = newy - oldy;
                vec_delta(1) = deltax;
                vec_delta(2) = deltay;
                
                obj.xd(nde_list) = obj.xd(nde_list) + deltax;
                obj.yd(nde_list) = obj.yd(nde_list) + deltay;
                
                cellfun(@(x)set(x,'Position', x.Position + vec_delta), node_cell);
                cellfun(@(x,y) set(x,'XData',obj.xd(y)),edge_cell, edge_ends);
                cellfun(@(x,y) set(x,'YData',obj.yd(y)),edge_cell, edge_ends);
                
                oldx = newx;
                oldy = newy;
                refreshdata(node_plot_cell,'caller');
                drawnow limitrate;
            end
            function node_release_fcn(~,~)
                source.WindowButtonMotionFcn = [];
                source.WindowButtonUpFcn = [];
            end
            
            function rbbox_motion_fcn(~,~)
                pt2 = a.CurrentPoint(1,1:2);    % button up detected
                mask = (obj.xd - min(pt(1),pt2(1)) > 0) & (obj.xd - max(pt(1),pt2(1)) < 0);
                mask = mask & (obj.yd - min(pt(2),pt2(2)) > 0) & (obj.yd - max(pt(2),pt2(2)) < 0);
                
                temp_rect.Position = [min(pt(1),pt2(1)), min(pt(2), pt2(2)), abs(pt2(1)-pt(1)), abs(pt2(2)-pt(2))];
                for vnd_ = 1:size(obj.H,2)
                    
                    if strcmp(temp_selection_style,'add')
                        temp_selected_variables(vnd_) = xor(mask(vnd_), obj.selected_variables(vnd_));
                    else
                        temp_selected_variables(vnd_) = mask(vnd_);
                    end
                    if temp_selected_variables(vnd_)
                        obj.h_vn_egal{vnd_}.EdgeColor = [1 0 0];
                    else
                        obj.h_vn_egal{vnd_}.EdgeColor = 'none';
                    end
                end
                
                for cnd_ = 1:size(obj.H,1)
                    if strcmp(temp_selection_style,'add')
                        temp_selected_checks(cnd_) = xor(mask(cnd_+ size(obj.H,2)), obj.selected_checks(cnd_));
                     else
                        temp_selected_checks(cnd_) = mask(cnd_+ size(obj.H,2));
                    end   
                    
                    if temp_selected_checks(cnd_)
                        obj.h_pn_plus{cnd_}.EdgeColor = [1 0 0];
                    else
                        obj.h_pn_plus{cnd_}.EdgeColor = 'none';
                    end
                end
                
                
            end
            function rbbox_release_fcn(~,~)
                %pt2 = a.CurrentPoint(1,1:2);    % button up detected
                %mask = (obj.xd - min(pt(1),pt2(1)) > 0) & (obj.xd - max(pt(1),pt2(1)) < 0);
                %mask = mask & (obj.yd - min(pt(2),pt2(2)) > 0) & (obj.yd - max(pt(2),pt2(2)) < 0);
                obj.selected_variables = temp_selected_variables;
                obj.selected_checks = temp_selected_checks;
                for vnd_ = 1:size(obj.H,2)
                    %obj.selected_variables(vnd_) = temp_selected_variables(vnd_);
                    if obj.selected_variables(vnd_)
                        obj.h_vn_egal{vnd_}.EdgeColor = [1 0 0];
                    else
                        obj.h_vn_egal{vnd_}.EdgeColor = 'none';
                    end
                end
                
                for cnd_ = 1:size(obj.H,1)
                    %obj.selected_checks(cnd_) = temp_selected_checks(cnd_);
                    if obj.selected_checks(cnd_)
                        obj.h_pn_plus{cnd_}.EdgeColor = [1 0 0];
                    else
                        obj.h_pn_plus{cnd_}.EdgeColor = 'none';
                    end
                end
                source.WindowButtonMotionFcn = [];
                source.WindowButtonUpFcn = [];
                delete(temp_rect);
                temp_selected_variables = [];
                temp_selected_checks = [];
            end
        end
        
        function reset_variable_selection(obj)
            for vnd_ = 1:size(obj.H,2)
                obj.selected_variables(vnd_) = 0;
                obj.h_vn_egal{vnd_}.EdgeColor = 'none';
            end
        end
        
        function reset_check_selection(obj)
            for cnd_ = 1:size(obj.H,1)
                obj.selected_checks(cnd_) = 0;
                obj.h_pn_plus{cnd_}.EdgeColor = 'none';
            end
        end
        
        function reset_selection(obj)
            reset_check_selection(obj);
            reset_variable_selection(obj)
        end
    end
end

