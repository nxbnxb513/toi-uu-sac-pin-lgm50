function L = dfn_li_inventory(par, y)
%DFN_LI_INVENTORY  So sach lithium cua mot trang thai [mol] (dien tich dien cuc hien thoi par.A).
%   L.part_n, L.part_p  lithium trong hat con hoat dong: A sum_x eps_s(x) c_avg(x) dx
%   L.elyte             lithium trong dien giai jelly roll: A sum_x eps_e(x) c_e(x) dx
%   L.sei, L.seicr      lithium trong SEI be mat / tren vet nut (tich phan dong, khong dung a_typ)
%   L.plated, L.dead    lithium ma thuan nghich / lithium chet
%   L.lam_n, L.lam_p    lithium nam trong vat lieu hoat tinh da mat (LAM do ung suat)
%   L.total             tong cac muc tren (bao toan trong mot doan mo phong; can kho: dfn_dryout_update)
%   L.Cn, L.Cp [Ah]     dung luong dien cuc: A sum_x eps_s dx c_max F/3600
%   L.xav_err           max |x_av - sum(theta Vsh)/sum(Vsh)| (kiem tra bat bien)
%   L.CSi [Ah]          (chi tang 2) dung luong silicon A sum_x eps_Si dx c_max F/3600
g = par.grid; ix = par.ix; A = par.A;
thn = reshape(y(ix.thn), g.Nrn, g.Nn); thp = reshape(y(ix.thp), g.Nrp, g.Np);
xn = (g.Vshn.'*thn).'/sum(g.Vshn); xp = (g.Vshp.'*thp).'/sum(g.Vshp);
ag = dfn_aging_state(par, y);
if isfield(par, 'aging') && par.aging.on
    en = y(ix.ag.epsn); ep = y(ix.ag.epsp);
    L.sei    = A*sum(y(ix.ag.nSEI))*g.dxn;
    L.seicr  = A*sum(y(ix.ag.nSEIcr))*g.dxn;
    L.plated = A*sum(y(ix.ag.cLi))*g.dxn;
    L.dead   = A*sum(y(ix.ag.cdl))*g.dxn;
    L.lam_n  = A*y(ix.ag.nLAMn);
    L.lam_p  = A*y(ix.ag.nLAMp);
    L.xav_err = max([abs(y(ix.ag.xavn) - xn); abs(y(ix.ag.xavp) - xp)]);
    L.Qthr = y(ix.ag.Qthr);
else
    en = par.neg.eps_s*ones(g.Nn,1); ep = par.pos.eps_s*ones(g.Np,1);
    L.sei = 0; L.seicr = 0; L.plated = 0; L.dead = 0; L.lam_n = 0; L.lam_p = 0; L.xav_err = 0; L.Qthr = 0;
end
L.part_n = A*sum(en.*xn)*par.neg.cmax*g.dxn;
L.part_p = A*sum(ep.*xp)*par.pos.cmax*g.dxp;
ce = y(ix.ce)*par.ce_ref;
L.elyte  = A*sum(ag.eps.*ce.*g.dx);
L.total  = L.part_n + L.part_p + L.elyte + L.sei + L.seicr + L.plated + L.dead + L.lam_n + L.lam_p;
L.Cn = A*sum(en)*g.dxn*par.neg.cmax*par.F/3600;
L.Cp = A*sum(ep)*g.dxp*par.pos.cmax*par.F/3600;
L.Vpore = A*sum(ag.eps.*g.dx);
% tang 2 (gia dinh): dung luong silicon [Ah] (phan cua L.Cn)
if isfield(ix, 'ag') && isfield(ix.ag, 'epsSi')
    L.CSi = A*sum(y(ix.ag.epsSi))*g.dxn*par.neg.cmax*par.F/3600;
end
end
