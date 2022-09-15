function handles = disp_error(errormsg, handles)

if ~isempty(errormsg)
    warning(errormsg);
    set(handles.status, 'String', errormsg);
    set(handles.status, 'ForegroundColor', 'red');
    set(handles.status, 'FontSize', 8);
else
    set(handles.status, 'String', 'Ready to submit');
    set(handles.status, 'ForegroundColor', 'black');
    set(handles.status, 'FontSize', 12);
end
    