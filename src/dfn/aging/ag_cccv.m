function st = ag_cccv(par, Ichg, Tamb, trest)
%AG_CCCV  Sac CC Ichg [A] toi V_cv (par.V_cv, GD-43) roi giu ap toi C/100 = 0.05 A, nghi trest [s].
st = [ag_step('I', -abs(Ichg), 30*3600, Tamb, struct('Vmax', par.V_cv)), ...
      ag_step('V', par.V_cv, 30*3600, Tamb, struct('Icut', par.Qnom/100))];
if trest > 0, st(end+1) = ag_step('I', 0, trest, Tamb); end
end
