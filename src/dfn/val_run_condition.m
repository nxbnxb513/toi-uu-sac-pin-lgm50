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
%   base      : dung nhu ma nguon Li 2025 (h = 20, co khuech tan do ung suat, khong co nhiet R_contact)
%   Rc_heat   : them nhiet I^2.R_contact vao can bang nhiet (GD-05)
%   no_stress : tat khuech tan do ung suat (DFN nhu mo ta trong bai/SI; GD-10)
%   h15       : h = 15 W/m2/K nhu O'Regan 2022 (tr. 32) thay cho h = 20 cua Li 2025
vname = {'base', 'Rc_heat', 'no_stress', 'h15'};
pars  = {dfn_params(), dfn_params(struct('contact_heat', true)), ...
         dfn_params(struct('stress_diffusion', false)), dfn_params(struct('h', 15))};
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
            tic; sim = run_one(pars{v}, s, T0); wall = toc;
            m = metrics(sim, s);
            fprintf(['  cell %s xa %d [%-9s]: Vrest=%.4f V, T0=%.1f C, I=%.3f A, q0=%.3f Ah | ', ...
                     'RMSE_V=%.1f mV, RMSE_T=%.2f K, cap sim/exp=%.3f/%.3f Ah, dT sim/exp=%.1f/%.1f K, %s, %d buoc, %.1f s\n'], ...
                cellid, si, vname{v}, s.Vrest0, s.T0, s.Imean, sim.q0, 1e3*m.rmseV, m.rmseT, ...
                m.cap_sim, s.cap, m.Tend_sim - s.T0, m.Tend_exp - s.T0, sim.out.reason{1}, sum(sim.out.nsteps), wall);
            if any(strcmp(sim.out.reason, 'solver_failed'))
                error('val_run_condition: bo giai that bai o %s cell %s bien the %s', tag, cellid, vname{v});
            end
            rows(end+1,:) = {tag, vname{v}, crate, Tdeg, str2double(cellid), si, s.Vrest0, s.T0, s.Imean, sim.q0, ...
                1e3*m.rmseV, 1e3*m.maxV, m.rmseT, m.maxT, 1e3*m.rmseVr, m.rmseTr, ...
                s.cap, m.cap_sim, m.Tend_exp, m.Tend_sim, sim.out.reason{1}, wall, sum(sim.out.nsteps)}; %#ok<AGROW>
            sims{v} = sim;
        end
        runs(end+1) = struct('cell', cellid, 'idis', si, 'seg', s, 'sims', {sims}); %#ok<AGROW>
    end
end
if isempty(rows), error('Khong co lan xa hop le nao cho %s', tag); end

vn = {'cond', 'variant', 'crate', 'T_degC', 'cell', 'discharge', 'Vrest_V', 'T0_degC', 'I_A', 'q0_Ah', ...
      'rmseV_mV', 'maxerrV_mV', 'rmseT_K', 'maxerrT_K', 'rmseV_rest_mV', 'rmseT_rest_K', ...
      'cap_exp_Ah', 'cap_sim_Ah', 'Tend_exp_degC', 'Tend_sim_degC', 'stop_reason', 'wall_s', 'ode_steps'};
Tb = cell2table(rows, 'VariableNames', vn);
writetable(Tb, fullfile(od, 'metrics.csv'));

% ---- CSV duong cong mo phong (lan chay dau tien) va hinh chong ----------
r = runs(1); r.sim = r.sims{1};
writetable(table(r.sim.t, r.sim.V, r.sim.T - 273.15, r.sim.I, ...
    'VariableNames', {'t_s', 'V_sim', 'T_sim_degC', 'I_A'}), fullfile(od, 'sim_first_run.csv'));
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
tc = min(sim.tend, te(end));
k = te <= tc;
Vs = interp1(sim.tdis, sim.Vdis, te(k));
Ts = interp1(sim.tdis, sim.Tdis, te(k)) - 273.15;
m.rmseV = sqrt(mean((Vs - s.V(k)).^2));
m.maxV  = max(abs(Vs - s.V(k)));
m.rmseT = sqrt(mean((Ts - s.T(k)).^2));
m.maxT  = max(abs(Ts - s.T(k)));
m.cap_sim = sim.out.Q(find(sim.out.step == 1, 1, 'last'));
m.Tend_exp = s.T(end); m.Tend_sim = sim.Tdis(end) - 273.15;
% Pha nghi sau khi xa: thoi gian tinh tu luc ngat dong cua tung ben
m.rmseVr = NaN; m.rmseTr = NaN;
if ~isempty(s.tr) && ~isempty(sim.trest)
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
    s = runs(i).seg; sim = runs(i).sims{1}; sim1 = runs(i).sims{3};
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
title(ax1, ['Xa ' strrep(tag, '_', ' ') ': diem = do, lien = DFN base, dut = no stress'], 'Interpreter', 'none');
xlabel(ax2, 'Thoi gian xa (phut)'); ylabel(ax2, 'Nhiet do be mat (degC)');
title(ax2, 'Nhiet do be mat', 'Interpreter', 'none');
xlabel(ax3, 'Thoi gian nghi (phut)'); ylabel(ax3, 'Dien ap (V)'); title(ax3, 'Nghi sau khi xa');
xlabel(ax4, 'Thoi gian nghi (phut)'); ylabel(ax4, 'Nhiet do be mat (degC)'); title(ax4, 'Nghi sau khi xa');
grid(ax1, 'on'); grid(ax2, 'on'); grid(ax3, 'on'); grid(ax4, 'on');
print(fig, fullfile(od, ['overlay_' tag '.png']), '-dpng', '-r110');
close(fig);
end
