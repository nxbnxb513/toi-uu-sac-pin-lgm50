function status = ag_run(expt, TdegC, outdir, opt)
%AG_RUN  Mo phong thi nghiem lao hoa Li 2025 (Expt 2: 70-85 %, Expt 3: 85-100 %; buoc D them
% Expt 1: 0-30 %, Expt 5: 0-100 % cua Kirkaldy 2024) bang DFN
% + mo hinh lao hoa "5 coupled", co diem luu (checkpoint) de chay noi tiep nhieu job CI.
%   status = ag_run(expt, TdegC, outdir, opt)   status = 'done' | 'incomplete'
% opt: .variant ('default'), .Jmax (20; 0 = brute force), .nsets (12), .N (515; Expt 1: 258, Expt 5: 78),
%      .budget_s (5.0 h: dung va luu khi vuot), .ckpt_every_s (900)
% Giao thuc (dac_ta_lao_hoa.md muc 13; GD-59):
%   break-in (theo code): tu 100 % SOC (x100, y100, Li 2025 SI Table 6), 25 C: xa 0.5C toi
%   4.0 V; sac CCCV 0.3C; nghi 1 h. -> RPT0 -> [can kho; ageing set k (T_amb = T);
%   can kho; RPT k] k = 1..nsets.  Can kho (dfn_dryout_update) truoc moi set va moi RPT.
if nargin < 4, opt = struct(); end
% N mac dinh theo thi nghiem (Kirkaldy 2024 Table 1): Expt 2/3 515, Expt 1 258, Expt 5 78
Ndef = 515; if expt == 1, Ndef = 258; elseif expt == 5, Ndef = 78; end
opt = defaults(opt, struct('variant', 'default', 'Jmax', 20, 'nsets', 12, 'N', Ndef, ...
    'budget_s', 5.0*3600, 'ckpt_every_s', 900));
if ~exist(outdir, 'dir'), mkdir(outdir); end
ck = fullfile(outdir, 'checkpoint.mat');
tic0 = tic;
par0 = ag_par(expt, opt.variant);
Tamb = TdegC + 273.15; T25 = 298.15;
if exist(ck, 'file')
    S = load(ck); S = S.S;
    % checkpoint cua ban truoc 18/11/2026: them truong moi, doi dinh nghia SOH (GD-60)
    if ~isfield(S.set, 'nback'), S.set.nback = 0; end
    if ~isfield(S.set, 'Jcur'), S.set.Jcur = []; end
    if ~isempty(S.rows) && isfield(S.rows, 'SOH_code_pct')
        for ir = 1:numel(S.rows)
            S.rows(ir).SOH_pct = 100*S.rows(ir).Qdis01_Ah/4.865;
            S.rows(ir).SOH_code_pct = 100*S.rows(ir).Qdis01_Ah/S.Q0;
        end
        S.rows = cell2struct(struct2cell(S.rows), strrep(fieldnames(S.rows), 'SOH_code_pct', 'SOH_rpt0_pct'), 1);
    end
    fprintf('ag_run: tiep tuc tu checkpoint: stage %d, set %d chu ky %d\n', S.stage, S.k, S.set.n);
else
    S = struct();
    S.expt = expt; S.T = TdegC; S.opt = opt;
    y = dfn_init_state(par0, par0.neg.x100, par0.pos.y100, T25);
    S.y = y; S.A = par0.A; S.dry = dfn_dryout_init(par0, y); S.yseg = y;
    S.stage = 0;          % 0 break-in, 1 RPT0, 2 set, 3 RPT sau set
    S.k = 0;              % set hien tai
    S.set = newset(); S.rows = []; S.cyc = zeros(0, 9); S.inv0 = [];
    S.Li0 = dfn_li_inventory(par0, y).total + S.dry.Vres*S.dry.ce_res;
    S.wall = 0; S.tsim = 0; S.jump_err_max = 0; S.dry_info = {};
end
par = dfn_set_area(par0, S.A);
y = S.y;
wall0 = S.wall;
lastck = toc(tic0);
deadline = opt.budget_s;
status = 'incomplete';
try
while true
    if toc(tic0) > deadline, break; end
    switch S.stage
        case 0   % break-in (theo code)
            st = [ag_step('I', 0.5*par.Qnom, 5*3600, T25, struct('Vmin', 4.0)), ag_cccv(par, 0.3*par.Qnom, T25, 3600)];
            [y, o, ok] = ag_exec(par, y, st);
            if ~ok, error('ag_run: break-in that bai'); end
            S.tsim = S.tsim + o.t(end);
            S.stage = 1;
        case 1   % RPT0
            [y, r] = ag_rpt(par, y, expt, true);
            S.inv0 = r.inv; S.Q0 = r.Qdis01; S.R0 = r.R12;
            S.wall = wall0 + toc(tic0);
            S = addrow(S, par, y, r, 0);
            S.stage = 2; S.k = 1; S.set = newset();
        case 2   % ageing set k
            if S.set.n == 0 && ~S.set.dry_done
                [par, y, S] = dryout(par, y, S, sprintf('truoc set %d', S.k));
                S.set.dry_done = true;
            end
            sopt = struct('N', opt.N, 'Jmax', opt.Jmax, 'deadline', min(deadline, lastck + opt.ckpt_every_s), 'tic0', tic0);
            [y, S.set, clog] = ag_set(par, y, expt, Tamb, S.set, sopt);
            S.cyc = [S.cyc; [S.k*ones(size(clog,1),1), clog]];
            if S.set.n >= opt.N
                S.tsim = S.tsim + S.set.t; S.jump_err_max = max(S.jump_err_max, S.set.jump_err_max);
                S.stage = 3;
                fprintf('ag_run: xong set %d: %d chu ky mo phong, %d nhay, %d lan lui; %.0f s tuong\n', S.k, S.set.nsim, S.set.njump, S.set.nback, toc(tic0));
            end
        case 3   % dry-out + RPT k
            [par, y, S] = dryout(par, y, S, sprintf('truoc RPT %d', S.k));
            [y, r] = ag_rpt(par, y, expt, false);
            S.wall = wall0 + toc(tic0);
            S = addrow(S, par, y, r, S.k);
            if S.k >= opt.nsets
                S.stage = 4;
            else
                S.k = S.k + 1; S.stage = 2; S.set = newset();
            end
        case 4
            status = 'done';
            break
    end
    if toc(tic0) - lastck > opt.ckpt_every_s || S.stage == 4
        savec(); lastck = toc(tic0);
    end
end
catch err
    % khong luu checkpoint (trang thai co the hong); ghi ket qua da co roi bao loi
    fprintf('ag_run: LOI: %s\n', err.message);
    write_outputs(S, outdir, 'error');
    rethrow(err);
end
savec();
write_outputs(S, outdir, status);
fprintf('ag_run: Expt %d, %g C, %s: %s (%.0f s tuong lan nay)\n', expt, TdegC, opt.variant, status, toc(tic0));

    function savec()
        S.y = y; S.A = par.A; S.wall = wall0 + toc(tic0);
        save(ck, 'S', '-v7');
    end
end

function st = newset()
st = struct('n', 0, 'nsim', 0, 'njump', 0, 't', 0, 'jump_err_max', 0, 'dry_done', false, 'Jcur', [], 'nback', 0);
st.reasons = {};
end

function [par, y, S] = dryout(par, y, S, label)
Lb = dfn_li_inventory(par, y);
totb = Lb.total + S.dry.Vres*S.dry.ce_res + S.dry.n_dry;
[par, y, S.dry, info] = dfn_dryout_update(par, S.yseg, y, S.dry);
La = dfn_li_inventory(par, y);
tota = La.total + S.dry.Vres*S.dry.ce_res + S.dry.n_dry;
info.label = label; info.Li_jump_rel = (tota - totb)/totb;
S.dry_info{end+1} = info;
S.yseg = y;
end

function S = addrow(S, par, y, r, k)
inv = r.inv; i0 = S.inv0;
p0 = i0.part_n + i0.part_p;
tot = inv.total + S.dry.Vres*S.dry.ce_res + S.dry.n_dry;
row.rpt = k;
row.Qthr_Ah = inv.Qthr;
row.t_h = S.tsim/3600;
row.Qdis01_Ah = r.Qdis01;
row.SOH_pct = 100*r.Qdis01/4.865;                  % MAC DINH (nguoi dung chot 17/11/2026, GD-60):
                                                   % chia cho 4.865 Ah co dinh (Li 2025, dung luong dau LG M50T)
row.SOH_rpt0_pct = 100*r.Qdis01/S.Q0;              % phu: chuan hoa theo RPT0 cua chinh mo hinh
row.LLI_pct = 100*(1 - (inv.part_n + inv.part_p)/p0);
row.LAM_NE_pct = 100*(1 - inv.Cn/i0.Cn);
row.LAM_PE_pct = 100*(1 - inv.Cp/i0.Cp);
row.LAM_dry_pct = 100*(1 - S.dry.A/S.dry.Amax);
row.R_mOhm = 1e3*r.R12;
if isfield(inv, 'CSi')
    % tang 2 (gia dinh): LAM silicon / graphite (ke ca phan can kho qua dien tich A)
    row.LAM_Si_pct = 100*(1 - inv.CSi/i0.CSi);
    row.LAM_Gr_pct = 100*(1 - (inv.Cn - inv.CSi)/(i0.Cn - i0.CSi));
    row.si_k = par.ag.si.k; row.si_form = par.ag.si.form;
end
% phan ra LLI (phan tram cua Li trong hat tai RPT0)
row.LLI_SEI_pct   = 100*(inv.sei - i0.sei)/p0;
row.LLI_SEIcr_pct = 100*(inv.seicr - i0.seicr)/p0;
row.LLI_pl_pct    = 100*(inv.plated - i0.plated)/p0;
row.LLI_dead_pct  = 100*(inv.dead - i0.dead)/p0;
row.LLI_LAM_pct   = 100*((inv.lam_n + inv.lam_p) - (i0.lam_n + i0.lam_p))/p0;
row.LLI_dry_pct   = 100*S.dry.n_dry/p0;
row.LLI_elyte_pct = 100*((inv.elyte + S.dry.Vres*S.dry.ce_res) - i0.elyte)/p0;
row.Li_cons_rel = (tot - S.Li0)/S.Li0;              % sai lech bao toan Li tong (ke ca reservoir, phan kho)
row.xav_err = inv.xav_err;
row.A_m2 = par.A;
row.eps_n_min = min(dfn_aging_state(par, r.ydis).eps(1:par.grid.Nn));
row.lcr_max = max(r.ydis(par.ix.ag.lcr));
row.Vres_mL = 1e6*S.dry.Vres;
row.cEC = S.dry.cEC;
row.jump_err_max = S.jump_err_max;
row.wall_h = (S.wall)/3600;
if isempty(S.rows), S.rows = row; else, S.rows(end+1) = row; end
fprintf('RPT %2d: Qthr %.0f Ah, SOH %.2f %%, LLI %.2f %%, LAM_NE %.2f %%, LAM_PE %.2f %%, R %.2f mOhm, Li %.1e\n', ...
    k, row.Qthr_Ah, row.SOH_pct, row.LLI_pct, row.LAM_NE_pct, row.LAM_PE_pct, row.R_mOhm, row.Li_cons_rel);
if isfield(row, 'LAM_Si_pct'), fprintf('        tang 2: LAM_Si %.2f %%, LAM_Gr %.2f %%\n', row.LAM_Si_pct, row.LAM_Gr_pct); end
end

function write_outputs(S, outdir, status)
if ~isempty(S.rows)
    Tt = struct2table(S.rows);
    Tt.expt = repmat(S.expt, height(Tt), 1); Tt.T_degC = repmat(S.T, height(Tt), 1);
    Tt.variant = repmat({S.opt.variant}, height(Tt), 1); Tt.Jmax = repmat(S.opt.Jmax, height(Tt), 1);
    writetable(Tt, fullfile(outdir, 'rpt.csv'));
end
if ~isempty(S.cyc)
    C = array2table(S.cyc, 'VariableNames', {'set', 'n', 'Qthr_Ah', 'dur_s', 'Tmax_K', 'Vmin', 'Vmax', 'ok', 'jumped'});
    writetable(C, fullfile(outdir, 'cycles.csv'));
end
if ~isempty(S.dry_info)
    D = struct2table([S.dry_info{:}]);
    writetable(D, fullfile(outdir, 'dryout.csv'));
end
fid = fopen(fullfile(outdir, 'status.txt'), 'w');
fprintf(fid, '%s\nexpt %d T %g variant %s Jmax %d\nstage %d set %d cycle %d\nwall_h %.3f\n', status, S.expt, S.T, ...
    S.opt.variant, S.opt.Jmax, S.stage, S.k, S.set.n, S.wall/3600);
fclose(fid);
end

function o = defaults(o, d)
fn = fieldnames(d);
for i = 1:numel(fn)
    if ~isfield(o, fn{i}) || isempty(o.(fn{i})), o.(fn{i}) = d.(fn{i}); end
end
end
