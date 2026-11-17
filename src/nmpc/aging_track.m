function [trk, ser] = aging_track(cmd, par, ap, trk, tt, Y, a)
%AGING_TRACK  Bo dem lao hoa TAM THOI hau kiem tren quy dao DFN.
%   trk = aging_track('init', par)
%   [trk, ser] = aging_track('run', par, ap, trk, tt, Y, a)
% Tai moi nut x cuc am cua DFN: toc do SEI va dong ma lithium tinh bang
% aging_rates.m (CUNG cong thuc voi ROM/NMPC) tu phi_s - phi_e, j_tot, c_e, T
% cua DFN. Phan ung phu KHONG hoi tiep vao DFN (lao hoa chua cai vao DFN, buoc C).
%   SEI: tich phan hinh thang.
%   Lithium ma thuan nghich c_Li va lithium chet c_dl (dac_ta_lao_hoa.md muc 4):
%     dc_Li/dt = A - B c_Li,  A = -a_n j_pl(c_Li = 0)/F,  B = a_n (j_pl(1) - j_pl(0))/F + gamma0
%     dc_dl/dt = gamma0 c_Li
%   giai dung (nghiem mu) tren moi khoang luoi voi A, B trung binh hai dau khoang.
% Don vi tich luy: mAh (1 mAh = 3.6 C).
g = par.grid;
switch cmd
    case 'init'
        trk.cLi = zeros(g.Nn, 1); trk.cdl = zeros(g.Nn, 1);
        trk.nsei = 0; trk.npl = 0; trk.ndl = 0; trk.nlam = 0;   % nlam: chi khac 0 khi DFN co lao hoa
        return
    case 'run'
    otherwise
        error('aging_track: lenh khong hop le');
end
ix = par.ix;
nt = numel(tt);
Vn = par.A*g.dxn;                         % m3 moi o DFN cuc am
ser.nsei = zeros(nt, 1); ser.npl = zeros(nt, 1); ser.ndl = zeros(nt, 1);
ser.eta_sep = zeros(nt, 1); ser.eta_min = zeros(nt, 1);
[r0, A0, B0, eta0] = rates(1);
ser.eta_sep(1) = eta0(end); ser.eta_min(1) = min(eta0);
ser.nsei(1) = trk.nsei; ser.npl(1) = trk.npl; ser.ndl(1) = trk.ndl;
for i = 2:nt
    [r1, A1, B1, eta1] = rates(i);
    dt = tt(i) - tt(i-1);
    trk.nsei = trk.nsei + Vn*sum(0.5*(r0 + r1))*dt*par.F/3.6;
    Ab = 0.5*(A0 + A1); Bb = 0.5*(B0 + B1);
    css = Ab./Bb;
    e = exp(-Bb*dt);
    c1 = css + (trk.cLi - css).*e;
    intc = css*dt + (trk.cLi - css).*(1 - e)./Bb;          % tich phan c_Li tren khoang
    trk.cdl = trk.cdl + ap.gamma0*intc;
    trk.cLi = c1;
    trk.npl = Vn*sum(trk.cLi + trk.cdl)*par.F/3.6;
    trk.ndl = Vn*sum(trk.cdl)*par.F/3.6;
    ser.nsei(i) = trk.nsei; ser.npl(i) = trk.npl; ser.ndl(i) = trk.ndl;
    ser.eta_sep(i) = eta1(end); ser.eta_min(i) = min(eta1);
    r0 = r1; A0 = A1; B0 = B1;
end

    function [r, A, B, eta] = rates(i)
        q = a{i};
        ce_n = max(Y(ix.ce(g.in), i)*par.ce_ref, 1e-2);   % nhu chan c_e trong dfn_rhs.m
        z0 = zeros(g.Nn, 1);
        [r, jp0, eta] = aging_rates(ap, par, q.dphi_n, q.jn, ce_n, q.T, z0);
        [~, jp1]      = aging_rates(ap, par, q.dphi_n, q.jn, ce_n, q.T, z0 + 1);
        A = -ap.as_n*jp0/par.F;
        B = ap.as_n*(jp1 - jp0)/par.F + ap.gamma0;
    end
end
