% Instantiate a dataset with generic labels

function handles = instantiate_dataset(handles);

   handles.file_list(handles.datasets).file_list = {};
   handles.file_list(handles.datasets).odd_echoes = get(handles.odd_echoes, 'Value');
   
   handles.file_list(1).odd_echoes
   disp('coo')