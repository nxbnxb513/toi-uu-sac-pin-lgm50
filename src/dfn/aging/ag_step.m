function s = ag_step(mode, value, tmax, Tamb, stop, tout)
%AG_STEP  Mot buoc cho dfn_run (I > 0 la xa). stop: struct (Vmin, Vmax, Icut, Qstop).
if nargin < 5 || isempty(stop), stop = struct(); end
if nargin < 6, tout = []; end
if isempty(tout), tout = tmax; end      % chi xuat diem cuoi (nhanh)
s = struct('mode', mode, 'value', value, 'tmax', tmax, 'Tamb', Tamb, 'stop', stop, 'tout', tout);
end
