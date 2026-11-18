function r = rom_replay(M, rom, par, soc0, Ta, t, Ich)
%ROM_REPLAY  Cho ROM (z da khu, CUNG mo hinh trong acados) chay lai mot profile dong
% SAC Ich(t) [A, >= 0] da ap len DFN, tu trang thai nghi can bang tai soc0 (nhu
% nmpc_closed_loop.m). Tra ve lithium mat vinh vien du doan cua ROM tren pha sac
% r.loss = n_SEI + n_chet [mAh] (de so voi so hau kiem tren DFN; GD-85), r.sei, r.dead,
% r.reason, r.t_end. Chan doan "du doan cua ROM vs cham diem tren DFN".
[t, ia] = unique(t(:)); Ich = Ich(ia);
y = dfn_state_soc(par, soc0, Ta);
yc = dfn_consistent_init(0, y, par, struct('mode', 'I', 'value', 0, 'Tamb', Ta));
x0 = rom_from_dfn(rom, par, yc);
Ifun = @(s) -interp1(t, Ich, min(max(s, t(1)), t(end)), 'linear');
q = rom_sim_ode(M.E, M, rom, x0, Ifun, Ta, t, struct('sat', false));
r.sei = q.nsei(end); r.dead = q.ndl(end); r.loss = r.sei + r.dead;
r.reason = q.reason; r.t_end = q.t(end);
end
