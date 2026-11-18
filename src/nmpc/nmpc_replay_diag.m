function T = nmpc_replay_diag(indir, outdir, romcfg)
%NMPC_REPLAY_DIAG  Chan doan "du doan cua ROM vs cham diem tren DFN" (18/11/2026).
% Lay profile dong sac DA AP len DFN (CCCV va NMPC, file *_series.csv cua pilot_run)
% va cho ROM (da khu z, CUNG mo hinh trong acados, rom_elim.m) chay lai voi dung
% profile do tu cung trang thai dau. So sanh lithium mat (SEI, Li ma) cua ROM voi so
% hau kiem tren DFN (aging_track.m, CUNG cong thuc aging_rates.m) tren pha SAC.
% Muc dich: biet NMPC thua CCCV 0.5C la do ROM lech (sai so cau truc) hay do bo
% toi uu khong tim ra nghiem tot (ROM cung cho CCCV it mat hon).
%   indir: thu muc chua pilot_w*_T*_cccv_series.csv va pilot_w*_k*_nmpc_series.csv
if nargin < 2 || isempty(outdir), outdir = indir; end
if nargin < 3 || isempty(romcfg), romcfg = 'D'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
par = dfn_params(); rom = rom_setup(par, romcfg); M = rom_model(rom, par); E = M.E;
W = soc_windows();
f = dir(fullfile(indir, '**', 'pilot_w*_series.csv'));
names = unique({f.name});
rows = {};
for i = 1:numel(names)
    nm = names{i};
    tk = regexp(nm, 'pilot_w(\d+)_c(\d+)_T(\d+)_(cccv|k\d+)', 'tokens', 'once');
    if isempty(tk), continue; end
    j = find(strcmp({f.name}, nm), 1);
    S = readtable(fullfile(f(j).folder, nm));
    iw = str2double(tk{1}); Cb = str2double(tk{2})/10; Tc = str2double(tk{3}); kind = tk{4};
    Ta = 273.15 + Tc; soc0 = W(iw, 1);
    [t, ia] = unique(S.t_s); Ich = S.I_A(ia);
    % trang thai dau: nhu nmpc_closed_loop.m (nghi can bang tai soc0, nhat quan voi I = 0)
    y = dfn_state_soc(par, soc0, Ta);
    yc = dfn_consistent_init(0, y, par, struct('mode', 'I', 'value', 0, 'Tamb', Ta));
    x0 = rom_from_dfn(rom, par, yc);
    Ifun = @(tt) -interp1(t, Ich, min(max(tt, t(1)), t(end)), 'linear');
    tw = tic;
    r = rom_sim_ode(E, M, rom, x0, Ifun, Ta, t, struct('sat', false));
    wall = toc(tw);
    n = numel(r.t);
    loss_rom = r.nsei(end) + r.ndl(end);
    sei_dfn = S.sei_mAh(ia(n));          % DFN tai cung thoi diem ket thuc cua ROM
    sei_dfn_end = S.sei_mAh(end);
    eV = r.V - S.V(ia(1:n)); eE = 1e3*(r.eta_sep - S.eta_sep_mV(ia(1:n))/1e3);
    % toc do SEI theo thoi gian: chia 4 doan bang nhau
    q = round(linspace(1, n, 5));
    dS_rom = diff(r.nsei(q)); dS_dfn = diff(S.sei_mAh(ia(q)));
    rows(end+1, :) = {iw, sprintf('%g-%g', 100*W(iw, 1), 100*W(iw, 2)), Cb, kind, t(end), r.t(end), r.reason, ...
        loss_rom, r.nsei(end), r.ndl(end), sei_dfn, sei_dfn_end, 100*(r.nsei(end)/sei_dfn - 1), ...
        sqrt(mean(eV.^2))*1e3, max(abs(eV))*1e3, sqrt(mean(eE.^2)), max(abs(eE)), min(r.eta_sep)*1e3, min(S.eta_sep_mV), ...
        mat2str(round(100*(dS_rom./dS_dfn - 1), 2).'), wall}; %#ok<AGROW>
    fprintf('%s: ROM %s t %.0f/%.0f s; SEI ROM %.6f DFN %.6f mAh (lech %+.2f %%); Li chet ROM %.2e; V RMS %.1f mV; eta RMS %.1f mV; lech SEI theo 4 doan %s %%\n', ...
        nm, r.reason, r.t(end), t(end), r.nsei(end), sei_dfn, 100*(r.nsei(end)/sei_dfn - 1), r.ndl(end), ...
        sqrt(mean(eV.^2))*1e3, sqrt(mean(eE.^2)), rows{end, 20});
end
T = cell2table(rows, 'VariableNames', {'iw', 'window', 'Cbase', 'run', 't_dfn_s', 't_rom_s', 'rom_reason', ...
    'rom_loss_mAh', 'rom_sei_mAh', 'rom_dead_mAh', 'dfn_sei_mAh', 'dfn_sei_end_mAh', 'sei_bias_pct', ...
    'V_rms_mV', 'V_max_mV', 'eta_rms_mV', 'eta_max_mV', 'rom_eta_min_mV', 'dfn_eta_min_mV', 'sei_bias_quarters_pct', 'wall_s'});
T = sortrows(T, {'iw', 'Cbase', 'run'});
writetable(T, fullfile(outdir, 'replay_diag.csv'));
fid = fopen(fullfile(outdir, 'replay_diag.md'), 'w');
fprintf(fid, '# ROM chay lai profile dong da ap len DFN (pha sac)\n\n');
fprintf(fid, '| vung | CCCV goc | lan chay | t (s) | SEI ROM (mAh) | SEI DFN (mAh) | lech SEI (%%) | Li chet ROM (mAh) | V RMS (mV) | eta RMS / max (mV) | eta min ROM / DFN (mV) | lech SEI 4 doan (%%) |\n|---|---|---|---|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    r = T(i, :);
    fprintf(fid, '| %s | %gC | %s | %.0f | %.6f | %.6f | %+.2f | %.2e | %.1f | %.1f / %.1f | %.1f / %.1f | %s |\n', r.window{1}, r.Cbase, r.run{1}, ...
        r.t_dfn_s, r.rom_sei_mAh, r.dfn_sei_mAh, r.sei_bias_pct, r.rom_dead_mAh, r.V_rms_mV, r.eta_rms_mV, r.eta_max_mV, ...
        r.rom_eta_min_mV, r.dfn_eta_min_mV, r.sei_bias_quarters_pct{1});
end
fclose(fid);
txt = fileread(fullfile(outdir, 'replay_diag.md'));
sf = getenv('GITHUB_STEP_SUMMARY');
if ~isempty(sf), fs = fopen(sf, 'a'); fprintf(fs, '%s', txt); fclose(fs); end
fprintf('%s', txt);
end
