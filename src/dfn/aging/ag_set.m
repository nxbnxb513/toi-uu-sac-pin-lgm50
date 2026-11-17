function [y, st, clog] = ag_set(par, y, expt, Tamb, st, opt)
%AG_SET  Mot ageing set (N chu ky) voi phuong phap NHAY CHU KY (cycle jumping) tuy chon.
%
% Phuong phap so (khong phai don gian hoa mo hinh; tai_lieu/dac_ta_lao_hoa.md muc 17, GD-58):
%   cac chu ky giong het nhau va lao hoa thay doi cham. Sau 3 chu ky dau (qua do sau RPT/
%   doi nhiet do), lap: mo phong day du 2 chu ky (a, b) bang DFN; ngoai suy J chu ky bang
%   ag_jump (chi cac trang thai lao hoa cham + dich deu Li trong hat moi dien cuc; trang thai
%   nhanh giu nhu chu ky b; bao toan Li chinh xac). J <= Jmax. Chu ky dau sau moi buoc nhay
%   (a) hap thu qua do; Delta lay tren chu ky b. 2 chu ky cuoi cua set luon mo phong day du.
%   Jmax = 0: mo phong tung chu ky (brute force).
% Lui buoc (18/11/2026): neu trang thai sau nhay ra ngoai mien vat ly, J giam mot nua (thu
% lai); neu chu ky ngay sau buoc nhay that bai, tra ve trang thai truoc buoc nhay, J giam
% mot nua cho phan con lai cua set (J = 0: tung chu ky). Ghi so lan lui (st.nback).
%
% st: .n (so chu ky da xong cua set), .nsim, .njump, .t (thoi gian mo phong), .jump_err_max,
%     .Jcur (J hien hanh cua set), .nback
% opt: .N (515), .Jmax, .deadline (toc(opt.tic0) > deadline -> dung, luu), .tic0
N = opt.N;
if ~isfield(st, 'Jcur') || isempty(st.Jcur), st.Jcur = opt.Jmax; end
if ~isfield(st, 'nback') || isempty(st.nback), st.nback = 0; end
clog = zeros(0, 8);   % [n, Qthr, dur, Tmax, Vmin, Vmax, ok, jumped]
bak = [];             % trang thai truoc buoc nhay gan nhat (de lui)
while st.n < N
    if toc(opt.tic0) > opt.deadline, return; end
    if st.n < 3 || st.Jcur == 0 || N - st.n <= 3
        [y1, c] = ag_cycle(par, y, expt, Tamb);
        if ~c.ok && back(c), continue; end
        y = y1; st.n = st.n + 1; st.nsim = st.nsim + 1;
        st.t = st.t + c.dur; addlog(c, 0); chk(c); bak = [];
        continue
    end
    [ya, ca] = ag_cycle(par, y, expt, Tamb);
    if ~ca.ok && back(ca), continue; end
    st.n = st.n + 1; st.nsim = st.nsim + 1;
    st.t = st.t + ca.dur; y = ya; addlog(ca, 0); chk(ca); bak = [];
    [yb, cb] = ag_cycle(par, ya, expt, Tamb);
    st.n = st.n + 1; st.nsim = st.nsim + 1;
    st.t = st.t + cb.dur; y = yb; addlog(cb, 0); chk(cb);
    J = min(st.Jcur, N - st.n - 2);
    while J > 0
        [yj, info] = ag_jump(par, ya, yb, J);
        if info.ok, break; end
        fprintf('ag_set: nhay J = %d ra ngoai mien vat ly -> J = %d\n', J, floor(J/2));
        J = floor(J/2);
    end
    if J > 0
        bak = struct('y', yb, 'st', st, 'nlog', size(clog, 1), 'J', J);
        y = yj;
        st.jump_err_max = max(st.jump_err_max, info.err);
        st.n = st.n + J; st.njump = st.njump + J; st.t = st.t + J*cb.dur;
        clog(end+1, :) = [st.n, y(par.ix.ag.Qthr), J*cb.dur, NaN, NaN, NaN, 1, J]; %#ok<AGROW>
    end
end

    function did = back(c)
        % chu ky ngay sau buoc nhay that bai -> lui ve truoc buoc nhay, giam J
        did = false;
        if isempty(bak), return; end
        Jn = floor(bak.J/2);
        fprintf('ag_set: chu ky sau buoc nhay J = %d that bai (%s) -> lui ve chu ky %d, J = %d\n', ...
            bak.J, c.reason, bak.st.n, Jn);
        y = bak.y; nb = st.nback; st = bak.st; st.nback = nb + 1; st.Jcur = Jn;
        clog = clog(1:bak.nlog, :);
        bak = []; did = true;
    end
    function addlog(c, jumped)
        clog(end+1, :) = [st.n, y(par.ix.ag.Qthr), c.dur, c.Tmax, c.Vmin, c.Vmax, c.ok, jumped];
        st.reasons{end+1} = c.reason;
    end
    function chk(c)
        if ~c.ok, error('ag_set: chu ky %d that bai (%s)', st.n, c.reason); end
    end
end
