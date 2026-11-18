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
info.ok = true; info.proj = 0; info.iter = 0;
% ---- du doan ------------------------------------------------------------
nsub = max(1, ceil(u.dt/E.dtmax - 1e-9)); h = u.dt/nsub;
qc = qrates(E, c);
sI2 = c.sI_sens^2/2 + c.bI_filter^2;     % trung binh hai mau doc lap + lech khong co the co
tk = 0;
while tk < u.dt - 1e-9
    hk = min(h, u.dt - tk);
    [xf, A, B, hk] = substep(E, x, rf, u, tk, hk, Ta);
    P = A*P*A.' + diag(qc)*hk + (B*B.')*sI2;
    x = xf; tk = tk + hk;
end
x = project(E, x);
% ---- cap nhat -------------------------------------------------------------
info.innov = []; info.nis = NaN; info.S = [];
if ~isempty(y)
    % EKF lap (Gauss-Newton, Bell & Cathey 1993) voi c.n_iter lan; n_iter = 1 la EKF thuong.
    % Moi lan lap: tuyen tinh hoa lai h tai diem lap, chieu ve mien vat ly.
    xp = [x(fi); rf]; xi = xp; xfull = x; np = 0; info.lam = 1; info.alpha = 1;
    ls = isfield(c, 'ls') && c.ls; fade = 0; if isfield(c, 'fade'), fade = c.fade; end
    Rm = @(dhdI) diag([c.sV_sens^2 + c.sV_model^2, c.sT_sens^2 + c.sT_model^2]) + (dhdI*dhdI.')*(c.sI_sens^2 + c.bI_filter^2);
    if fade > 1
        % GD-78 (b): nhan P du doan voi lam khi innovation qua lon so voi S (NIS vuot nguong chi2 2 bac
        % tu do 99.9 % = 13.8): lam = min(fade, NIS/2). Bo loc "fading memory" (Sorenson & Sacks 1971).
        [hv, H, dhdI] = meas(E, xfull, rf, u.I1, Ta);
        S0 = H*P*H.' + Rm(dhdI); nu0 = y(:) - hv; nis0 = nu0.'*(S0\nu0);
        if nis0 > 13.8, info.lam = min(fade, nis0/2); P = info.lam*P; end
    end
    if ls
        [Lc, flag] = chol((P + P.')/2, 'lower');
        if flag, Lc = chol((P + P.')/2 + 1e-14*eye(E.na), 'lower'); end
    end
    for it = 1:max(1, c.n_iter)
        xfull(fi) = xi(1:nf);
        [hv, H, dhdI] = meas(E, xfull, xi(end), u.I1, Ta);
        R = Rm(dhdI);
        S = H*P*H.' + R; S = (S + S.')/2;
        K = (P*H.')/S;
        if isfield(u, 'hold') && u.hold, K = hold_gain(E, K); end
        if it == 1, nu = y(:) - hv; info.innov = nu; info.S = S; info.nis = nu.'*(S\nu); end
        xn = xp + K*(y(:) - hv - H*(xp - xi));
        if ls
            % GD-78 (a): tim theo duong (Gauss-Newton co tat dan): chia doi buoc toi khi trang thai
            % nam trong mien vat ly (khong phai chieu) va ham muc tieu MAP giam.
            [xn, xfull, np, alpha, ok] = line_search(E, xi, xn, xp, Lc, R, y(:), hv, xfull, u.I1, Ta);
            if it == 1, info.alpha = alpha; end
            stepn = max(abs(xn - xi)); xi = xn;
            if ~ok || stepn < 1e-7, break; end
        else
            xfull(fi) = xn(1:nf);
            [xfull, np] = project(E, xfull); xn(1:nf) = xfull(fi);
            if xn(end) < 0.05, xn(end) = 0.05; np = np + 1; end
            stepn = max(abs(xn - xi)); xi = xn;
            if stepn < 1e-7, break; end
        end
    end
    info.iter = it; info.proj = np;
    x = xfull; x(fi) = xi(1:nf); rf = xi(end);
    IKH = eye(E.na) - K*H;
    P = IKH*P*IKH.' + K*R*K.';
end
P = (P + P.')/2;
x(ix.soc) = (E.wn.'*x(ix.thn) - E.x0n)/(E.x100n - E.x0n);   % SOC theo dinh nghia GD-24
xa = [x; rf];
info.z = ekf_solve_z(E, x, u.I1, Ta, rf);
end

function K = hold_gain(E, K)
% "giu" trang thai lao hoa (GD-74, hai thang thoi gian): trong giai doan hoi tu dau,
% phan hieu chinh khong duoc lam doi rf va luong lithium trao doi duoc (LLI):
%   - hang rf cua K = 0;
%   - bo thanh phan lam doi LLI: dx <- dx - w (l.dx)/(l.w), w = huong dich cuc duong
% P cap nhat dang Joseph nen van dung voi K da sua (bo loc Schmidt / "consider").
ix = E.ix; fi = E.fi; nf = E.nf;
K(end, :) = 0;
l = zeros(1, E.na); w = zeros(E.na, 1);
[~, ln] = ismember(ix.thn, fi); [~, lp] = ismember(ix.thp, fi);
l(ln) = -E.Qn*E.wn.'; l(lp) = -E.Qp*E.wp.';
w(lp) = -1/E.Qp;
K = K - w*(l*K)/(l*w);
end

function [hv, H, dhdI] = meas(E, x, rf, I, Ta)
% phuong trinh do h = [V; T] va Jacobian toan phan theo [x(fi); rf] (z = z(x) qua g = 0)
fi = E.fi;
z = ekf_solve_z(E, x, I, Ta, rf);
[hv, hx, hz, hrf, hI, ~, gx, gz, grf, gI] = E.Hf(x, z, I, Ta, rf);
hv = full(hv); hx = full(hx); hz = full(hz); hrf = full(hrf); hI = full(hI);
gx = full(gx); gz = full(gz); grf = full(grf); gI = full(gI);
H = [hx(:, fi), hrf] + hz*(-gz\[gx(:, fi), grf]);
if ~all(isfinite(H(:))) || rcond(gz) < 1e-15
    error('ekf_step: Jacobian do khong hop le (rcond(g_z) = %.2e)', rcond(gz));
end
dhdI = hI - hz*(gz\gI);                          % nhieu dong vao phuong trinh do
end

function [xf, A, B, h] = substep(E, x, rf, u, tk, h, Ta)
% mot khoang con; neu bo giai Newton cua tich phan khong hoi tu (trang thai ra
% ngoai mien vat ly hoac khong giai duoc z) thi chia doi khoang (toi da 6 lan)
fi = E.fi; nf = E.nf;
for tries = 0:6
    Ik = u.I0 + (u.I1 - u.I0)*(tk + h/2)/u.dt;
    z0 = ekf_solve_z(E, x, Ik, Ta, rf);
    [xf, ~, Jx, Jp] = E.FJ(x, z0, [Ik; Ta; rf; h]);
    xf = full(xf); Jx = full(Jx); Jp = full(Jp);
    ok = all(isfinite(xf)) && all(isfinite(Jx(:))) && all(isfinite(Jp(:))) && valid(E, x, xf);
    if ok
        try
            ekf_solve_z(E, xf, Ik, Ta, rf);
        catch
            ok = false;
        end
    end
    if ok, break; end
    fprintf('ekf_step: khoang con %.3g s that bai, chia doi\n', h);
    if tries == 6, error('ekf_step: tich phan that bai ca voi khoang %.3g s', h); end
    h = h/2;
end
A = [Jx(fi, fi), Jp(fi, 3); zeros(1, nf), 1];
B = [Jp(fi, 1); 0];
end

function ok = valid(E, x, xf)
% kiem tra ket qua tich phan co hop ly khong (khong phai nghiem Newton phan ky)
ix = E.ix; th = [ix.thn; ix.thp];
ok = all(xf(th) > -1e-3 & xf(th) < 1 + 1e-3) && all(xf(ix.ce) > 0) && abs(xf(ix.T) - x(ix.T)) < 5 ...
    && max(abs(xf(th) - x(th))) < 0.2;
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

function [xn, xfull, np, alpha, ok] = line_search(E, xi, xc, xp, Lc, R, y, hv, xfull, I, Ta)
% Chia doi buoc d = xc - xi (alpha = 1, 1/2, ..., 1/256). Nhan alpha dau tien ma trang thai
% hop le (stoich trong (0, 1), c_e > 0, rf >= 0.05, giai duoc z) va ham MAP
%   J(x) = |Lc \ (x - xp)|^2 + (y - h(x))' R^-1 (y - h(x))
% giam so voi tai xi. Neu khong co: lay buoc nho nhat hop le (ok = false, dung lap).
fi = E.fi; nf = E.nf;
J = @(x, h) sum((Lc\(x - xp)).^2) + (y - h).'*(R\(y - h));
J0 = J(xi, hv); d = xc - xi; ok = false; np = 0;
xbest = []; 
for alpha = 2.^-(0:8)
    x = xi + alpha*d;
    xf = xfull; xf(fi) = x(1:nf);
    [~, nproj] = project(E, xf);
    if nproj > 0 || x(end) < 0.05, continue; end
    try
        h = meas(E, xf, x(end), I, Ta);
    catch
        continue
    end
    if isempty(xbest), xbest = x; abest = alpha; end
    if J(x, h) < J0, ok = true; xn = x; xfull = xf; return; end
end
if isempty(xbest)
    % khong buoc nao hop le: giu xi (khong hieu chinh o lan lap nay)
    xn = xi; alpha = 0; xfull(fi) = xi(1:nf); np = 1;
else
    xn = xbest; alpha = abest; xfull(fi) = xn(1:nf);
end
end
