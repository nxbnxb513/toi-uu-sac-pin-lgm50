function make_report(indir, outdir)
%MAKE_REPORT  Gop ket qua cua tat ca cac vung sac thanh bang thong ke va hinh.
%   Doc moi file window_*.csv trong indir (ke ca thu muc con).

if nargin < 1, indir = 'results'; end
if nargin < 2, outdir = indir; end
if ~exist(outdir, 'dir'), mkdir(outdir); end

files = dir(fullfile(indir, '**', 'window_*.csv'));
T = table();
for i = 1:numel(files)
    f = fullfile(files(i).folder, files(i).name);
    try
        Ti = readtable(f);
        if height(Ti) > 0, T = [T; Ti]; end %#ok<AGROW>
    catch err
        fprintf('Bo qua %s: %s\n', f, err.message);
    end
end
if isempty(T), error('Khong tim thay ket qua nao trong %s', indir); end
T = sortrows(T, {'c_base', 'soc_lo', 'soc_hi'});
writetable(T, fullfile(outdir, 'summary.csv'));

% ---- Bang Markdown ------------------------------------------------------
fid = fopen(fullfile(outdir, 'summary.md'), 'w');
fprintf(fid, '# Thong ke: profile toi uu so voi CCCV theo tung vung sac\n\n');
fprintf(fid, 'Lao hoa = Li mat vao SEI + Li chet + Li ma con lai sau khi nghi (Ah moi lan sac).\n\n');
cb = unique(T.c_base);
for j = 1:numel(cb)
    S = T(T.c_base == cb(j), :);
    fprintf(fid, '## Baseline CCCV %.2gC\n\n', cb(j));
    fprintf(fid, '| Vung sac | Thoi gian (phut) | Lao hoa CCCV (uAh) | Lao hoa toi uu (uAh) | Giam (%%) | eta_Li min CCCV (mV) | eta_Li min toi uu (mV) | C-rate toi uu theo doan |\n');
    fprintf(fid, '|---|---|---|---|---|---|---|---|\n');
    for k = 1:height(S)
        cc = S{k, startsWith(S.Properties.VariableNames, 'c_opt_')};
        fprintf(fid, '| %d -> %d %% | %.1f | %.2f | %.2f | %.2f | %.1f | %.1f | %s |\n', ...
            S.soc_lo(k), S.soc_hi(k), S.t_base_s(k)/60, 1e6*S.aging_base_Ah(k), ...
            1e6*S.aging_opt_Ah(k), S.reduction_pct(k), 1e3*S.etaLi_min_base_V(k), ...
            1e3*S.etaLi_min_opt_V(k), strjoin(compose('%.2f', cc), ' / '));
    end
    fprintf(fid, '\nTrung binh muc giam: %.2f %%; lon nhat: %.2f %%; nho nhat: %.2f %%.\n\n', ...
        mean(S.reduction_pct), max(S.reduction_pct), min(S.reduction_pct));
end
fclose(fid);

% ---- Hinh: ban do muc giam lao hoa theo vung sac -----------------------
for j = 1:numel(cb)
    S = T(T.c_base == cb(j), :);
    lo = unique(S.soc_lo); hi = unique(S.soc_hi);
    M = nan(numel(lo), numel(hi)); A = M;
    for k = 1:height(S)
        a = find(lo == S.soc_lo(k)); b = find(hi == S.soc_hi(k));
        M(a, b) = S.reduction_pct(k);
        A(a, b) = 1e6*S.aging_base_Ah(k)/(S.soc_hi(k) - S.soc_lo(k))*100;
    end
    fig = figure('Visible', 'off', 'Position', [100 100 1100 450]);
    subplot(1, 2, 1);
    imagesc(hi, lo, M, 'AlphaData', ~isnan(M)); colorbar; axis xy;
    xlabel('SOC ket thuc (%)'); ylabel('SOC bat dau (%)');
    title(sprintf('Muc giam lao hoa so voi CCCV %.2gC (%%)', cb(j)));
    subplot(1, 2, 2);
    imagesc(hi, lo, A, 'AlphaData', ~isnan(A)); colorbar; axis xy;
    xlabel('SOC ket thuc (%)'); ylabel('SOC bat dau (%)');
    title('Lao hoa cua CCCV, quy ve 100 % SOC nap (uAh)');
    print(fig, fullfile(outdir, sprintf('heatmap_c%03d.png', round(100*cb(j)))), '-dpng', '-r130');
    close(fig);
end
fprintf('Da ghi summary.csv, summary.md va cac hinh vao %s\n', outdir);
end
