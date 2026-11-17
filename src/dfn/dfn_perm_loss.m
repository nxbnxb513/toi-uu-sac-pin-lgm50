function R = dfn_perm_loss(par, y0, chg, opt)
%DFN_PERM_LOSS  Mat lithium VINH VIEN cua mot lan sac roi xa ve SOC dau (cho luoi so sanh,
% buoc H), tinh bang DFN CO lao hoa "5 coupled" day du (hoi tiep vao dong, do xop, mang).
%
%   R = dfn_perm_loss(par, y0, chg)          chg: mang buoc sac (struct nhu dfn_run)
%   R = dfn_perm_loss(par, y0, chg, opt)
% par, y0: bo tham so va trang thai dau. Neu par.aging.on = false (vd. trang thai tu src/nmpc),
%   bo tham so co lao hoa duoc tao lai tu par.opt (+ aging = true, cung luoi) va y0 duoc mo rong
%   voi trang thai lao hoa BOL (dfn_aging_extend). Neu da co lao hoa, y0 dung nguyen (co the la
%   trang thai da gia).
% opt.Cdis   C-rate xa ve (mac dinh 0.5, GD-32)       opt.Tamb  [K] (mac dinh: Tamb cua buoc sac cuoi)
% opt.discharge (true): xa ve Q dau (Qstop) hoac toi par.Vmin
%
% R (mAh, Li quy doi F/3.6): .sei, .seicr (SEI tren vet nut), .dead (lithium chet),
%   .lam (Li trong vat lieu hoat tinh mat do LAM, ca hai cuc), .perm = sei + seicr + dead + lam
%   (mat vinh vien); .plated_left (lithium ma thuan nghich con lai sau xa, chi thong ke);
%   .chg (cung cac truong, chi tinh den het pha sac); .t_chg, .t_dis [s]; .reason;
%   .Li_cons_rel (sai lech bao toan Li tong tuong doi); .y_end, .par.
% Nhanh: chi xuat diem cuoi moi buoc (khong luu duong cong).
if nargin < 4, opt = struct(); end
if ~(isfield(par, 'aging') && par.aging.on)
    o2 = par.opt; o2.aging = true;
    para = dfn_params(o2);
    para = dfn_set_area(para, par.A);
    y0 = dfn_aging_extend(par, y0, para);
    par = para;
end
if ~isfield(opt, 'Cdis') || isempty(opt.Cdis), opt.Cdis = 0.5; end
if ~isfield(opt, 'discharge') || isempty(opt.discharge), opt.discharge = true; end
if ~isfield(opt, 'Tamb') || isempty(opt.Tamb), opt.Tamb = chg(end).Tamb; end
for k = 1:numel(chg)
    if ~isfield(chg(k), 'tout') || isempty(chg(k).tout), chg(k).tout = chg(k).tmax; end
end
L0 = dfn_li_inventory(par, y0);
o1 = dfn_run(par, y0, chg);
y1 = o1.y_end; L1 = dfn_li_inventory(par, y1);
R.reason = o1.reason; R.t_chg = o1.t(end);
R.chg = parts(L1, L0);
y2 = y1; R.t_dis = 0;
if opt.discharge
    st = struct('mode', 'I', 'value', opt.Cdis*par.Qnom, 'tmax', 10*3600, 'Tamb', opt.Tamb, ...
        'stop', struct('Qstop', y0(par.ix.Q), 'Vmin', par.Vmin), 'tout', 10*3600);
    o2 = dfn_run(par, y1, st);
    y2 = o2.y_end; R.reason = [R.reason, o2.reason]; R.t_dis = o2.t(end);
end
L2 = dfn_li_inventory(par, y2);
P = parts(L2, L0);
fn = fieldnames(P);
for i = 1:numel(fn), R.(fn{i}) = P.(fn{i}); end
R.Li_cons_rel = (L2.total - L0.total)/L0.total;
R.y_end = y2; R.par = par;
end

function P = parts(L, L0)
k = 96485.33212/3.6;      % mol -> mAh
P.sei   = k*(L.sei - L0.sei);
P.seicr = k*(L.seicr - L0.seicr);
P.dead  = k*(L.dead - L0.dead);
P.lam   = k*((L.lam_n + L.lam_p) - (L0.lam_n + L0.lam_p));
P.perm  = P.sei + P.seicr + P.dead + P.lam;
P.plated_left = k*(L.plated - L0.plated);
end
