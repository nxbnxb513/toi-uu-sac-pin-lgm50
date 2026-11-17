function steps = dfn_cccv(Ichg, Vmax, Icut, Tamb, tmax)
%DFN_CCCV  Tao hai buoc sac CC-CV: dong khong doi Ichg [A, > 0] toi Vmax,
% roi giu ap Vmax (rang buoc dai so) toi khi |I| <= Icut.
% Vmax: ap CV [V], hoac struct par (dung par.V_cv, GD-43). Nen truyen par.V_cv.
if nargin < 5, tmax = 20*3600; end
if isstruct(Vmax), Vmax = Vmax.V_cv; end
steps(1) = struct('mode', 'I', 'value', -abs(Ichg), 'tmax', tmax, 'Tamb', Tamb, ...
    'stop', struct('Vmax', Vmax), 'tout', []);
steps(2) = struct('mode', 'V', 'value', Vmax, 'tmax', tmax, 'Tamb', Tamb, ...
    'stop', struct('Icut', abs(Icut)), 'tout', []);
end
