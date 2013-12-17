% Remove dir info to allow nice visualization
function list = visualize_list(list);

for i = 1:numel(list)
    [fd fn] = fileparts(list{i});
    list{i} = fn;
end