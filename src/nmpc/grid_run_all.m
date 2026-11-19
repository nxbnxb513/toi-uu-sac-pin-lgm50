function grid_run_all(iw, Cbase, Tamb_C, variant, ks, outdir, gopt, nw)
%GRID_RUN_ALL  Chay cac muc k cua mot job song song (GD-98): moi k mot lan pilot_run tren mot
% worker; k nao bat dau khi con < gopt.min_start_s toi gopt.deadline thi pilot_run bo qua.
% Nhat ky tung k: <outdir>/log_k<k>.txt.
grid_pool(min(nw, numel(ks)));
F = parallel.FevalFuture.empty;
for k = ks(:).'
    F(end+1) = parfeval(@one, 0, iw, Cbase, Tamb_C, variant, k, outdir, gopt); %#ok<AGROW>
end
for i = 1:numel(F)
    [idx] = fetchNext(F);
    fprintf('===== k so %d xong (%s)\n', ks(idx), datestr(now, 'HH:MM:SS'));
    if ~isempty(F(idx).Error), fprintf('LOI: %s\n', F(idx).Error.message); end
end
end

function one(iw, Cbase, Tamb_C, variant, k, outdir, gopt)
diary(fullfile(outdir, sprintf('log_k%d.txt', k)));
c = onCleanup(@() diary('off'));
pilot_run(iw, Cbase, k, outdir, 'D', variant, Tamb_C, 330, gopt);
end
