function [pp, info] = ekf_plant_par(par, scen)
%EKF_PLANT_PAR  Tham so cua pin "that" (DFN day du) cho phep thu EKF (GD-72).
%   scen = 'nominal'      : giong het mo hinh cua EKF (chi sai SOC ban dau)
%   scen = 'mismatch'     : lech tham so + pin da lao hoa (GD-72, GIA DINH):
%       D_s cuc am x 0.8 (qua R_cor, bang Kirchhoff tinh lai), j0_ref cuc am
%       va cuc duong x 0.8, h x 0.8, do day SEI L_SEI x 1.5 (=> R_film x 1.5),
%       lithium mat 2 % dung luong SOC (Q_LLI = 0.02 Csoc, dat o trang thai dau)
%   scen = 'mismatch_Rc'  : nhu 'mismatch' + dien tro tiep xuc R_contact x 1.2
% info.lli [Ah], info.rf (R_film that / R_film,BOL), info.desc
pp = par; info.lli = 0; info.rf = 1;
switch scen
    case 'nominal'
        info.desc = 'khong lech tham so';
    case {'mismatch', 'mismatch_Rc'}
        pp.neg.Ds.Rcor = 0.8*par.neg.Ds.Rcor;
        pp.neg = dfn_Ktable(pp.neg);                     % bang Kirchhoff cua D_s (GD-15) tinh lai
        pp.neg.j0_ref = 0.8*par.neg.j0_ref;
        pp.pos.j0_ref = 0.8*par.pos.j0_ref;
        pp.th.h = 0.8*par.th.h;
        pp.th.hA_V = pp.th.h*pp.th.Acool/pp.th.Vcell;    % nhu dfn_params.m
        pp.sei.L0 = 1.5*par.sei.L0;                      % dfn_aging_state: R_film = rho_SEI L0
        info.rf = 1.5;
        info.lli = 0.02*par.neg.Qcap*(par.neg.x100 - par.neg.x0);
        info.desc = 'D_s,n x0.8; j0 (am, duong) x0.8; h x0.8; L_SEI x1.5; LLI 2 %';
        if strcmp(scen, 'mismatch_Rc')
            pp.Rcontact = 1.2*par.Rcontact;
            info.desc = [info.desc '; R_contact x1.2'];
        end
    otherwise
        error('ekf_plant_par: kich ban %s', scen);
end
% kiem tra: R_film cua DFN pin that dung nhu khai bao
ag = dfn_aging_state(pp, []);
rf_chk = ag.Rfilm_n(1)/(par.sei.rho*par.sei.L0);
if abs(rf_chk - info.rf) > 1e-12
    error('ekf_plant_par: dfn_aging_state khong doc par.sei.L0 nhu gia thiet (rf = %.4f)', rf_chk);
end
end
