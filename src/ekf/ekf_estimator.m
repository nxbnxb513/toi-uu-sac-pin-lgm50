classdef ekf_estimator < handle
%EKF_ESTIMATOR  Bo boc (handle) giu trang thai EKF giua cac lan goi, de vong kin
% NMPC (src/nmpc/nmpc_closed_loop.m, cfg.estimator) dung ma khong phai sua.
%   est = ekf_estimator(par, 'bms', soc_guess, T0, Tamb)
%   cfg.estimator = @(y, trk, meas) est.estimate(meas);
% est.estimate(meas): meas.t [s], meas.I [A], meas.V [V], meas.T [K] la gia tri DO
%   (vo huong = mot mau cuoi khoang; hoac vector = moi mau trong khoang, khuyen dung).
%   Dau dong: meas.I theo quy uoc cua nmpc_closed_loop (dong SAC >= 0); duoc doi sang
%   quy uoc DFN (> 0 la xa) ben trong. Tra ve xhat (rom.nx) cho nmpc_solve.m:
%   bo dem lao hoa n_SEI, n_dl dat = 0 (NMPC dem tu luc giai, nhu rom_from_dfn.m).
% Ghi chu tich hop: tai_lieu/bo_uoc_luong_ekf.md muc 7.
    properties
        E; c; xa; P; Tamb; t_last; I_last; log
    end
    methods
        function o = ekf_estimator(par, noise, soc_guess, T0, Tamb)
            o.E = ekf_build(par);
            o.c = ekf_config(noise);
            [o.xa, o.P] = ekf_init(o.E, o.c, soc_guess, T0);
            o.Tamb = Tamb; o.t_last = 0; o.I_last = 0;
            o.log = struct('t', [], 'soc', [], 's_soc', [], 'eta', [], 's_eta', [], 'rf', [], 'lli', []);
        end
        function xhat = estimate(o, meas)
            for k = 1:numel(meas.t)
                dt = meas.t(k) - o.t_last;
                Id = -meas.I(k);                       % sang quy uoc DFN
                if dt > 1e-3
                    u = struct('I0', o.I_last, 'I1', Id, 'dt', dt, 'Tamb', o.Tamb, 'hold', meas.t(k) < o.c.t_hold);
                    y = [meas.V(k); meas.T(k)];
                    if ~isfinite(y(1)), y = []; end    % chua co phep do (lan goi dau)
                    [o.xa, o.P] = ekf_step(o.E, o.xa, o.P, u, y, o.c);
                    o.t_last = meas.t(k);
                end
                o.I_last = Id;
            end
            q = ekf_outputs(o.E, o.xa, o.P, o.I_last, o.Tamb);
            L = o.log; L.t(end+1, 1) = o.t_last; L.soc(end+1, 1) = q.soc; L.s_soc(end+1, 1) = q.s_soc;
            L.eta(end+1, 1) = q.eta; L.s_eta(end+1, 1) = q.s_eta; L.rf(end+1, 1) = q.rf; L.lli(end+1, 1) = q.lli; o.log = L;
            xhat = o.xa(1:o.E.nx);
            xhat(o.E.ix.nsei) = 0; xhat(o.E.ix.ndl) = 0;
        end
    end
end
