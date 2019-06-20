classdef tanner_graph
    % tanner_graph is a class for representing Tanner graphs from parity check matrices.
    
    properties(SetAccess = 'private', GetAccess = 'public')
        H
        
        variable_nbr
        check_nbr
        
        variable_names
        check_names
        
        bp_graph
    end
    
    methods
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
            
            A = [[zeros(size(H,2)) H.'] ; [H zeros(size(H,1))]];
            
            obj.bp_graph = graph(A);
            obj.H = H;
            obj.variable_names = variable_names;
            obj.check_names = check_names;
            obj.variable_nbr = n;
            obj.check_nbr = p;
            
        end
        
        function varargout = plot(obj,varargin)
            tg_hdl = tanner_graph_handle(obj, varargin{:});
            if nargout == 1
                varargout{1} = tg_hdl;
            end
        end
    end
    
        
end

