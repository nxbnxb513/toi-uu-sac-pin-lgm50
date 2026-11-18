function [y, c] = ag_cycle(par, y, expt, Tamb)
%AG_CYCLE  Mot chu ky lao hoa (Kirkaldy 2024 Table 1-6; Li 2025 SI Table 5, Note 1):
%   Expt 2 (70-85 %): xa 1C 730 mAh -> sac CC 0.3C 730 mAh (khong CV)
%   Expt 3 (85-100 %): xa 1C 730 mAh -> sac CC 0.3C toi V_cv -> CV toi C/100
%   Expt 1 (0-30 %):  sac CC 0.3C 1500 mAh -> xa 1C toi 2.5 V   (Kirkaldy 2024 Table 2; GD-94)
%   Expt 5 (0-100 %): xa 1C toi 2.5 V -> sac CC 0.3C toi V_cv -> CV toi C/100 (Table 6; GD-94)
% 1C = 5 A (Li 2025 SI Note 9; Kirkaldy 2022 tr. 3). Gioi han an toan 2.5 V / V_cv (GD-43) moi buoc.
Idis = par.Qnom; Ich = 0.3*par.Qnom;
switch expt
    case 1
        Ah = 1.500;
        st = ag_step('I', -Ich, Ah/Ich*3600, Tamb, struct('Vmax', par.V_cv));
        st(2) = ag_step('I', Idis, 2*3600, Tamb, struct('Vmin', par.Vmin));
    case 5
        st = ag_step('I', Idis, 2*3600, Tamb, struct('Vmin', par.Vmin));
        st(2) = ag_step('I', -Ich, 10*3600, Tamb, struct('Vmax', par.V_cv));
        st(3) = ag_step('V', par.V_cv, 10*3600, Tamb, struct('Icut', par.Qnom/100));
    otherwise
        Ah = 0.730;
        st = ag_step('I', Idis, Ah/Idis*3600, Tamb, struct('Vmin', par.Vmin));
        if expt == 2
            st(2) = ag_step('I', -Ich, Ah/Ich*3600, Tamb, struct('Vmax', par.V_cv));
        else
            st(2) = ag_step('I', -Ich, 10*3600, Tamb, struct('Vmax', par.V_cv));
            st(3) = ag_step('V', par.V_cv, 10*3600, Tamb, struct('Icut', par.Qnom/100));
        end
end
[y, o, ok] = ag_exec(par, y, st);
c.ok = ok; c.reason = strjoin(cellfun(@char, o.reason, 'UniformOutput', false), '/');
c.dur = o.t(end); c.Tmax = max(o.T); c.Vmin = min(o.V); c.Vmax = max(o.V);
end
