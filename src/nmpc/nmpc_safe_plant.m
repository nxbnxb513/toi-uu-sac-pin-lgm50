function P = nmpc_safe_plant(par, y0, Ta, soc_t, Qstop, Imax, lim, dt, tmax)
%NMPC_SAFE_PLANT  Sac "an toan nhanh nhat" TREN PIN (DFN day du), cung luat voi
% nmpc_cccv_rom.m (GD-82): moi buoc dt [s] ap dong KHONG DOI lon nhat I <= I_max sao cho
% tren ca buoc  V <= V_cv,  T <= T_max,  eta_Li,sep >= delta,  x_s,sep <= x_s,max.
% Dung de kiem tra ngan sach (GD-88): ROM lech pin vai mV o eta_Li khi dong lon, nen
% duong nhanh nhat an toan tren ROM co the KHONG an toan tren pin (run 44237965357:
% 40->100 % 1C k = 1 va 0.5C k = 0.8 -> eta_Li min 41.2 mV < 45 mV). Neu thoi gian nay
% > ngan sach: "khong the sac an toan trong thoi gian nay".
% Dung khi Q = Qstop (SOC dich), I <= lim.Icut, hoac t >= tmax. P.T = Inf neu khong toi
% (tru Icut voi SOC thieu <= lim.soc_tol, nhu nmpc_cccv_rom).
tw = tic; nsim = 0;
trk = aging_track('init', par);
y = y0; t = 0; Iprev = Imax; reason = 'tmax'; soc = NaN;
while true
    if t >= tmax, reason = 'tmax'; break; end
    I = min(Imax, Iprev);
    [ok, yn, o] = step(I);
    if ~ok
        hi = I; lo = NaN;
        for fr = [0.97 0.9 0.7 0.4 0.15]
            [ok2, y2, o2] = step(fr*hi);
            if ok2, lo = fr*hi; yn = y2; o = o2; break; end
            hi = fr*hi;
        end
        if isnan(lo), reason = 'Icut'; break; end
        for it = 1:4
            mid = 0.5*(lo + hi);
            [ok2, y2, o2] = step(mid);
            if ok2, lo = mid; yn = y2; o = o2; else, hi = mid; end
        end
        I = lo;
    end
    if I <= lim.Icut, reason = 'Icut'; break; end
    t = t + o.t(end); y = yn; soc = o.soc(end); Iprev = I;
    if strcmp(o.reason{end}, 'Qstop'), reason = 'soc'; break; end
end
if ~isfield(lim, 'soc_tol'), lim.soc_tol = 0; end
P.T = Inf;
if strcmp(reason, 'soc') || (strcmp(reason, 'Icut') && soc >= soc_t - lim.soc_tol), P.T = t; end
P.reason = reason; P.t_end = t; P.soc_end = soc; P.nsim = nsim; P.wall = toc(tw);
fprintf('  sac an toan nhanh nhat TREN PIN (DFN, I <= %.1f A): %s, t = %.0f s, SOC %.4f (%d lan mo phong, %.0f s)\n', ...
    Imax, reason, t, soc, nsim, P.wall);

    function [ok, ye, o] = step(Ic)
        nsim = nsim + 1;
        st = struct('mode', 'I', 'value', -Ic, 'tmax', dt, 'Tamb', Ta, ...
            'stop', struct('Qstop', Qstop, 'Vmin', par.Vmin), 'tout', []);
        try
            [o, ~] = plant_run(par, y, st, trk, struct('dt', min(5, dt/2)));
        catch
            ok = false; ye = y; o = []; return
        end
        ye = o.y_end;
        ok = any(strcmp(o.reason{end}, {'time', 'Qstop'})) && all(isfinite(o.V)) ...
            && max(o.V) <= lim.Vcv + 1e-6 && max(o.T) <= lim.Tmax ...
            && min(o.eta_sep) >= lim.delta && max(o.xs_sep) <= lim.xsmax;
    end
end
