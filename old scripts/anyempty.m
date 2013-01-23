%Check if any arrays empty.

function empty = anyempty(results)

empty = 0;
results;
tsize = size(results);
tsizea = tsize(1);
tsizeb = tsize(2);


if(tsizeb == 0)
  empty = 1;
  return;
end


for i = 1:tsizea
  if(isempty(results{i}))
    empty = 1;
    return;
    
  else
  end
end
