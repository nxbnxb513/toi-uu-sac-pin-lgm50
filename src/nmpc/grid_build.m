function grid_build(variant, ns, root, mex_dir)
%GRID_BUILD  Tao truoc bo giai acados cho luoi day du (GD-98): cung cach dung bo giai nhu
% pilot_run.m (par = dfn_params(), ROM 'D', nmpc_config, nmpc_variant(variant)), chi khac so
% buoc IRK ns (vector 1 x N). Ghi vao <root>/<ma so buoc>/c_generated_code va danh dau
% <root>/<ma>/ok khi xong. pilot_run(..., gopt.solver_root = root) dung lai bo giai nay.
par = dfn_params();
rom = rom_setup(par, 'D');
M = rom_model(rom, par);
cfgn = nmpc_config(par);
bo = struct('N', cfgn.N, 'Imax', cfgn.Imax, 'E', M.E);
bo = nmpc_variant(bo, variant);
bo.num_steps = ns(:).';
code = steps_code(bo.num_steps);
d = fullfile(root, code);
if ~exist(d, 'dir'), mkdir(d); end
bo.codegen_dir = fullfile(d, 'c_generated_code');
if ~isempty(mex_dir), bo.mex_dir = mex_dir; end
cd(d);
C = nmpc_build(rom, par, bo);
fprintf('grid_build %s: tao + bien dich %.1f s\n', code, C.t_build);
fid = fopen(fullfile(d, 'ok'), 'w'); fprintf(fid, '%s\n', mat2str(bo.num_steps)); fclose(fid);
end

function c = steps_code(ns)
c = ''; i = 1;
while i <= numel(ns)
    j = i; while j < numel(ns) && ns(j+1) == ns(i), j = j + 1; end
    if j > i, p = sprintf('%dx%d', ns(i), j - i + 1); else, p = sprintf('%d', ns(i)); end
    if isempty(c), c = p; else, c = [c '-' p]; end %#ok<AGROW>
    i = j + 1;
end
end
