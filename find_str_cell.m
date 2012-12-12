function Ind=find_str_cell(Cell,Str,Case,Sub);
%--------------------------------------------------------------------------
% find_str_cell function   Search for a (sub)string within cell array
%                        of strings and return the indicies of the
%                        cell-array elements that contain the (sub)string.
% Input  : - Cell array of strings.
%          - String to search.
%          - Case sensitive {'y' | 'n'}, default is 'y'.
%          - Search Sub string {'y'} or exact match {'n'}, default is 'y'. 
% Output : - Indicies of cell-array containing the string.
% Tested : Matlab 7.0
%     By : Eran O. Ofek            January 2006
%    URL : http://wise-obs.tau.ac.il/~eran/matlab.html
%--------------------------------------------------------------------------

if (nargin==2),
   Case   = 'y';
   Sub    = 'y';
elseif (nargin==3),
   Sub    = 'y';
elseif (nargin==4),
   % do nothing
else
   error('Illegal number of input arguments');
end


Size = size(Cell);
N    = prod(Size);

Ind  = zeros(Size);
for I=1:1:N,
   Found = 0;

   switch Case
    case 'y'
       StrI = findstr(Cell{I},Str);
    case 'n'
       StrI = findstr(lower(Cell{I}),lower(Str));
    otherwise
       error('Unknown Case Option');
   end
   if (isempty(StrI)==0),
      switch Sub
       case 'n'
  	  if (StrI==1 & length(Cell{I})==length(Str)),
  	     Found = 1;
          end
       case 'y'
          Found = 1;
       otherwise
          error('Unknown Sub Option');
      end
   end

   Ind(I) = Found;

end
