% Visualize R2 on the screen

function handles = visualize_R2(handles, single_IMG)
    cur_slice_num = str2num(get(handles.slice_num, 'String'));
    axes(handles.r2graph)
    %imagesc(zeros(100,100))
    imagesc(single_IMG(:,:, cur_slice_num), [0 1]);
    set(handles.r2graph, 'XTick', []);
    set(handles.r2graph, 'YTick', []);
    handles.single_IMG = single_IMG;
    set(handles.slice_total, 'String', ['/ ' num2str(size(single_IMG,3))]);
    set(handles.slice_slider, 'Min', 1));
    set(handles.slice_slider, 'Max', size(single_IMG,3));
    handles.single_IMG = single_IMG;