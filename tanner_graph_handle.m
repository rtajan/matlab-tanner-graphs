classdef tanner_graph_handle < handle
    % tanner_graph_handle handle to a GRAPHPLOT representing a Tanner
    % graph
    
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
    
    properties(Access = 'private')
        tanner_graph
        
        plot_handler
        
        node_styles
        node_labels
        
        xd
        yd
        
        h_vn_txt
        h_vn_egal
        
        h_pn_plus
        h_pn_txt
        
    end
    
    methods
        
        function obj = tanner_graph_handle(tanner_graph)
            % Constructor of the tanner_graph_handle object. 
            % Plots the underlying tanner_graph and returns the object.
            
            obj.tanner_graph = tanner_graph;
            n = obj.tanner_graph.variable_nbr;
            p = obj.tanner_graph.check_nbr;
            
            obj.node_styles  = cell(1,n+p);
            obj.node_labels = cell(1,n+p);
            
            for i = 1:n
                obj.node_styles{i} = 's';
                obj.node_labels{i} = ' ';
            end
            
            for i = n+1:n+p
                obj.node_styles{i} = 'o';
                obj.node_labels{i} = ' ';
            end
            
            obj.plot_handler = plot(obj.tanner_graph.bp_graph,'Marker',obj.node_styles, 'MarkerSize', 18, 'NodeLabel', obj.node_labels);
            this_fig = gcf;
            
            obj.xd = get(obj.plot_handler, 'XData');
            obj.yd = get(obj.plot_handler, 'YData');
            
            obj.plot_handler.XData(1) = obj.xd(1);
            obj.h_vn_txt = cell(1,n);
            obj.h_vn_egal = cell(1,n);
            
            obj.h_pn_plus = cell(1,p);
            obj.h_pn_txt = cell(1,p);
            
            for i = 1:n
                obj.h_vn_egal{i} = text(obj.xd(i), obj.yd(i), '\bf =', 'Color',[1, 1 ,1],'FontSize',16, 'HorizontalAlignment','center', 'VerticalAlignment','middle','Interpreter',obj.interpreter);
                obj.h_vn_txt{i}  = text(obj.xd(i), obj.yd(i), obj.tanner_graph.variable_names{i},'FontSize',20, 'HorizontalAlignment','center', 'VerticalAlignment','bottom','Interpreter',obj.interpreter);
            end
            for i = 1:p
                obj.h_pn_plus{i} = text(obj.xd(i+n), obj.yd(i+n), '+', 'Color',[1, 1 ,1],'FontSize',18, 'HorizontalAlignment','center', 'VerticalAlignment','middle','Interpreter',obj.interpreter);
                obj.h_pn_txt{i} = text(obj.xd(i+n), obj.yd(i+n), obj.tanner_graph.check_names{i}, 'FontSize',18, 'HorizontalAlignment','center', 'VerticalAlignment','bottom','Interpreter',obj.interpreter);
            end
            set(this_fig,'WindowButtonDownFcn',@(f,~)obj.edit_graph(f));
        end
        
        %% layout
        function layout(obj,varargin)
            % layout is a wrapper to call the @layout function for the @PlotGraph
            % object underlying the tanner_graph object  
            layout(obj.plot_handler,varargin{:});
            obj.xd = get(obj.plot_handler, 'XData');
            obj.yd = get(obj.plot_handler, 'YData');
            
            for i = 1:n
                obj.h_vn_egal{i}.Position = [obj.xd(i), obj.yd(i)];
                obj.h_vn_txt{i}.Position = [obj.xd(i), obj.yd(i)];
            end
            for i = 1:p
                obj.h_pn_plus{i}.Position = [obj.xd(n+i), obj.yd(n+i)];
                obj.h_pn_txt{i}.Position = [obj.xd(n+i), obj.yd(n+i)];
            end
        end
        
        
        %% to_tikz
        function to_tikz(obj,file_name)
            % to_tikz writes the Tanner graph display into a tex file
            % using tikz language for drawing

            n = obj.tanner_graph.variable_nbr;
            p = obj.tanner_graph.check_nbr;
            
            %%
            FID = fopen(file_name,'w');
            
            PREAMBULE = '\\documentclass[tikz]{standalone}\n\\usepackage{pgfplots}\n\\usepackage{grffile}\n\\usepackage{pgfplots,tikz}\n\\usetikzlibrary{shapes,decorations,arrows,positioning,fit}\n\\pgfplotsset{compat=newest}\n\n\\begin{document}\n';
            COLORB_GND = ['\\pagecolor{',obj.tikz_params.backgound_color,'}\n\n'];
            
            BEGIN_TIKZ = '\\begin{tikzpicture} \n';
            
            VARIABLE_NODE_STYLE = '\\tikzset{variable_node_style/.style={regular polygon,regular polygon sides=4,draw=VARIABLE_NODE_DRAW_COLOR,fill=VARIABLE_NODE_FILL_COLOR, inner sep = 0.1pt}};\n';
            VARIABLE_NODE = '\\node [variable_node_style, label=above:{%s}] (x%d) at (%f,%f) {$=$};\n';
            
            CHECK_NODE_STYLE = '\\tikzset{check_node_style/.style={circle,draw=CHECK_NODE_DRAW_COLOR,fill=CHECK_NODE_FILL_COLOR, inner sep = 0.1pt}};\n';
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
            
            
            %%
            fprintf(FID, PREAMBULE);
            fprintf(FID,COLORB_GND);
            fprintf(FID,BEGIN_TIKZ);
            fprintf(FID, '\n%% Style definitions\n');
            fprintf(FID, VARIABLE_NODE_STYLE);
            fprintf(FID, CHECK_NODE_STYLE);
            fprintf(FID, EDGE_STYLE);
            
            fprintf(FID, '\n%% Variable Nodes\n');
            
            for vn = 1:n
                fprintf(FID, VARIABLE_NODE, obj.tanner_graph.variable_names{vn}, vn, obj.xd(vn)*2, obj.yd(vn)*2);
            end
            
            fprintf(FID, '\n%% Check Nodes\n');
            for cn = 1:p
                fprintf(FID, CHECK_NODE, obj.tanner_graph.check_names{cn}, cn, obj.xd(cn+n)*2, obj.yd(cn+n)*2);
            end
            
            fprintf(FID, '\n%% Edges\n');
            for vn = 1:n
                for cn = 1:p
                    if obj.tanner_graph.H(cn,vn) == 1
                        fprintf(FID, EDGE, vn, cn);
                    end
                end
            end
            
            fprintf(FID, END_TIKZ);
            
            fprintf(FID, END_DOC);
            fclose(FID);
            
        end
    end
    
    methods (Access = private)
        
        %% edit_graph
        function edit_graph(obj,f)
            % For moving nodes whithin the Tanner graph plot
            a = ancestor(obj.plot_handler,'axes');
            pt = a.CurrentPoint(1,1:2);
            dx = obj.plot_handler.XData - pt(1);
            dy = obj.plot_handler.YData - pt(2);
            len = sqrt(dx.^2 + dy.^2);
            [lmin,idx] = min(len);
            
            tol = max(diff(a.XLim),diff(a.YLim))/20;
            if lmin > tol || isempty(idx)
                return
            end
            node = idx(1);
            
            f.WindowButtonMotionFcn = @motion_fcn;
            f.WindowButtonUpFcn     = @release_fcn;
            
            function motion_fcn(~,~)
                newx = a.CurrentPoint(1,1);
                newy = a.CurrentPoint(1,2);
                obj.plot_handler.XData(node) = newx;
                obj.xd(node) = newx;
                if node > size(obj.tanner_graph.H,2)
                    obj.h_pn_txt{node-size(obj.tanner_graph.H,2)}.Position(1) = newx;
                    obj.h_pn_plus{node-size(obj.tanner_graph.H,2)}.Position(1) = newx;
                else
                    obj.h_vn_txt{node}.Position(1)   = newx;
                    obj.h_vn_egal{node}.Position(1)   = newx;
                    
                end
                
                obj.plot_handler.YData(node) = newy;
                obj.yd(node) = newy;
                if node > size(obj.tanner_graph.H,2)
                    obj.h_pn_txt{node-size(obj.tanner_graph.H,2)}.Position(2) = newy;
                    obj.h_pn_plus{node-size(obj.tanner_graph.H,2)}.Position(2) = newy;
                else
                    obj.h_vn_egal{node}.Position(2)   = newy;
                    obj.h_vn_txt{node}.Position(2)   = newy;
                end
                
                drawnow;
            end
            
            function release_fcn(~,~)
                f.WindowButtonMotionFcn = [];
                f.WindowButtonUpFcn = [];
            end
        end
        
    end
end

