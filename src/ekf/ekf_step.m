function [xa, P, info] = ekf_step(E, xa, P, u, y, c)
%EKF_STEP  Mot buoc EKF (du doan + cap nhat) - giao dien cho vong kin NMPC.
%   [xa, P, info] = ekf_step(E, xa, P, u, y, c)
%   E   : ekf_build(par)            c : ekf_config(...) (so dieu chinh Q, R)
%   xa  : [x (rom.nx, trang thai ROM day du nhu NMPC dung); rf]
%         rf = R_film / R_film,BOL (tham so troi cham)
%   P   : hiep phuong sai (E.na x E.na) theo thu tu [x(E.fi); rf]
%   u   : .I0, .I1 dong DO DUOC [A] o dau va cuoi khoang (DFN: > 0 la XA,
%         sac la am), .dt [s] do dai khoang, .Tamb [K]
%   y   : [V; T] do duoc o cuoi khoang [V; K]; y = [] => chi du doan
% Dong trong khoang: noi suy tuyen tinh giua I0 va I1 (gia tri giua moi khoang con).
% Khoang dai hon E.dtmax duoc chia thanh nhieu khoang con, Jacobian nhan chuoi.
% info: .z (bien dai so o cuoi), .nis (do lech chuan hoa cua innovation),
%       .innov, .S, .ok, .proj (so lan phai chieu trang thai ve mien vat ly)
nx = E.nx; fi = E.fi; nf = E.nf; ix = E.ix;
x = xa(1:nx); rf = xa(nx+1); Ta = u.Tamb;
info.ok = true; info.proj = 0;
% ---- du doan ------------------------------------------------------------
nsub = max(1, ceil(u.dt/E.dtmax - 1e-9)); h = u.dt/nsub;
qc = qrates(E, c);
sI2 = c.sI_sens^2/2 + c.bI_filter^2;     % trung binh hai mau doc lap + lech khong co the co
for k = 1:nsub
    Ik = u.I0 + (u.I1 - u.I0)*(k - 0.5)/nsub;
    z0 = ekf_solve_z(E, x, Ik, Ta, rf);
    [xf, ~, Jx, Jp] = E.FJ(x, z0, [Ik; Ta; rf; h]);
    xf = full(xf); Jx = full(Jx); Jp = full(Jp);
    if ~all(isfinite(xf)) || ~all(isfinite(Jx(:)))
        info.ok = false;
        error('ekf_step: tich phan that bai (t buoc %.3g s)', h);
    end
    A = [Jx(fi, fi), Jp(fi, 3); zeros(1, nf), 1];
    B = [Jp(fi, 1); 0];
    P = A*P*A.' + diag(qc)*h + (B*B.')*sI2;
    x = xf;
end
x = project(E, x);
% ---- cap nhat -------------------------------------------------------------
info.innov = []; info.nis = NaN; info.S = [];
if ~isempty(y)
    z = ekf_solve_z(E, x, u.I1, Ta, rf);
    [hv, hx, hz, hrf, hI, ~, gx, gz, grf, gI] = E.Hf(x, z, u.I1, Ta, rf);
    hv = full(hv); hx = full(hx); hz = full(hz); hrf = full(hrf); hI = full(hI);
    gx = full(gx); gz = full(gz); grf = full(grf); gI = full(gI);
    dz = -gz\[gx(:, fi), grf];
    H = [hx(:, fi), hrf] + hz*dz;
    dhdI = hI - hz*(gz\gI);                          % nhieu dong vao phuong trinh do
    R = diag([c.sV_sens^2 + c.sV_model^2, c.sT_sens^2 + c.sT_model^2]) + (dhdI*dhdI.')*(c.sI_sens^2 + c.bI_filter^2);
    S = H*P*H.' + R; S = (S + S.')/2;
    K = (P*H.')/S;
    nu = y(:) - hv;
    d = K*nu;
    x(fi) = x(fi) + d(1:nf); rf = rf + d(end);
    IKH = eye(E.na) - K*H;
    P = IKH*P*IKH.' + K*R*K.';
    info.innov = nu; info.S = S; info.nis = nu.'*(S\nu);
    [x, np] = project(E, x); info.proj = np;
    if rf < 0.05, rf = 0.05; info.proj = info.proj + 1; end
end
P = (P + P.')/2;
x(ix.soc) = (E.wn.'*x(ix.thn) - E.x0n)/(E.x100n - E.x0n);   % SOC theo dinh nghia GD-24
xa = [x; rf];
info.z = ekf_solve_z(E, x, u.I1, Ta, rf);
end

function qc = qrates(E, c)
% toc do nhieu qua trinh lien tuc (phuong sai / s), thu tu [x(fi); rf]
ix = E.ix; fi = E.fi;
q = zeros(E.nx, 1);
q(ix.thn) = c.q1h.th^2/3600; q(ix.thp) = c.q1h.th^2/3600;
q(ix.ce) = c.q1h.ce^2/3600; q(ix.T) = c.q1h.T^2/3600;
qc = [q(fi); c.q1h.rf^2/3600];
end

function [x, n] = project(E, x)
% giu stoich trong (0, 1) va c_e > 0 (chi khi cap nhat day ra ngoai mien vat ly)
ix = E.ix; n = 0;
th = [ix.thn; ix.thp];
lo = x(th) < 1e-6; hi = x(th) > 1 - 1e-6;
n = n + nnz(lo) + nnz(hi);
x(th(lo)) = 1e-6; x(th(hi)) = 1 - 1e-6;
lc = x(ix.ce) < 1e-3; n = n + nnz(lc); x(ix.ce(lc)) = 1e-3;
end
