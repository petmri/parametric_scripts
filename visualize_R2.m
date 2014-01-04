% Visualize R2 on the screen

function handles = visualize_R2(handles)
batch_selected = get(handles.batch_set,'Value');
single_IMG = handles.batch_data(batch_selected).preview_image;
	
if ~isempty(single_IMG)
    cur_slice_num = str2num(get(handles.slice_num, 'String'));
    axes(handles.r2graph)
    %imagesc(zeros(100,100))
    imagesc(single_IMG(:,:, cur_slice_num)', [0 1]);
    colorbar
    set(handles.r2graph, 'XTick', []);
    set(handles.r2graph, 'YTick', []);
%     handles.single_IMG = single_IMG;
    set(handles.slice_total, 'String', ['/ ' num2str(size(single_IMG,3))]);
    set(handles.slice_slider, 'Enable', 'on');
    set(handles.slice_slider, 'Max', size(single_IMG,3));
else
    % Resetting the graphic
    axes(handles.r2graph)
    %imagesc(zeros(100,100))
    imagesc(zeros(2,2), [0 1]);
    set(handles.r2graph, 'XTick', []);
    set(handles.r2graph, 'YTick', []);
    
    set(handles.slice_total, 'String', ['/ ' num2str(0)]);
    set(handles.slice_slider, 'Enable', 'off');   
end