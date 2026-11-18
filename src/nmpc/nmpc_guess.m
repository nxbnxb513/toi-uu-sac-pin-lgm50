function G = nmpc_guess(M, rom, x0, cfg, lim, Imax)
%NMPC_GUESS  Duong sac an toan nhanh nhat va doan dau "tu duong CCCV" tren ROM (GD-82),
% tach ra tu nmpc_closed_loop.m (18/11/2026) de pilot_run.m dung TRUOC khi tao bo giai:
% so buoc IRK moi khoang du bao duoc chon theo dong cua doan dau (nmpc_steps.m, GD-87).
%   G.Pf: sac an toan nhanh nhat (I <= I_max); G.infeasible: nhanh nhat > ngan sach
%   G.P: doan dau; G.Icc: dong CC cua doan dau.
Ta = cfg.Tamb; soc_t = cfg.soc_target; unlimited = ~isfinite(cfg.budget);
tmax_prof = max(cfg.tmax, 1);
G.Pf = nmpc_cccv_rom(M, rom, x0, Ta, soc_t, Imax, lim, 0, cfg.dt_prof, tmax_prof);
fprintf('  sac an toan nhanh nhat (ROM, I <= %.1f A): %s, t = %.0f s, SOC %.4f (%d lan tich phan, %.1f s)\n', ...
    Imax, G.Pf.reason, G.Pf.t_end, G.Pf.soc_end, G.Pf.nsim, G.Pf.wall);
G.infeasible = ~unlimited && G.Pf.T > cfg.budget;
G.P = []; G.Icc = NaN;
if G.infeasible, return; end
% doan dau "tu duong CCCV": CCCV an toan o dong goc; neu qua ngan sach thi dong CC
% lon dan (I_cc T_CCCV / ngan sach, roi I_max) - duong an toan nhanh nhat da tinh.
Icc_list = cfg.Icc_cccv;
if ~unlimited
    Icc_list = unique(min(Imax, [cfg.Icc_cccv, cfg.Icc_cccv*max(1, cfg.T_cccv/cfg.budget)*1.05]));
end
for Icc = Icc_list
    Pc = nmpc_cccv_rom(M, rom, x0, Ta, soc_t, Icc, lim, 0, cfg.dt_prof, tmax_prof);
    fprintf('  doan dau CCCV an toan tren ROM, I_cc = %.2f A: %s, t = %.0f s, SOC %.4f (%.1f s)\n', Icc, Pc.reason, Pc.t_end, Pc.soc_end, Pc.wall);
    if isfinite(Pc.T) && (unlimited || Pc.T <= cfg.budget), G.P = Pc; G.Icc = Icc; break; end
end
if isempty(G.P), G.P = G.Pf; G.Icc = Imax; end
end
