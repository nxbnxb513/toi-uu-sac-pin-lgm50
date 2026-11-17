function par = dfn_mesh(par)
%DFN_MESH  Luoi the tich huu han, chi so bien, ma tran khoi luong, JPattern.
%
% Vector trang thai y (cot):
%   --- vi phan ---
%   thn  (Nrn x Nn)  stoichiometry trong hat cuc am, cot k = nut x thu k
%   thp  (Nrp x Np)  stoichiometry trong hat cuc duong
%   ce   (N)         nong do dien giai / ce_ref
%   T    (1)         nhiet do cell [K]
%   Q    (1)         dien luong da xa [Ah] (tich phan cua I)
%   --- dai so ---
%   phisn (Nn), phisp (Np)  the pha ran [V] (moc: phi_s = 0 tai x = 0)
%   phie  (N)               the dien giai [V]
%   jn (Nn), jp (Np)        mat do dong be mat TONG j_tot [A/m^2]
%   H  (N)                  nhiet tich luy theo x [W/m^2] (de Jacobian thua)
%   I  (1)                  dong cell [A], > 0 la xa
% Buoc sau (lao hoa) them trang thai vi phan moi vao sau Q; xem dfn_aging_state.m.

c = par.cfg;
Nn = c.Nn; Ns = c.Ns; Np = c.Np; N = Nn + Ns + Np;
if Nn < 2 || Np < 2 || Ns < 1 || c.Nrn < 3 || c.Nrp < 3
    error('dfn_mesh: luoi qua tho');
end
g.Nn = Nn; g.Ns = Ns; g.Np = Np; g.N = N; g.Nrn = c.Nrn; g.Nrp = c.Nrp;
g.dxn = par.neg.L/Nn; g.dxs = par.sep.L/Ns; g.dxp = par.pos.L/Np;
g.dx  = [g.dxn*ones(Nn,1); g.dxs*ones(Ns,1); g.dxp*ones(Np,1)];
g.in  = (1:Nn).'; g.is = (Nn+1:Nn+Ns).'; g.ip = (Nn+Ns+1:N).';
g.xc  = cumsum(g.dx) - g.dx/2;
% hat: vo cau deu theo r
g.drn  = par.neg.Rp/c.Nrn;  rf = (0:c.Nrn).'*g.drn;
g.r2fn = rf.^2;  g.Vshn = (rf(2:end).^3 - rf(1:end-1).^3)/3;
g.drp  = par.pos.Rp/c.Nrp;  rf = (0:c.Nrp).'*g.drp;
g.r2fp = rf.^2;  g.Vshp = (rf(2:end).^3 - rf(1:end-1).^3)/3;
par.grid = g;

% ---- chi so -------------------------------------------------------------
n = 0;
ix.thn = (n+1 : n+c.Nrn*Nn).'; n = n + c.Nrn*Nn;
ix.thp = (n+1 : n+c.Nrp*Np).'; n = n + c.Nrp*Np;
ix.ce  = (n+1 : n+N).';        n = n + N;
ix.T   = n+1;                  n = n + 1;
ix.Q   = n+1;                  n = n + 1;
ix.nd  = n;                    % so trang thai vi phan
ix.phisn = (n+1 : n+Nn).';     n = n + Nn;
ix.phisp = (n+1 : n+Np).';     n = n + Np;
ix.phie  = (n+1 : n+N).';      n = n + N;
ix.jn    = (n+1 : n+Nn).';     n = n + Nn;
ix.jp    = (n+1 : n+Np).';     n = n + Np;
ix.H     = (n+1 : n+N).';      n = n + N;
ix.I     = n+1;                n = n + 1;
ix.ny    = n;
par.ix = ix;
par.id = (1:ix.nd).';          % hang vi phan
par.ia = (ix.nd+1:ix.ny).';    % hang dai so
par.M  = spdiags([ones(ix.nd,1); zeros(ix.ny-ix.nd,1)], 0, ix.ny, ix.ny);

% ---- sai so tuyet doi cho ode15s ---------------------------------------
at = zeros(ix.ny,1);
at(ix.thn) = 1e-7; at(ix.thp) = 1e-7; at(ix.ce) = 1e-6; at(ix.T) = 1e-4;
at(ix.Q) = 1e-6; at(ix.phisn) = 1e-6; at(ix.phisp) = 1e-6; at(ix.phie) = 1e-6;
at(ix.jn) = 1e-6; at(ix.jp) = 1e-6; at(ix.H) = 1e-5; at(ix.I) = 1e-6;
par.atol = at;

% ---- JPattern (cau truc Jacobian df/dy) --------------------------------
R = {}; C = {};
Mn = reshape(ix.thn, c.Nrn, Nn); Mp = reshape(ix.thp, c.Nrp, Np);
cen = ix.ce(g.in); cep = ix.ce(g.ip); phn = ix.phie(g.in); php = ix.phie(g.ip);
% hat
add(Mn, Mn); add(Mn(2:end,:), Mn(1:end-1,:)); add(Mn(1:end-1,:), Mn(2:end,:)); add(Mn, ix.T);
add(Mp, Mp); add(Mp(2:end,:), Mp(1:end-1,:)); add(Mp(1:end-1,:), Mp(2:end,:)); add(Mp, ix.T);
% vo ngoai cung: thong luong be mat (j_int = j_tot - j_side(phi_s, phi_e, c_e, ...))
add(Mn(end,:), ix.jn); add(Mn(end,:), ix.phisn); add(Mn(end,:), phn); add(Mn(end,:), cen);
add(Mp(end,:), ix.jp); add(Mp(end,:), ix.phisp); add(Mp(end,:), php); add(Mp(end,:), cep);
% dien giai: bao toan khoi luong
tri(ix.ce, ix.ce); tri(ix.ce, ix.phie); add(ix.ce, ix.T); add(cen, ix.jn); add(cep, ix.jp);
% nhiet, dien luong
add(ix.T, ix.T); add(ix.T, ix.H(end));
add(ix.Q, ix.Q); add(ix.Q, ix.I);
% the pha ran
tri(ix.phisn, ix.phisn); add(ix.phisn, ix.jn); add(ix.phisn, ix.T);
tri(ix.phisp, ix.phisp); add(ix.phisp, ix.jp); add(ix.phisp, ix.T); add(ix.phisp, ix.I);
% the dien giai
tri(ix.phie, ix.phie); tri(ix.phie, ix.ce); add(ix.phie, ix.T);
add(phn, ix.jn); add(php, ix.jp);
% dong hoc
add(ix.jn, ix.jn); add(ix.jn, ix.phisn); add(ix.jn, phn); add(ix.jn, cen);
add(ix.jn, Mn(end,:)); add(ix.jn, Mn(end-1,:)); add(ix.jn, ix.T); add(ix.jn, ix.I);
add(ix.jp, ix.jp); add(ix.jp, ix.phisp); add(ix.jp, php); add(ix.jp, cep);
add(ix.jp, Mp(end,:)); add(ix.jp, Mp(end-1,:)); add(ix.jp, ix.T); add(ix.jp, ix.I);
% nhiet tich luy H(k) = H(k-1) + q(k)
add(ix.H, ix.H); add(ix.H(2:end), ix.H(1:end-1));
add(ix.H, ix.phie); add(ix.H(1:end-1), ix.phie(2:end));
add(ix.H, ix.ce);   add(ix.H(1:end-1), ix.ce(2:end));
add(ix.H, ix.T);    add(ix.H, ix.I);
Hn = ix.H(g.in); Hp = ix.H(g.ip);
add(Hn, ix.phisn); add(Hn(1:end-1), ix.phisn(2:end)); add(Hn, ix.jn);
add(Hn, Mn(end,:)); add(Hn, Mn(end-1,:));
add(Hp, ix.phisp); add(Hp(1:end-1), ix.phisp(2:end)); add(Hp, ix.jp);
add(Hp, Mp(end,:)); add(Hp, Mp(end-1,:));
% phuong trinh dieu khien dong / ap
add(ix.I, ix.I); add(ix.I, ix.phisp(end)); add(ix.I, ix.T);

S = sparse(vertcat(R{:}), vertcat(C{:}), 1, ix.ny, ix.ny);
par.S = spones(S);
% khoi dai so va to mau cot cho Jacobian sai phan (khoi tao nhat quan)
par.Saa    = par.S(par.ia, par.ia);
par.grp_aa = dfn_color(par.Saa);

    function add(r, cc)
        r = r(:); cc = cc(:);
        if numel(cc) == 1, cc = repmat(cc, numel(r), 1); end
        if numel(r) == 1, r = repmat(r, numel(cc), 1); end
        R{end+1} = r; C{end+1} = cc; %#ok<AGROW>
    end
    function tri(rows, cols)
        add(rows, cols);
        add(rows(2:end), cols(1:end-1));
        add(rows(1:end-1), cols(2:end));
    end
end
