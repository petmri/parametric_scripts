% Consistency check for a map to be calculated

function [errormsg] = quick_check(handles);
errormsg = '';
% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

%1. Are datasets present?

if handles.batch_total <1
    
    warning('No Datasets present');
    errormsg = 'No Datasets present';
    return;
elseif numel(handles.batch_data(batch_selected).file_list) < 1
    %2. in current dataset, are files present
    warning('No files in dataset');
    errormsg = 'No files in dataset';
    return;
elseif isempty(get(get(handles.data_order,'SelectedObject'),'Tag'));
    %3. No data order selected
    warning('No data order selected');
    errormsg = 'No data order selected';
elseif isempty(str2num(get(handles.te_box, 'String')))
    %4. Parameter box empty
    warning('No indpendent variables entered');
    errormsg = 'No independent variables entered';
elseif isempty(get(get(handles.fit_type,'SelectedObject'),'Tag'));
    %5. No fit_type entered
    warning('No fit_type entered');
    errormsg = 'No fit_type entered';
elseif isempty(get(get(handles.data_order,'SelectedObject'),'Tag'));
    %6. No data_order entered
    warning('No data order entered');
    errormsg = 'No data order entered';
elseif numel(str2num(get(handles.te_box, 'String'))) ~= numel(handles.batch_data(batch_selected).file_list)...
		&& strcmp(get(get(handles.data_order,'SelectedObject'),'Tag'),'xyzfile');
    %7. Parameter list less than number of files
    warning('Wrong number of parameters');
    errormsg = 'Wrong number of parameters';
elseif numel(str2num(get(handles.te_box, 'String'))) == 1;
    %8. Parameter list single, not error, but may return bad
    warning('Only one parameter entered');
elseif isempty(get(handles.tr, 'String'))...
		&& ~isempty(strfind(get(get(handles.fit_type,'SelectedObject'),'Tag'), 't1'))...
		&& (~isempty(strfind(get(get(handles.fit_type,'SelectedObject'),'Tag'),'fa')) || ~isempty(strfind(get(get(handles.fit_type,'SelectedObject'),'Tag'),'ti_exponential'))) 
    warning('TR not defined')
    errormsg = 'TR not defined';
elseif numel(handles.batch_data(batch_selected).file_list) > 1 && ~strcmp(get(get(handles.data_order,'SelectedObject'),'Tag'), 'xyzfile')
     warning('Multiple files present')
    errormsg = 'Multiple files present';
% elseif strfind(get(get(handles.fit_type,'SelectedObject'),'Tag'), 'user_input') && handles.batch_data(batch_selected).tr
%     if(isempty(num2str(str2num(get(handles.tr, 'String')))))
%     warning('Need to input TR')
%     errormsg = 'Need to input TR';
%     end
% else
    %Rough check ok
end
