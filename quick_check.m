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
elseif numel(handles.file_list(batch_selected).file_list) < 1
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
elseif isempty(get(get(handles.fittype,'SelectedObject'),'Tag'));
    %5. No fittype entered
    warning('No fittype entered');
    errormsg = 'No fittype entered';
elseif isempty(get(get(handles.data_order,'SelectedObject'),'Tag'));
    %6. No data_order entered
    warning('No data order entered');
    errormsg = 'No data order entered';
elseif numel(str2num(get(handles.te_box, 'String'))) < numel(handles.file_list(batch_selected).file_list);
    %7. Parameter list less than number of files
    warning('Not enough parameters');
    errormsg = 'Not enough parameters';
elseif numel(str2num(get(handles.te_box, 'String'))) == 1;
    %8. Parameter list single, not error, but may return bad
    warning('Only one parameter entered');
elseif isempty(get(handles.tr, 'String'))
    warning('TR not defined')
    errormsg = 'TR not defined';
else
    %Rough check ok
end
