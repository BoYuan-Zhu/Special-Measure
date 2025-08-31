function tf = isopt(ctrl, opt)
%ISOPT  Check if option string OPT is present in CTRL.
% Usage:
%   tf = isopt(ctrl, opt)
%
% INPUT:
%   ctrl : string (e.g. 'fast pls') or cell array of strings (e.g. {'fast','pls'})
%   opt  : option to check (string)
%
% OUTPUT:
%   tf   : logical true/false

    if iscell(ctrl)
        % If ctrl is a cell array of strings
        tf = any(strcmp(ctrl, opt));
    elseif ischar(ctrl) || isstring(ctrl)
        % If ctrl is a string
        tf = ~isempty(strfind(char(ctrl), opt));  % old style
        % tf = contains(ctrl, opt);  % for newer MATLAB
    else
        tf = false;
    end
end
