function grid_build_all(prep_json, variant, root, mex_dir, nw)
%GRID_BUILD_ALL  Tao song song cac bo giai con thieu cua mot job (GD-98): moi vector so buoc
% IRK trong prep_json (do pilot_run phase 'prep' ghi) mot bo giai, bo qua bo giai da co
% (<root>/<ma>/ok, vd tu actions/cache).
p = jsondecode(fileread(prep_json));
codes = {}; nss = {};
for i = 1:numel(p)
    if ~any(strcmp(codes, p(i).code)), codes{end+1} = p(i).code; nss{end+1} = p(i).ns(:).'; end %#ok<AGROW>
end
todo = find(cellfun(@(c) ~exist(fullfile(root, c, 'ok'), 'file'), codes));
for i = setdiff(1:numel(codes), todo), fprintf('bo giai %s: co san (cache)\n', codes{i}); end
if isempty(todo), return; end
grid_pool(min(nw, numel(todo)));
F = parallel.FevalFuture.empty;
for i = todo
    fprintf('bo giai %s: tao moi\n', codes{i});
    F(end+1) = parfeval(@grid_build, 0, variant, nss{i}, root, mex_dir); %#ok<AGROW>
end
wait(F);
for i = 1:numel(F)
    fprintf('%s', F(i).Diary);
    if ~isempty(F(i).Error), fprintf('LOI tao bo giai %s: %s\n', codes{todo(i)}, F(i).Error.message); end
end
end
