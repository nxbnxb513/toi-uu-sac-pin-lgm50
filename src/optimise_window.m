function [best, base, info] = optimise_window(p, soc0, soc1, Cbase, cfg)
%OPTIMISE_WINDOW  Toi uu dong sac cho mot vung SOC va so voi baseline CCCV.
%
%   base: sac CCCV o muc Cbase tu soc0 den soc1.
%   best: profile nhieu doan dong khong doi, CUNG thoi gian sac voi baseline,
%         co chi so lao hoa nho nhat tim duoc.
%
% Bien toi uu: theta (N-1 so). Thoi luong cac doan t_k = Tb * softmax(theta).
% Moi doan nap cung mot luong dien tich, nen tong thoi gian luon bang Tb.
% theta = 0 cho dong khong doi, tuc gan trung voi baseline. Vi tim kiem bat
% dau tu theta = 0 nen ket qua khong bao gio te hon diem xuat phat do.

base = sim_charge(p, soc0, soc1, Cbase, cfg);
Tb = base.t_charge;
N = cfg.Nseg;
dQ = (soc1 - soc0)*p.Qcap/N;            % Ah moi doan

    function c = to_crates(theta)
        w = exp([theta(:); 0]); w = w/sum(w);
        c = dQ./(Tb*w/3600)/p.Qnom;
    end

    function [J, r] = cost(theta)
        c = to_crates(theta);
        if any(c > 3*cfg.Cmax) || any(~isfinite(c))
            J = 1e3; r = []; return;
        end
        r = sim_charge(p, soc0, soc1, c, cfg);
        J = r.aging/max(base.aging, 1e-12) ...
            + 100*max(0, (r.t_charge - Tb)/Tb - 0.01) ...
            + 100*(~r.reached) ...
            + 10*sum(max(0, c/cfg.Cmax - 1)) ...
            + 10*max(0, (r.T_peak - cfg.Tmax)/10) ...
            + 10*max(0, (cfg.margin - r.etaLi_min)/0.05);
    end

% Tim kiem theo toa do (pattern search), khong can toolbox.
theta = zeros(N-1, 1);
[Jb, rb] = cost(theta);
nev = 1; step = 0.6;
while step > 0.05 && nev < cfg.maxEval
    improved = false;
    for i = 1:N-1
        for s = [1 -1]
            if nev >= cfg.maxEval, break; end
            th = theta; th(i) = th(i) + s*step;
            [J, r] = cost(th); nev = nev + 1;
            if J < Jb - 1e-6
                Jb = J; rb = r; theta = th; improved = true;
            end
        end
    end
    if ~improved, step = step/2; end
end

best = rb;
info.theta = theta; info.J = Jb; info.nev = nev; info.Tb = Tb;
end
