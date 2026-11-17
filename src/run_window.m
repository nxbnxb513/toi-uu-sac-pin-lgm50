function run_window(lo, Cbase, user)
%RUN_WINDOW  Chay tat ca cac vung sac bat dau tu 'lo' (% SOC) voi baseline Cbase.
%   Vi du: run_window(10, 0.3) chay 10->20, 10->30, ..., 10->100.
%   Moi vung tinh RIENG hai truong hop: CCCV va profile toi uu.
%   Ket qua ghi vao results/window_loXX_cYY.csv (moi vung mot dong).

if nargin < 3, user = struct(); end
cfg = default_cfg(user);
p = params_lgm50('fine');
if ~exist(cfg.outdir, 'dir'), mkdir(cfg.outdir); end

tag = sprintf('lo%02d_c%03d', round(lo), round(100*Cbase));
fid = fopen(fullfile(cfg.outdir, ['window_' tag '.csv']), 'w');
fprintf(fid, ['soc_lo,soc_hi,c_base,' ...
    't_base_s,t_opt_s,aging_base_Ah,aging_opt_Ah,reduction_pct,' ...
    'sei_base_Ah,sei_opt_Ah,dead_base_Ah,dead_opt_Ah,plate_base_Ah,plate_opt_Ah,' ...
    'etaLi_min_base_V,etaLi_min_opt_V,Tpeak_base_K,Tpeak_opt_K,' ...
    'Vpeak_base_V,Vpeak_opt_V,cv_base,cv_opt,reached_base,reached_opt,n_eval']);
for k = 1:cfg.Nseg, fprintf(fid, ',c_opt_%d', k); end
fprintf(fid, '\n');

profiles = struct('lo', {}, 'hi', {}, 'base', {}, 'best', {});
for hi = (lo + cfg.step):cfg.step:100
    t_start = tic;
    try
        [best, base, info] = optimise_window(p, lo/100, hi/100, Cbase, cfg);
        red = 100*(1 - best.aging/base.aging);
        fprintf(fid, '%g,%g,%g,%.2f,%.2f,%.6e,%.6e,%.3f,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.5f,%.5f,%.3f,%.3f,%.4f,%.4f,%d,%d,%d,%d,%d', ...
            lo, hi, Cbase, base.t_charge, best.t_charge, base.aging, best.aging, red, ...
            base.Qsei, best.Qsei, base.Qdead, best.Qdead, base.Qplate, best.Qplate, ...
            base.etaLi_min, best.etaLi_min, base.T_peak, best.T_peak, ...
            base.V_peak, best.V_peak, base.used_cv, best.used_cv, ...
            base.reached, best.reached, info.nev);
        c = best.crates; c(end+1:cfg.Nseg) = NaN;
        fprintf(fid, ',%.4f', c(1:cfg.Nseg));
        fprintf(fid, '\n');
        profiles(end+1) = struct('lo', lo, 'hi', hi, ...
            'base', slim(base), 'best', slim(best)); %#ok<AGROW>
        fprintf('Vung %3d -> %3d %%, %.1fC: giam lao hoa %.2f %% (%d lan mo phong, %.0f s)\n', ...
            lo, hi, Cbase, red, info.nev, toc(t_start));
    catch err
        fprintf('Vung %3d -> %3d %%, %.1fC: LOI: %s\n', lo, hi, Cbase, err.message);
    end
end
fclose(fid);
save(fullfile(cfg.outdir, ['profiles_' tag '.mat']), 'profiles', 'cfg');
end

function s = slim(r)
% Giu lai chuoi thoi gian thua de file nho.
n = numel(r.t); id = unique(round(linspace(1, n, min(n, 300))));
s.t = r.t(id); s.I = r.I(id); s.V = r.V(id); s.T = r.T(id);
s.soc = r.soc(id); s.etaLi = r.etaLi(id); s.crates = r.crates;
end
