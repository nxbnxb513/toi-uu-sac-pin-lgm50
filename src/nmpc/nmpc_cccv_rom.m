function P = nmpc_cccv_rom(M, rom, x0, Ta, soc_t, Icc, lim, vb, dt, tmax)
%NMPC_CCCV_ROM  Sac "CCCV an toan" tren ROM (z da khu, CUNG mo hinh voi acados):
% moi buoc dt [s] ap dong KHONG DOI lon nhat I <= Icc sao cho moi rang buoc cua NMPC
% thoa o dau va cuoi buoc:
%   V + vb <= V_cv,  T <= T_max,  eta_Li,sep >= delta,  x_s,sep <= x_s,max
% (vb: lech dien ap do duoc DFN - ROM, GD-83). Khi chi rang buoc V hoat dong, day
% chinh la CCCV (CC Icc toi V_cv roi giu V_cv); cac rang buoc an toan khac chi lam
% giam dong khi chung hoat dong (GD-82).
%   Dung de: (1) doan dau "tu duong CCCV" cho NMPC (Icc = dong CCCV goc);
%            (2) uoc luong thoi gian sac AN TOAN NHANH NHAT (Icc = I_max) - neu lon
%                hon ngan sach thi bao "khong the sac an toan trong thoi gian nay";
%            (3) doan dau + dong du phong an toan khi bo giai that bai.
% Dung khi SOC >= soc_t (buoc cuoi rut ngan cho dung soc_t), khi dong an toan
% <= lim.Icut (= C/50, nhu dieu kien dung CV cua CCCV, GD-25), hoac t >= tmax.
% Ra: P.t (nt x 1, s), P.X (nx x nt), P.I (nt x 1, dong SAC [A] cua buoc bat dau tai
% P.t; phan tu cuoi lap lai), P.T (thoi gian toi soc_t, Inf neu khong toi), P.reason,
% P.nsim (so lan tich phan), P.wall.
if nargin < 8 || isempty(vb), vb = 0; end
if nargin < 9 || isempty(dt), dt = 30; end
if nargin < 10 || isempty(tmax), tmax = 12*3600; end
E = M.E; ix = rom.ix; io = M.iout;
tw = tic; nsim = 0;
x = x0(:); t = 0;
tt = 0; XX = x; II = [];
Iprev = Icc; reason = 'tmax';
opts = odeset('RelTol', 1e-6, 'AbsTol', rom.atol_x);
while true
    if x(ix.soc) >= soc_t - 1e-6, reason = 'soc'; break; end
    if t >= tmax, reason = 'tmax'; break; end
    % thu dong cua buoc truoc (giai doan CC: Icc), neu khong duoc thi khoanh vung + chia doi
    [ok, xn] = step(min(Icc, Iprev), dt);
    I = min(Icc, Iprev);
    if ~ok
        hi = I; lo = NaN; xlo = [];
        for fr = [0.97 0.9 0.7 0.4 0.15]
            [ok2, x2] = step(fr*hi, dt);
            if ok2, lo = fr*hi; xlo = x2; break; end
            hi = fr*hi;
        end
        if isnan(lo), I = 0; reason = 'Icut'; break; end
        for it = 1:4
            mid = 0.5*(lo + hi);
            [ok2, x2] = step(mid, dt);
            if ok2, lo = mid; xlo = x2; else, hi = mid; end
        end
        I = lo; xn = xlo;
    end
    if I <= lim.Icut, reason = 'Icut'; break; end
    if xn(ix.soc) > soc_t
        % buoc cuoi: rut ngan de dung soc_t
        h = dt*(soc_t - x(ix.soc))/(xn(ix.soc) - x(ix.soc));
        [~, xn] = step(I, max(h, 1e-3));
        tt(end+1, 1) = t + h; XX(:, end+1) = xn; II(end+1, 1) = I; %#ok<AGROW>
        t = t + h; x = xn; reason = 'soc'; break;
    end
    t = t + dt; x = xn;
    tt(end+1, 1) = t; XX(:, end+1) = x; II(end+1, 1) = I; %#ok<AGROW>
    Iprev = I;
end
if isempty(II), II = 0; end
P.t = tt; P.X = XX; P.I = [II; II(end)];
P.reason = reason;
% Ket thuc bang I <= C/50 (nhu CCCV, GD-25) ma SOC chi thieu <= lim.soc_tol so voi dich
% (sai so dien ap ROM - DFN vai mV gan day): coi la nap du (GD-82).
if ~isfield(lim, 'soc_tol'), lim.soc_tol = 0; end
P.T = Inf;
if strcmp(reason, 'soc') || (strcmp(reason, 'Icut') && x(ix.soc) >= soc_t - lim.soc_tol), P.T = t; end
P.t_end = t; P.soc_end = x(ix.soc);
P.nsim = nsim; P.wall = toc(tw);

    function [ok, xe] = step(I, h)
        xe = x;
        if ~okc(full(E.out(x, -I, Ta))), ok = false; return; end
        nsim = nsim + 1;
        try
            [~, Xs] = ode15s(@(s, xx) full(E.ode(xx, -I, Ta)), [0 h/2 h], x, ...
                odeset(opts, 'Jacobian', @(s, xx) sparse(E.jac(xx, -I, Ta))));
            if size(Xs, 1) < 3, ok = false; return; end
            xe = Xs(end, :).';
        catch
            ok = false; return;
        end
        ok = all(isfinite(xe)) && okc(full(E.out(xe, -I, Ta))) && okc(full(E.out(Xs(2, :).', -I, Ta)));
    end

    function ok = okc(o)
        ok = all(isfinite(o)) && o(io.V) + vb <= lim.Vcv + 1e-6 && o(io.T) <= lim.Tmax ...
            && o(io.eta_sep) >= lim.delta && o(io.xs_sep) <= lim.xsmax;
    end
end
