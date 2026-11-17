function [y, st, clog] = ag_set(par, y, expt, Tamb, st, opt)
%AG_SET  Mot ageing set (N chu ky) voi phuong phap NHAY CHU KY (cycle jumping) tuy chon.
%
% Phuong phap so (khong phai don gian hoa mo hinh; tai_lieu/dac_ta_lao_hoa.md muc 17, GD-58):
%   cac chu ky giong het nhau va lao hoa thay doi cham. Sau 3 chu ky dau (qua do sau RPT/
%   doi nhiet do), lap: mo phong day du 2 chu ky (a, b) bang DFN; Delta = y_b - y_a (moi
%   trang thai vi phan, do cung pha chu ky); ngoai suy tuyen tinh J chu ky:
%   y <- y_b + J Delta (J <= Jmax); trang thai dai so khoi tao nhat quan lai o chu ky sau.
%   Chu ky dau sau moi buoc nhay (a) hap thu qua do; Delta lay tren chu ky b.
%   2 chu ky cuoi cua set luon mo phong day du. Jmax = 0: mo phong tung chu ky (brute force).
% Bat bien tuyen tinh (dien tich tich luy, Li trong dien giai/SEI/ma, x_av) duoc ngoai suy
% chinh xac; tich eps_s c_avg (Li trong hat khi co LAM) chi sai bac hai - ghi lai sai so
% bao toan Li cua moi buoc nhay (st.jump_err_max).
%
% st: .n (so chu ky da xong cua set), .nsim, .njump, .t (thoi gian mo phong), .jump_err_max
% opt: .N (515), .Jmax, .deadline (now_s() > deadline -> dung, luu), .tic0
N = opt.N; nd = par.ix.nd;
clog = zeros(0, 8);   % [n, Qthr, dur, Tmax, Vmin, Vmax, ok, jumped]
while st.n < N
    if toc(opt.tic0) > opt.deadline, return; end
    if st.n < 3 || opt.Jmax == 0 || N - st.n <= 3
        [y, c] = ag_cycle(par, y, expt, Tamb); st.n = st.n + 1; st.nsim = st.nsim + 1;
        st.t = st.t + c.dur; addlog(c, 0); chk(c);
        continue
    end
    [ya, ca] = ag_cycle(par, y, expt, Tamb); st.n = st.n + 1; st.nsim = st.nsim + 1;
    st.t = st.t + ca.dur; y = ya; addlog(ca, 0); chk(ca);
    [yb, cb] = ag_cycle(par, ya, expt, Tamb); st.n = st.n + 1; st.nsim = st.nsim + 1;
    st.t = st.t + cb.dur; y = yb; addlog(cb, 0); chk(cb);
    J = min(opt.Jmax, N - st.n - 2);
    if J > 0
        d = yb(1:nd) - ya(1:nd);
        L1 = dfn_li_inventory(par, yb);
        y(1:nd) = yb(1:nd) + J*d;
        L2 = dfn_li_inventory(par, y);
        st.jump_err_max = max(st.jump_err_max, abs(L2.total - L1.total)/L1.total);
        st.n = st.n + J; st.njump = st.njump + J; st.t = st.t + J*cb.dur;
        clog(end+1, :) = [st.n, y(par.ix.ag.Qthr), J*cb.dur, NaN, NaN, NaN, 1, J]; %#ok<AGROW>
    end
end

    function addlog(c, jumped)
        clog(end+1, :) = [st.n, y(par.ix.ag.Qthr), c.dur, c.Tmax, c.Vmin, c.Vmax, c.ok, jumped];
        st.reasons{end+1} = c.reason;
    end
    function chk(c)
        if ~c.ok, error('ag_set: chu ky %d that bai (%s)', st.n, c.reason); end
    end
end
