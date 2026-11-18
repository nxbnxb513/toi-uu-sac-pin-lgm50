function [y, info] = ag_jump(par, ya, yb, J)
%AG_JUMP  Mot buoc nhay chu ky (phuong phap so, GD-58): ngoai suy J chu ky tu hai chu ky lien
% tiep a, b (trang thai cuoi chu ky, cung pha). Ban 18/11/2026 (thay ngoai suy moi trang thai):
%
%  1. CHI ngoai suy tuyen tinh cac trang thai CHAM (bien lao hoa tich luy):
%       L_inner, L_outer, L_inner,cr, L_outer,cr, c_dl, l_cr, eps_s,n, eps_s,p, so sach
%       nSEI, nSEIcr, nLAM_n, nLAM_p, Qthr:      y = y_b + J (y_b - y_a)
%  2. Lithium trong hat: moi dien cuc dich DEU (cung mot hang so cho moi vo hat, moi nut x)
%       sao cho tong Li trong hat cua dien cuc = n_b + J (n_b - n_a); x_av dich cung luong
%       (bat bien x_av = sum(theta Vsh)/sum(Vsh) giu chinh xac). Hinh dang profile ban kinh
%       va phan bo theo x giu nhu chu ky b.
%  3. Trang thai NHANH giu nguyen gia tri cuoi chu ky b: profile trong hat (ngoai phan dich
%       deu), c_e, T, Q, c_Li (ma thuan nghich), cac bien dai so.
%  4. Bao toan Li tong chinh xac: phan chenh (do giu c_e, c_Li; tich eps_s.x_av) dich deu vao
%       hat cuc am; info.err = |phan chenh|/tong (ghi lai).
% Ly do (chan doan run 44123422399): ngoai suy MOI trang thai khuech dai cac mode tat dan
% nhanh (profile ban kinh, c_Li, phan bo theo x) theo he so |r (r + J (r - 1))| moi lan
% nhay (r = he so tat dan moi chu ky) -> sau 4-8 lan nhay theta < 0 hoac > 1, c_Li < 0,
% ode15s/khoi tao nhat quan that bai. Cac mode tat dan khong duoc ngoai suy thi khong khuech dai.
%
% info.ok = false neu trang thai sau nhay vuot mien vat ly (theta ngoai (0,1), eps <= 0,
% do day <= 0, c_dl < 0, eps_e <= 0) - nguoi goi giam J.
ix = par.ix; G = ix.ag; g = par.grid; A = par.A;
y = yb;
slow = [G.Lin; G.Lout; G.Lcin; G.Lcout; G.cdl; G.lcr; G.epsn; G.epsp; G.nSEI; G.nSEIcr; G.nLAMn; G.nLAMp; G.Qthr];
if isfield(G, 'epsSi'), slow = [slow; G.epsSi]; end    % tang 2 (gia dinh): eps_Si cung la trang thai cham
y(slow) = yb(slow) + J*(yb(slow) - ya(slow));
L1 = dfn_li_inventory(par, yb);
La = dfn_li_inventory(par, ya);
% Li trong hat moi dien cuc [mol]
tn = L1.part_n + J*(L1.part_n - La.part_n);
tp = L1.part_p + J*(L1.part_p - La.part_p);
y = shift(y, 'n', tn);
y = shift(y, 'p', tp);
% bao toan Li tong (doan mo phong khong co can kho) -> phan chenh vao hat cuc am
L2 = dfn_li_inventory(par, y);
tgt = L1.total;
y = shift(y, 'n', L2.part_n + (tgt - L2.total));
L3 = dfn_li_inventory(par, y);
info.err = abs(tgt - L2.total)/tgt;          % phan chenh da bu (tuong doi)
info.cons = abs(L3.total - tgt)/tgt;         % sau khi bu (~ 1e-15)
if info.err > 1e-3
    fn = {'part_n', 'part_p', 'elyte', 'sei', 'seicr', 'plated', 'dead', 'lam_n', 'lam_p', 'total'};
    fprintf('ag_jump: J = %d, phan bu Li lon (%.3g). Thanh phan [mol] a / b / sau nhay:\n', J, info.err);
    for k = 1:numel(fn)
        fprintf('   %-7s %.6e  %.6e  %.6e\n', fn{k}, La.(fn{k}), L1.(fn{k}), L2.(fn{k}));
    end
end
% kiem tra mien vat ly
thn = y(ix.thn); thp = y(ix.thp);
ag = dfn_aging_state(par, y);
info.ok = all(thn > 1e-6 & thn < 1 - 1e-6) && all(thp > 1e-6 & thp < 1 - 1e-6) ...
    && all(y(G.epsn) > 0) && all(y(G.epsp) > 0) && all(ag.eps > 0) ...
    && (~isfield(G, 'epsSi') || (all(y(G.epsSi) > 0) && all(y(G.epsSi) < y(G.epsn)))) ...
    && all(y([G.Lin; G.Lout; G.Lcin; G.Lcout]) > 0) && all(y(G.cdl) >= 0) && all(y(G.lcr) > 0);

    function yy = shift(yy, el, target)
        % dich deu theta cua dien cuc el sao cho Li trong hat = target [mol]
        if el == 'n'
            e = yy(G.epsn); dx = g.dxn; cm = par.neg.cmax; it = ix.thn; ia = G.xavn; Nr = g.Nrn; Nx = g.Nn; Vs = g.Vshn;
        else
            e = yy(G.epsp); dx = g.dxp; cm = par.pos.cmax; it = ix.thp; ia = G.xavp; Nr = g.Nrp; Nx = g.Np; Vs = g.Vshp;
        end
        xm = (Vs.'*reshape(yy(it), Nr, Nx)).'/sum(Vs);     % nhu dfn_li_inventory
        cur = A*sum(e.*xm)*cm*dx;
        d = (target - cur)/(A*sum(e)*cm*dx);
        yy(it) = yy(it) + d;
        yy(ia) = yy(ia) + d;
    end
end
