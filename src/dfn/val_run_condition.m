function val_run_condition(cstr, Tdeg, datadir, outdir)
%VAL_RUN_CONDITION  Kiem chung mot dieu kien xa (C-rate, nhiet do) voi du lieu mo.
%   cstr    : '0p1' | '0p5' | '1' | '2'  (C-rate nhu trong ten file)
%   Tdeg    : 0 | 10 | 25 (degC)
%   datadir : thu muc data/ cua TEC-reduced-model (Zenodo 10.5281/zenodo.4864437)
%   outdir  : thu muc ket qua
% Voi MOI cell va MOI lan xa trong file: mo phong tu trang thai dau cua du lieu
%   - trang thai lithium ban dau: OCV(mo hinh) = ap nghi do duoc ngay truoc khi xa
%   - T ban dau = T moi truong = nhiet do be mat cell do duoc ngay truoc khi xa (GD-09)
%   - dong xa = dong trung binh do duoc; dung khi V = 2.5 V; sau do nghi 2 h
% roi tinh RMSE dien ap va nhiet do so voi du lieu, cho 4 bien the mo hinh
% (xem danh sach ben duoi).
if ischar(Tdeg) || isstring(Tdeg), Tdeg = str2double(Tdeg); end
cstr = char(cstr);
tag = sprintf('%sC_%ddegC', cstr, Tdeg);
od = fullfile(outdir, ['cond_' tag]);
if ~exist(od, 'dir'), mkdir(od); end
files = dir(fullfile(datadir, sprintf('%ddegC', Tdeg), sprintf('Cell*_%sC_%ddegC.csv', cstr, Tdeg)));
if isempty(files), error('Khong tim thay du lieu cho %s trong %s', tag, datadir); end
crate = str2double(strrep(cstr, 'p', '.'));

% Bien the mo hinh (bao cao tat ca, khong chon ngam):
%   paper          : cho nao bai bao in thi dung nhu in (ke ca he so dien giai 0.8353, -0.612;
%                    L_SEI,0 = 1.23625e-8 m; mat do xop kho nhu SI Table 6) - xem tai_lieu/gia_dinh.md
%   code           : cac cho do lay theo ma nguon cua tac gia (0.353, -6.12; L_SEI,0 = 9.2326e-9 m ...)
%   code_no_stress : code + tat khuech tan do ung suat (GD-10)
%   code_Rc_heat   : code + nhiet I^2.R_contact trong can bang nhiet (GD-05)
%   code_h15       : code + h = 15 W/m2/K nhu O'Regan 2022 (tr. 32) thay cho h = 20 cua Li 2025
%   code_h_tau     : code + h suy tu hang so thoi gian nguoi do duoc tau = 582 s (trung vi,
%                    data/ket_qua_du_lieu.md muc A.3): h = rho.c_p,eff.V_cell/(tau.A_cool)
% Nhiet do mo hinh (lumped, mot gia tri) duoc so voi cap nhiet GIUA than cell.
pb = dfn_params(struct('src', 'code'));
h_tau = dfn_rhocp(pb, Tdeg + 273.15, dfn_aging_state(pb, []))*pb.th.Vcell/(582*pb.th.Acool);
fprintf('h suy tu tau = 582 s: %.2f W/m2/K\n', h_tau);
vname = {'paper', 'code', 'code_no_stress', 'code_Rc_heat', 'code_h15', 'code_h_tau'};
pars  = {dfn_params(struct('src', 'paper')), pb, ...
         dfn_params(struct('src', 'code', 'stress_diffusion', false)), ...
         dfn_params(struct('src', 'code', 'contact_heat', true)), ...
         dfn_params(struct('src', 'code', 'h', 15)), ...
         dfn_params(struct('src', 'code', 'h', h_tau))};
nv = numel(vname);
par0 = pars{1};
fprintf('=== %s: %d file, luoi [%d %d %d | %d %d], %d an ===\n', tag, numel(files), ...
    par0.cfg.Nn, par0.cfg.Ns, par0.cfg.Np, par0.cfg.Nrn, par0.cfg.Nrp, par0.ix.ny);

rows = {}; runs = struct('cell', {}, 'idis', {}, 'seg', {}, 'sims', {});
for fi = 1:numel(files)
    fn = fullfile(files(fi).folder, files(fi).name);
    d = val_read_cell(fn);
    cellid = regexp(files(fi).name, 'Cell(\d+)', 'tokens', 'once'); cellid = cellid{1};
    if isempty(d.seg)
        fprintf('  %s: khong co doan xa, bo qua\n', files(fi).name); continue;
    end
    for si = 1:numel(d.seg)
        s = d.seg(si);
        if abs(s.Imean/(crate*par0.Qnom) - 1) > 0.1
            fprintf('  %s doan %d: dong %.3f A khong khop C-rate, bo qua\n', files(fi).name, si, s.Imean);
            continue;
        end
        T0 = s.T0 + 273.15;
        sims = cell(1, nv);
        for v = 1:nv
            try
                tic; sim = run_one(pars{v}, s, T0); wall = toc;
            catch ME
                fprintf('  !!! LOI o %s cell %s xa %d bien the %s: %s\n', tag, cellid, si, vname{v}, ME.message);
                rows(end+1,:) = {tag, vname{v}, crate, Tdeg, str2double(cellid), si, s.Vrest0, s.T0, s.Imean, NaN, ...
                    NaN, NaN, NaN, NaN, NaN, NaN, s.cap, NaN, s.T(end), NaN, s.dTpos, s.dTneg, pars{v}.th.h, ...
                    'error', NaN, NaN}; %#ok<AGROW>
                continue;
            end
            m = metrics(sim, s);
            fprintf(['  cell %s xa %d [%-9s]: Vrest=%.4f V, T0=%.1f C, I=%.3f A, q0=%.3f Ah | ', ...
                     'RMSE_V=%.1f mV, RMSE_T=%.2f K, cap sim/exp=%.3f/%.3f Ah, dT sim/exp=%.1f/%.1f K, %s, %d lan goi ve phai, %.1f s\n'], ...
                cellid, si, vname{v}, s.Vrest0, s.T0, s.Imean, sim.q0, 1e3*m.rmseV, m.rmseT, ...
                m.cap_sim, s.cap, m.Tend_sim - s.T0, m.Tend_exp - s.T0, sim.out.reason{1}, sum(sim.out.nfev), wall);
            if any(strcmp(sim.out.reason, 'solver_failed'))
                fprintf('  !!! bo giai that bai o %s cell %s bien the %s (ghi vao bang, khong dung job)\n', tag, cellid, vname{v});
            end
            rows(end+1,:) = {tag, vname{v}, crate, Tdeg, str2double(cellid), si, s.Vrest0, s.T0, s.Imean, sim.q0, ...
                1e3*m.rmseV, 1e3*m.maxV, m.rmseT, m.maxT, 1e3*m.rmseVr, m.rmseTr, ...
                s.cap, m.cap_sim, m.Tend_exp, m.Tend_sim, s.dTpos, s.dTneg, pars{v}.th.h, ...
                sim.out.reason{1}, wall, sum(sim.out.nfev)}; %#ok<AGROW>
            sims{v} = sim;
        end
        runs(end+1) = struct('cell', cellid, 'idis', si, 'seg', s, 'sims', {sims}); %#ok<AGROW>
    end
end
if isempty(rows), error('Khong co lan xa hop le nao cho %s', tag); end

vn = {'cond', 'variant', 'crate', 'T_degC', 'cell', 'discharge', 'Vrest_V', 'T0_degC', 'I_A', 'q0_Ah', ...
      'rmseV_mV', 'maxerrV_mV', 'rmseT_K', 'maxerrT_K', 'rmseV_rest_mV', 'rmseT_rest_K', ...
      'cap_exp_Ah', 'cap_sim_Ah', 'Tend_exp_degC', 'Tend_sim_degC', 'dTpos_exp_K', 'dTneg_exp_K', 'h_W_m2K', ...
      'stop_reason', 'wall_s', 'rhs_evals'};
Tb = cell2table(rows, 'VariableNames', vn);
writetable(Tb, fullfile(od, 'metrics.csv'));

% ---- CSV duong cong mo phong (lan chay dau tien) va hinh chong ----------
r = runs(1); r.sim = r.sims{2};
if ~isempty(r.sim)
writetable(table(r.sim.t, r.sim.V, r.sim.T - 273.15, r.sim.I, ...
    'VariableNames', {'t_s', 'V_sim', 'T_sim_degC', 'I_A'}), fullfile(od, 'sim_first_run.csv'));
end
plot_overlay(runs, tag, od);
end

% -------------------------------------------------------------------------
function sim = run_one(par, s, T0)
[y0, q0] = dfn_state_from_ocv(par, s.Vrest0, T0);
tdis = s.t(end) - s.t(1);
st(1) = struct('mode', 'I', 'value', s.Imean, 'tmax', 1.5*tdis + 600, 'Tamb', T0, ...
    'stop', struct('Vmin', par.Vmin), 'tout', linspace(0, 1.5*tdis + 600, 2500).');
trest = 7200;
if ~isempty(s.tr), trest = max(s.tr); end
st(2) = struct('mode', 'rest', 'value', 0, 'tmax', trest, 'Tamb', T0, ...
    'stop', struct(), 'tout', [linspace(0, 120, 241).'; linspace(120, trest, 1200).']);
out = dfn_run(par, y0, st);
sim.out = out; sim.q0 = q0;
sim.t = out.t; sim.V = out.V; sim.T = out.T; sim.I = out.I; sim.step = out.step;
i1 = out.step == 1;
sim.tdis = out.t(i1); sim.Vdis = out.V(i1); sim.Tdis = out.T(i1);
sim.tend = sim.tdis(end);
i2 = out.step == 2;
sim.trest = out.t(i2) - sim.tend; sim.Vrest = out.V(i2); sim.Trest = out.T(i2);
end

function m = metrics(sim, s)
% Pha xa: so sanh tren khoang thoi gian chung [0, min(t_sim, t_exp)]
te = s.t - s.t(1);
m.rmseV = NaN; m.maxV = NaN; m.rmseT = NaN; m.maxT = NaN; m.rmseVr = NaN; m.rmseTr = NaN;
m.cap_sim = sim.out.Q(find(sim.out.step == 1, 1, 'last'));
m.Tend_exp = s.T(end); m.Tend_sim = sim.Tdis(end) - 273.15;
if numel(sim.tdis) < 3 || sim.tend <= 0, return; end
tc = min(sim.tend, te(end));
k = te <= tc;
Vs = interp1(sim.tdis, sim.Vdis, te(k));
Ts = interp1(sim.tdis, sim.Tdis, te(k)) - 273.15;
m.rmseV = sqrt(mean((Vs - s.V(k)).^2));
m.maxV  = max(abs(Vs - s.V(k)));
m.rmseT = sqrt(mean((Ts - s.T(k)).^2));
m.maxT  = max(abs(Ts - s.T(k)));
% Pha nghi sau khi xa: thoi gian tinh tu luc ngat dong cua tung ben
if ~isempty(s.tr) && numel(sim.trest) > 2
    k = s.tr <= sim.trest(end) & s.tr > 0;
    [tu, iu] = unique(sim.trest);
    Vs = interp1(tu, sim.Vrest(iu), s.tr(k));
    Ts = interp1(tu, sim.Trest(iu), s.tr(k)) - 273.15;
    m.rmseVr = sqrt(mean((Vs - s.Vr(k)).^2));
    m.rmseTr = sqrt(mean((Ts - s.Tr(k)).^2));
end
end

function plot_overlay(runs, tag, od)
fig = figure('Visible', 'off', 'Position', [100 100 1100 800]);
co = lines(numel(runs));
ax1 = subplot(2,2,1); hold(ax1, 'on'); ax2 = subplot(2,2,2); hold(ax2, 'on');
ax3 = subplot(2,2,3); hold(ax3, 'on'); ax4 = subplot(2,2,4); hold(ax4, 'on');
for i = 1:numel(runs)
    s = runs(i).seg; sim = runs(i).sims{2}; sim1 = runs(i).sims{1};
    if isempty(sim) || isempty(sim1), continue; end
    te = s.t - s.t(1);
    plot(ax1, te/60, s.V, '.', 'Color', co(i,:), 'MarkerSize', 4);
    plot(ax1, sim.tdis/60, sim.Vdis, '-', 'Color', co(i,:), 'LineWidth', 1.2);
    plot(ax1, sim1.tdis/60, sim1.Vdis, '--', 'Color', co(i,:), 'LineWidth', 0.8);
    plot(ax2, te/60, s.T, '.', 'Color', co(i,:), 'MarkerSize', 4);
    plot(ax2, sim.tdis/60, sim.Tdis - 273.15, '-', 'Color', co(i,:), 'LineWidth', 1.2);
    plot(ax2, sim1.tdis/60, sim1.Tdis - 273.15, '--', 'Color', co(i,:), 'LineWidth', 0.8);
    if ~isempty(s.tr)
        plot(ax3, s.tr/60, s.Vr, '.', 'Color', co(i,:), 'MarkerSize', 4);
        plot(ax3, sim.trest/60, sim.Vrest, '-', 'Color', co(i,:), 'LineWidth', 1.2);
        plot(ax4, s.tr/60, s.Tr, '.', 'Color', co(i,:), 'MarkerSize', 4);
        plot(ax4, sim.trest/60, sim.Trest - 273.15, '-', 'Color', co(i,:), 'LineWidth', 1.2);
        plot(ax4, sim1.trest/60, sim1.Trest - 273.15, '--', 'Color', co(i,:), 'LineWidth', 0.8);
    end
end
xlabel(ax1, 'Thoi gian xa (phut)'); ylabel(ax1, 'Dien ap (V)');
title(ax1, ['Xa ' strrep(tag, '_', ' ') ': diem = do, lien = DFN code, dut = DFN paper'], 'Interpreter', 'none');
xlabel(ax2, 'Thoi gian xa (phut)'); ylabel(ax2, 'Nhiet do be mat (degC)');
title(ax2, 'Nhiet do be mat', 'Interpreter', 'none');
xlabel(ax3, 'Thoi gian nghi (phut)'); ylabel(ax3, 'Dien ap (V)'); title(ax3, 'Nghi sau khi xa');
xlabel(ax4, 'Thoi gian nghi (phut)'); ylabel(ax4, 'Nhiet do be mat (degC)'); title(ax4, 'Nghi sau khi xa');
grid(ax1, 'on'); grid(ax2, 'on'); grid(ax3, 'on'); grid(ax4, 'on');
print(fig, fullfile(od, ['overlay_' tag '.png']), '-dpng', '-r110');
close(fig);
end
