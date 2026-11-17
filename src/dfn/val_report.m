function val_report(indir, outdir)
%VAL_REPORT  Gop metrics.csv cua cac dieu kien thanh results/validation.md,
% validation.csv (tung lan xa, tung bien the), validation_summary.csv va hinh.
if nargin < 2, outdir = indir; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
fl = dir(fullfile(indir, '**', 'metrics.csv'));
if isempty(fl), error('val_report: khong tim thay metrics.csv trong %s', indir); end
Tb = table();
for i = 1:numel(fl)
    t = readtable(fullfile(fl(i).folder, fl(i).name), 'TextType', 'char', 'Delimiter', ',');
    if ~iscell(t.cond), t.cond = cellstr(t.cond); end
    if ~iscell(t.variant), t.variant = cellstr(t.variant); end
    if ~iscell(t.stop_reason), t.stop_reason = cellstr(t.stop_reason); end
    Tb = [Tb; t]; %#ok<AGROW>
end
Tb = sortrows(Tb, {'variant', 'T_degC', 'crate', 'cell', 'discharge'});
writetable(Tb, fullfile(outdir, 'validation.csv'));
vars = {'paper', 'code', 'code_no_stress', 'code_Rc_heat', 'code_h15', 'code_h_tau'};
vars = vars(ismember(vars, unique(Tb.variant)));
vdesc = {'paper', 'cho nao bai bao in thi dung nhu in: he so dien giai (S14) 0.8353 va (S15) -0.612 (t+ = 5.7, kappa = 2.4 S/m tai 1 M, 25 degC), L_SEI,0 = 1.23625e-8 m moi lop, mat do xop kho nhu SI Table 6; h = 20'; ...
         'code', 'nhung cho do lay theo ma nguon cua tac gia: 0.353 va -6.12 (t+ = 0.22, kappa = 0.91 S/m), L_SEI,0 = 9.2326e-9 m, eps_n = 0.234965; h = 20, co khuech tan do ung suat, khong co nhiet R_contact'; ...
         'code_no_stress', 'code nhung tat khuech tan do ung suat (GD-10)'; ...
         'code_Rc_heat', 'code + nhiet I^2.R_contact trong can bang nhiet (GD-05)'; ...
         'code_h15', 'code nhung h = 15 W/m2/K (gia tri O''Regan 2022 chinh tay cho chinh bo du lieu nay)'; ...
         'code_h_tau', 'code nhung h suy tu hang so thoi gian nguoi do duoc tau = 582 s (data/ket_qua_du_lieu.md A.3): h = rho.c_p,eff.V_cell/(tau.A_cool)'};

% ---- tong hop theo (bien the, T, C-rate) --------------------------------
S = table();
for v = 1:numel(vars)
    Tv = Tb(strcmp(Tb.variant, vars{v}), :);
    [G, Tg, Cg] = findgroups(Tv.T_degC, Tv.crate);
    Sv = table(repmat(vars(v), numel(Tg), 1), Tg, Cg, splitapply(@numel, Tv.cell, G), ...
        splitapply(@(x) mean(x, 'omitnan'), Tv.rmseV_mV, G), splitapply(@(x) std(x, 'omitnan'), Tv.rmseV_mV, G), ...
        splitapply(@(x) mean(x, 'omitnan'), Tv.rmseT_K, G), splitapply(@(x) std(x, 'omitnan'), Tv.rmseT_K, G), ...
        splitapply(@(x) mean(x, 'omitnan'), Tv.rmseV_rest_mV, G), splitapply(@(x) mean(x, 'omitnan'), Tv.rmseT_rest_K, G), ...
        splitapply(@mean, Tv.cap_exp_Ah, G), splitapply(@mean, Tv.cap_sim_Ah, G), ...
        splitapply(@mean, Tv.Tend_exp_degC - Tv.T0_degC, G), splitapply(@mean, Tv.Tend_sim_degC - Tv.T0_degC, G), ...
        splitapply(@mean, Tv.wall_s, G), splitapply(@(x) mean(x, 'omitnan'), Tv.dTpos_exp_K, G), ...
        splitapply(@(x) mean(x, 'omitnan'), Tv.dTneg_exp_K, G), splitapply(@mean, Tv.h_W_m2K, G), ...
        'VariableNames', {'variant', 'T_degC', 'crate', 'n_runs', 'rmseV_mV', 'rmseV_std_mV', 'rmseT_K', 'rmseT_std_K', ...
        'rmseV_rest_mV', 'rmseT_rest_K', 'cap_exp_Ah', 'cap_sim_Ah', 'dT_exp_K', 'dT_sim_K', 'wall_s', ...
        'dTpos_exp_K', 'dTneg_exp_K', 'h_W_m2K'});
    Sv.n_notVmin = splitapply(@(x) sum(~strcmp(x, 'Vmin')), Tv.stop_reason, G);
    S = [S; Sv]; %#ok<AGROW>
end
writetable(S, fullfile(outdir, 'validation_summary.csv'));

fid = fopen(fullfile(outdir, 'validation.md'), 'w');
fprintf(fid, '# Kiem chung mo hinh DFN + nhiet lumped (LG M50) voi du lieu xa mo\n\n');
fprintf(fid, ['- Du lieu: Zenodo 10.5281/zenodo.4864437 (brosaplanella/TEC-reduced-model, BSD-3), cell LG M50, ' ...
    'xa C/10, C/2, 1C, 2C tai 0, 10, 25 degC.\n']);
fprintf(fid, ['- Bo tham so: Li 2025 (Nat. Commun. 16:2776) = O''Regan 2022 + cac muc * (xem src/dfn/dfn_params.m, tai_lieu/gia_dinh.md). ' ...
    'KHONG hieu chinh tham so nao theo bo du lieu nay.\n']);
fprintf(fid, ['- Moi lan xa cua moi cell duoc mo phong rieng: trang thai dau lay tu ap nghi do duoc, ' ...
    'T dau = T moi truong = nhiet do be mat cell ngay truoc khi xa, dong = dong trung binh do duoc, dung o 2.5 V, roi nghi 2 h.\n']);
fprintf(fid, '- RMSE tinh tren khoang thoi gian chung cua mo phong va thi nghiem; "tb +- dlc" la trung binh va do lech chuan qua cac lan xa.\n');
fprintf(fid, ['- Nhiet do mo hinh la MOT gia tri (lumped); no duoc so voi cap nhiet GIUA than cell ("Temp Cell": LogTempMid, hoac LogTemp001 o cell chi co mot cap nhiet). ' ...
    'Be mat cell khong dong deu: cot "dT dau duong / dau am" la do tang nhiet do duoc o hai dau (chi cell co 3 cap nhiet). Do phan giai nhiet do 0.1 K.\n']);
pb = dfn_params(struct('src', 'code'));
Cth = dfn_rhocp(pb, 298.15, dfn_aging_state(pb, []))*pb.th.Vcell;
fprintf(fid, ['- Hang so thoi gian nhiet cua mo hinh (25 degC): C_th = %.1f J/K; tau = C_th/(h.A_cool) = %.0f s voi h = 20, %.0f s voi h = 15. ' ...
    'Do tu pha nguoi cua chinh bo du lieu nay: trung vi 582 s (462 - 911 s; data/ket_qua_du_lieu.md muc A.3). Khong chinh h theo du lieu trong bien the `paper` va `code`.\n'], ...
    Cth, Cth/(20*pb.th.Acool), Cth/(15*pb.th.Acool));
fprintf(fid, '- dT = do tang nhiet do be mat cuoi pha xa.\n- Cac bien the mo hinh:\n');
for v = 1:numel(vars)
    fprintf(fid, '  - `%s`: %s\n', vars{v}, vdesc{strcmp(vdesc(:,1), vars{v}), 2});
end
for v = 1:numel(vars)
    Sv = S(strcmp(S.variant, vars{v}), :); Tv = Tb(strcmp(Tb.variant, vars{v}), :);
    fprintf(fid, '\n## Tong hop theo dieu kien - bien the `%s`\n\n', vars{v});
    fprintf(fid, 'h = %.2f W/m2/K.\n\n', mean(Sv.h_W_m2K));
    fprintf(fid, ['| T (degC) | C-rate | so lan xa | RMSE V xa (mV) | RMSE T xa (K) | RMSE V nghi (mV) | RMSE T nghi (K) | ' ...
        'dung luong do / mo phong (Ah) | dT giua cell: do / mo phong (K) | dT do dau duong / dau am (K) | thoi gian chay 1 mo phong (s) |\n|---|---|---|---|---|---|---|---|---|---|---|\n']);
    for i = 1:height(Sv)
        fprintf(fid, '| %d | %g | %d | %.1f +- %.1f | %.2f +- %.2f | %.1f | %.2f | %.3f / %.3f | %.1f / %.1f | %.1f / %.1f | %.0f |\n', ...
            Sv.T_degC(i), Sv.crate(i), Sv.n_runs(i), Sv.rmseV_mV(i), Sv.rmseV_std_mV(i), Sv.rmseT_K(i), Sv.rmseT_std_K(i), ...
            Sv.rmseV_rest_mV(i), Sv.rmseT_rest_K(i), Sv.cap_exp_Ah(i), Sv.cap_sim_Ah(i), Sv.dT_exp_K(i), Sv.dT_sim_K(i), Sv.dTpos_exp_K(i), Sv.dTneg_exp_K(i), Sv.wall_s(i));
    end
    fprintf(fid, '\n- So lan xa KHONG ket thuc o 2.5 V (bo giai hong, dien giai can kiet, stoich be mat cham gioi han): %d / %d.', sum(~strcmp(Tv.stop_reason, 'Vmin')), height(Tv));
    fprintf(fid, '\n- Trung binh tat ca cac lan xa: RMSE V = %.1f mV; RMSE T = %.2f K.', mean(Tv.rmseV_mV, 'omitnan'), mean(Tv.rmseT_K, 'omitnan'));
    for Tx = unique(Tv.T_degC).'
        k = Tv.T_degC == Tx;
        fprintf(fid, ' %d degC: %.1f mV, %.2f K.', Tx, mean(Tv.rmseV_mV(k), 'omitnan'), mean(Tv.rmseT_K(k), 'omitnan'));
    end
    fprintf(fid, '\n');
end
fprintf(fid, '\n## Sai so da cong bo de doi chieu (chi lay so in trong van ban/bang)\n\n');
fprintf(fid, ['- O''Regan 2022 (tr. 32 ban AAM): RMSE dien ap o C/2 la 0.14 (Chen2020) va 0.10 (bo O''Regan), bai khong ghi don vi; ' ...
    'khong co sai so nhiet do dang so. D_s,p, D_s,n, dU_n/dT va h duoc chinh tay theo chinh bo du lieu nay.\n']);
fprintf(fid, ['- Li 2025 (SI Supplementary Table 1): RMSE duong ap C/10 cua RPT (cell LG M50T, trung binh 13 RPT) = ' ...
    '23.3 - 39.4 mV tuy mo hinh va nhiet do (5 coupled: 23.29 / 25.31 / 28.45 mV o 10 / 25 / 40 degC).\n']);
fprintf(fid, ['- Luu y: bo tham so Li 2025 duoc chinh cho cell LG M50T cua Kirkaldy 2024 (dung luong 4.865 Ah, R_contact = 11.5 mOhm, h = 20, ' ...
    'lam mat day cell), con du lieu kiem chung la cell LG M50 cua O''Regan/Brosa Planella trong buong nhiet; ' ...
    'sai lech he thong giua hai lo cell va hai dieu kien nhiet nam trong cac so RMSE tren.\n']);
Tv = Tb(ismember(Tb.variant, {'paper', 'code'}), :);
fprintf(fid, '\n## Chi tiet tung lan xa (bien the `paper` va `code`)\n\n');
fprintf(fid, '| Bien the | Dieu kien | cell | lan xa | V nghi (V) | T0 (degC) | I (A) | q0 (Ah) | RMSE V (mV) | max dV (mV) | RMSE T (K) | max dT (K) | cap do (Ah) | cap mo phong (Ah) | ly do dung |\n');
fprintf(fid, '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
for i = 1:height(Tv)
    fprintf(fid, '| %s | %s | %d | %d | %.4f | %.1f | %.3f | %.3f | %.1f | %.1f | %.2f | %.2f | %.3f | %.3f | %s |\n', ...
        Tv.variant{i}, Tv.cond{i}, Tv.cell(i), Tv.discharge(i), Tv.Vrest_V(i), Tv.T0_degC(i), Tv.I_A(i), Tv.q0_Ah(i), Tv.rmseV_mV(i), ...
        Tv.maxerrV_mV(i), Tv.rmseT_K(i), Tv.maxerrT_K(i), Tv.cap_exp_Ah(i), Tv.cap_sim_Ah(i), Tv.stop_reason{i});
end
st = dir(fullfile(indir, '**', 'selftest.md'));
if ~isempty(st)
    fprintf(fid, '\n---\n\n%s\n', fileread(fullfile(st(1).folder, st(1).name)));
end
fclose(fid);

% ---- hinh tong hop (bien the code) --------------------------------------
Sb = S(strcmp(S.variant, 'code'), :);
fig = figure('Visible', 'off', 'Position', [100 100 1000 420]);
Ts = unique(Sb.T_degC); Cs = unique(Sb.crate);
MV = nan(numel(Cs), numel(Ts)); MT = MV;
for i = 1:height(Sb)
    MV(Cs == Sb.crate(i), Ts == Sb.T_degC(i)) = Sb.rmseV_mV(i);
    MT(Cs == Sb.crate(i), Ts == Sb.T_degC(i)) = Sb.rmseT_K(i);
end
lg = arrayfun(@(x) sprintf('%d degC', x), Ts, 'UniformOutput', false);
xl = arrayfun(@(x) sprintf('%gC', x), Cs, 'UniformOutput', false);
subplot(1,2,1); bar(MV); set(gca, 'XTick', 1:numel(Cs), 'XTickLabel', xl); ylabel('RMSE dien ap pha xa (mV)'); legend(lg, 'Location', 'northwest'); grid on;
title('DFN (bien the code) so voi du lieu LG M50');
subplot(1,2,2); bar(MT); set(gca, 'XTick', 1:numel(Cs), 'XTickLabel', xl); ylabel('RMSE nhiet do pha xa (K)'); legend(lg, 'Location', 'northwest'); grid on;
print(fig, fullfile(outdir, 'validation_summary.png'), '-dpng', '-r110');
close(fig);
type(fullfile(outdir, 'validation.md'));
end
