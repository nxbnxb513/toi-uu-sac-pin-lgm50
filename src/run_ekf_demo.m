function run_ekf_demo(user)
%RUN_EKF_DEMO  Sac vong kin chi dung cac dai luong do duoc (I, V, T).
%
%   - "Pin that" (plant): mo hinh luoi min, tham so bi lam lech so voi danh dinh.
%   - Bo uoc luong: EKF tren mo hinh luoi tho, tham so danh dinh, chi nhan
%     dong, dien ap va nhiet do co nhieu. Trang thai SOC ban dau bi dat sai.
%   - Bo dieu khien: profile toi uu (tinh tren mo hinh danh dinh) tra theo
%     SOC UOC LUONG; giam dong khi qua the ma Li UOC LUONG xuong duoi bien
%     an toan hoac khi dien ap do cham gioi han.
%
% Nhieu cam bien va muc lech tham so la GIA DINH cua de tai.

if nargin < 1, user = struct(); end
cfg = default_cfg(user);
if ~exist(cfg.outdir, 'dir'), mkdir(cfg.outdir); end
rng(1);

soc0 = 0.10; soc1 = 0.80; Cb = 1.0;       % vung sac minh hoa
dt = 10;                                   % s, chu ky lay mau

% ---- Profile toi uu tren mo hinh danh dinh ------------------------------
pN = params_lgm50('fine');
[best, base] = optimise_window(pN, soc0, soc1, Cb, cfg);
crates = best.crates; N = numel(crates);
edges = linspace(soc0, soc1, N+1);

% ---- Plant: tham so lech (GIA DINH) -------------------------------------
pP = params_lgm50('fine');
pP.n.Ds = 0.8*pP.n.Ds;      % khuech tan cham hon 20 %
pP.n.k  = 0.8*pP.n.k;       % dong hoc cham hon 20 %
pP.th.h = 1.2*pP.th.h;      % tan nhiet tot hon 20 %

% ---- Bo uoc luong -------------------------------------------------------
pE = params_lgm50('coarse');
ix = state_index(pE); s = ix.scale; n = ix.n;
sigV = 2e-3; sigT = 0.1; sigI = 0.01; biasI = 0.005;   % GIA DINH: 2 mV, 0.1 K, 10 mA, lech 0.5 %
Rm = diag([sigV^2, sigT^2]);
q = 1e-4*ones(n, 1); q(ix.Qsei) = 0;
Qp = diag(q.^2);                                       % nhieu qua trinh (toa do chuan hoa)
p0 = 0.05*ones(n, 1); p0(ix.T) = 1e-3; p0(ix.ce) = 0.01; p0(ix.Qsei) = 1e-6;
P = diag(p0.^2);

xP = init_state(pP, soc0, cfg.Tamb);
xE = init_state(pE, soc0 + 0.05, cfg.Tamb);            % sai 5 % SOC ban dau

kmax = ceil(3*base.t_charge/dt);
L = nan(kmax, 9); Iprev = -crates(1)*pP.Qnom; Vmeas = 0;
for k = 1:kmax
    % --- Bo dieu khien: chi dung uoc luong va so do ---
    [~, oE] = model_rhs(xE, Iprev, cfg.Tamb, pE);
    seg = find(oE.soc < edges(2:end), 1, 'first');
    if isempty(seg), break; end                        % SOC uoc luong da dat dich
    Icmd = -crates(seg)*pE.Qnom;
    if oE.etaLi_min < cfg.margin, Icmd = 0.5*Icmd; end
    if Vmeas > pE.Vmax - 0.005, Icmd = max(Icmd, 0.8*Iprev); end   % giam do lon dong
    I = Icmd;

    % --- Plant ---
    xP = step_model(xP, I, cfg.Tamb, pP, dt, 1e-6);
    [~, oP] = model_rhs(xP, I, cfg.Tamb, pP);
    y = [oP.V + sigV*randn; oP.T + sigT*randn];
    Im = I*(1 + biasI) + sigI*randn;
    Vmeas = y(1);

    % --- EKF: du bao ---
    f0 = step_model(xE, Im, cfg.Tamb, pE, dt, 1e-7);
    Aj = zeros(n);
    for i = 1:n
        xp = xE; d = 1e-3*s(i); xp(i) = xp(i) + d;
        Aj(:, i) = (step_model(xp, Im, cfg.Tamb, pE, dt, 1e-7) - f0)./s*s(i)/d;
    end
    P = Aj*P*Aj' + Qp;
    xE = f0;

    % --- EKF: cap nhat ---
    h0 = hfun(xE, Im, cfg.Tamb, pE);
    H = zeros(2, n);
    for i = 1:n
        xp = xE; d = 1e-3*s(i); xp(i) = xp(i) + d;
        H(:, i) = (hfun(xp, Im, cfg.Tamb, pE) - h0)*s(i)/d;
    end
    K = P*H'/(H*P*H' + Rm);
    xE = xE + s.*(K*(y - h0));
    P = (eye(n) - K*H)*P; P = 0.5*(P + P');
    xE(ix.cn) = min(max(xE(ix.cn), 1e-3*pE.n.cmax), 0.999*pE.n.cmax);
    xE(ix.cp) = min(max(xE(ix.cp), 1e-3*pE.p.cmax), 0.999*pE.p.cmax);
    xE(ix.ce) = max(xE(ix.ce), 10);
    xE(ix.Lsei) = max(xE(ix.Lsei), 0.5*pE.sei.L0);
    xE(ix.cLi) = max(xE(ix.cLi), 0); xE(ix.cdl) = max(xE(ix.cdl), 0);

    [~, oE2] = model_rhs(xE, Im, cfg.Tamb, pE);
    L(k, :) = [k*dt, I, y(1), y(2), oP.soc, oE2.soc, oP.etaLi_min, oE2.etaLi_min, oP.T];
    Iprev = I;
    if oP.soc > 0.99, break; end
end
L = L(~isnan(L(:, 1)), :);

% ---- Ket qua ------------------------------------------------------------
half = L(:, 1) > 0.2*L(end, 1);                        % bo doan hoi tu dau
rm = @(e) sqrt(mean(e.^2));
fid = fopen(fullfile(cfg.outdir, 'ekf_demo.md'), 'w');
fprintf(fid, '# Sac vong kin voi EKF (vung %d -> %d %%, baseline %.1fC)\n\n', 100*soc0, 100*soc1, Cb);
fprintf(fid, '- Thoi gian sac: %.1f phut (baseline CCCV tren mo hinh danh dinh: %.1f phut)\n', L(end, 1)/60, base.t_charge/60);
fprintf(fid, '- SOC that cuoi: %.2f %% (dich %.0f %%)\n', 100*L(end, 5), 100*soc1);
fprintf(fid, '- Sai so SOC ban dau cua bo uoc luong: 5 %%\n');
fprintf(fid, '- RMSE uoc luong SOC (sau 20 %% thoi gian dau): %.2f %%\n', 100*rm(L(half, 5) - L(half, 6)));
fprintf(fid, '- RMSE uoc luong qua the ma Li: %.1f mV\n', 1e3*rm(L(half, 7) - L(half, 8)));
fprintf(fid, '- Qua the ma Li nho nhat cua plant: %.1f mV\n', 1e3*min(L(:, 7)));
fprintf(fid, '- Dien ap do lon nhat: %.3f V; nhiet do lon nhat: %.2f C\n', max(L(:, 3)), max(L(:, 9)) - 273.15);
fclose(fid);
writematrix(L, fullfile(cfg.outdir, 'ekf_demo.csv'));

fig = figure('Visible', 'off', 'Position', [100 100 900 800]);
subplot(4, 1, 1); plot(L(:, 1)/60, -L(:, 2)/pN.Qnom); ylabel('Dong sac (C)'); grid on;
subplot(4, 1, 2); plot(L(:, 1)/60, 100*L(:, 5), L(:, 1)/60, 100*L(:, 6), '--');
ylabel('SOC (%)'); legend('that', 'uoc luong', 'Location', 'southeast'); grid on;
subplot(4, 1, 3); plot(L(:, 1)/60, 1e3*L(:, 7), L(:, 1)/60, 1e3*L(:, 8), '--');
ylabel('\eta_{Li} min (mV)'); legend('that', 'uoc luong'); grid on;
subplot(4, 1, 4); plot(L(:, 1)/60, L(:, 3)); ylabel('V do (V)'); xlabel('Thoi gian (phut)'); grid on;
print(fig, fullfile(cfg.outdir, 'ekf_demo.png'), '-dpng', '-r130');
close(fig);
fprintf('Da ghi ket qua EKF vao %s\n', cfg.outdir);
end

% -----------------------------------------------------------------------
function x = step_model(x, I, Tamb, p, dt, rtol)
ix = state_index(p);
opts = odeset('RelTol', rtol, 'AbsTol', rtol*1e-2*ix.scale);
[~, X] = ode15s(@(t, x) model_rhs(x, I, Tamb, p), [0 dt], x, opts);
x = X(end, :)';
end

function y = hfun(x, I, Tamb, p)
[~, o] = model_rhs(x, I, Tamb, p);
y = [o.V; o.T];
end
