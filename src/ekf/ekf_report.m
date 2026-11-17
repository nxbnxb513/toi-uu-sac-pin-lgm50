function ekf_report(indir, outfile)
%EKF_REPORT  Gop ket qua cac phep thu EKF (ekf_sum_*.csv) thanh bang markdown.
if nargin < 2, outfile = fullfile(indir, 'ekf_report.md'); end
L = dir(fullfile(indir, '**', 'ekf_sum_*.csv'));
if isempty(L), error('ekf_report: khong co ket qua'); end
T = [];
for i = 1:numel(L)
    t = readtable(fullfile(L(i).folder, L(i).name), 'TextType', 'string');
    if isempty(T), T = t; else, T = [T; t(:, T.Properties.VariableNames)]; end %#ok<AGROW>
end
T = sortrows(T, {'scen', 'noise', 'Tc', 'crate', 'socerr'});
writetable(T, fullfile(fileparts(outfile), 'ekf_all.csv'));
fid = fopen(outfile, 'w');
fprintf(fid, '# Ket qua EKF (pin that = DFN day du)\n\n%d truong hop. Sai so = uoc luong - that. "sau 600 s" bo qua giai doan hoi tu ban dau.\n\n', height(T));
fprintf(fid, '## Sai so\n\n| kich ban | nhieu | T (degC) | C | sai SOC dau | SOC RMSE / max (%%) | SOC RMSE / max sau 600 s (%%) | eta_Li RMSE / max (mV) | eta_Li RMSE / max sau 600 s (mV) | T RMSE / max sau 600 s (K) | hoi tu SOC <1 %% / eta <5 mV (s) | t cuoi (s) |\n|---|---|---|---|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    r = T(i, :);
    fprintf(fid, '| %s | %s | %d | %g | %+.0f %% | %.2f / %.2f | %.2f / %.2f | %.1f / %.1f | %.1f / %.1f | %.3f / %.3f | %s / %s | %.0f |\n', ...
        r.scen, r.noise, r.Tc, r.crate, 100*r.socerr, r.soc_rmse, r.soc_max, r.soc_rmse_l, r.soc_max_l, ...
        r.eta_rmse, r.eta_max, r.eta_rmse_l, r.eta_max_l, r.T_rmse_l, r.T_max_l, num(r.tconv_soc), num(r.tconv_eta), r.t_end);
end
fprintf(fid, '\n## Do nhat quan (sau 600 s) va an toan ma lithium\n\nNEES vo huong ly tuong = 1; ty le trong +/-3 sigma ly tuong 99.7 %%; NIS ly tuong 2. Uoc cao eta = eta_uoc - eta_that > 0 (phia NGUY HIEM: bo dieu khien tuong con xa nguong ma).\n\n');
fprintf(fid, '| kich ban | nhieu | T | C | sai SOC dau | NEES SOC / eta / T | trong 3 sigma SOC / eta / T (%%) | NIS | NEES toan trang thai | uoc cao eta max / P99.7 (mV) | uoc cao khi eta < 100 mV (mV) | sigma_eta trung vi (mV) | eta_that >= eta_uoc - 3 sigma (%%) | min eta that / uoc (mV) |\n|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    r = T(i, :);
    fprintf(fid, '| %s | %s | %d | %g | %+.0f %% | %.2f / %.2f / %.2f | %.1f / %.1f / %.1f | %.2f | %.1f | %.1f / %.1f | %.1f | %.1f | %.1f | %.1f / %.1f |\n', ...
        r.scen, r.noise, r.Tc, r.crate, 100*r.socerr, r.nees_soc, r.nees_eta, r.nees_T, r.in3_soc, r.in3_eta, r.in3_T, r.nis, r.nees_full, ...
        r.eta_over_max, r.eta_over_p997, r.eta_over_near, r.s_eta_med, r.cover1s, r.eta_true_min, r.eta_est_min);
end
fprintf(fid, '\n## Trang thai lao hoa (cuoi lan sac) va thoi gian chay\n\n| kich ban | nhieu | T | C | sai SOC dau | LLI uoc +/- sigma (that) (mAh) | R_film/BOL uoc +/- sigma (that) | L_SEI uoc (that) (nm) | ms/buoc | so buoc | so lan chieu |\n|---|---|---|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    r = T(i, :);
    fprintf(fid, '| %s | %s | %d | %g | %+.0f %% | %.0f +/- %.0f (%.0f) | %.3f +/- %.3f (%.2f) | %.1f (%.1f) | %.0f | %d | %d |\n', ...
        r.scen, r.noise, r.Tc, r.crate, 100*r.socerr, 1e3*r.lli_end, 1e3*r.s_lli_end, 1e3*r.lli_true, r.rf_end, r.s_rf_end, r.rf_true, ...
        r.Lsei_end_nm, r.Lsei_true_nm, r.ms_per_step, r.n, r.nproj);
end
fclose(fid);
type(outfile);
end

function s = num(v)
if isnan(v), s = 'khong'; else, s = sprintf('%.0f', v); end
end
