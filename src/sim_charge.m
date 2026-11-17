function r = sim_charge(p, soc0, soc1, crates, cfg)
%SIM_CHARGE  Mo phong mot lan sac tu soc0 den soc1 (0..1).
%
%   crates: vector C-rate sac (duong) cho N doan co do rong SOC bang nhau.
%           N = 1 chinh la sac CCCV: dong khong doi, neu cham Vmax thi giu ap.
%   Ket qua r: thoi gian sac, cac chi so lao hoa, va chuoi thoi gian.

ix = state_index(p);
N = numel(crates);
edges = linspace(soc0, soc1, N+1);

x = init_state(p, soc0, cfg.Tamb);
z = [x; -crates(1)*p.Qnom];            % trang thai mo rong: them dong I
abstol = [1e-7*ix.scale; 1e-5];

mode = 1;                              % 1 = dong khong doi, 2 = giu ap
t0 = 0; tt = []; ZZ = [];
k = 1; reached = false;
while k <= N
    Icmd = -crates(k)*p.Qnom;
    if mode == 2, target = soc1; else, target = edges(k+1); end
    opts = odeset('RelTol', 1e-5, 'AbsTol', abstol, 'MaxStep', 120, ...
        'Events', @(t, z) ev(z, target, mode, p, cfg));
    [t, Z, ~, ~, ie] = ode15s(@(t, z) rhs(z, Icmd, mode, p, cfg), ...
        [t0, t0 + cfg.tmax], z, opts);
    tt = [tt; t]; ZZ = [ZZ; Z]; %#ok<AGROW>
    t0 = t(end); z = Z(end, :)';
    if isempty(ie), break; end         % het thoi gian
    ie = ie(end);
    if ie == 1                          % dat muc SOC cua doan
        if mode == 2 || k == N, reached = true; break; end
        k = k + 1;
    elseif ie == 2                      % cham Vmax: chuyen sang giu ap
        mode = 2;
    else                                % dong CV tut duoi nguong cat
        break;
    end
end
t_charge = t0;
x_end = z(1:end-1);

% Nghi sau khi sac (I = 0)
if cfg.t_rest > 0
    opts = odeset('RelTol', 1e-5, 'AbsTol', 1e-7*ix.scale, 'MaxStep', 300);
    [~, X] = ode15s(@(t, x) model_rhs(x, 0, cfg.Tamb, p), [0 cfg.t_rest], x_end, opts);
    x_rest = X(end, :)';
else
    x_rest = x_end;
end

% Chuoi thoi gian
n = numel(tt);
V = zeros(n, 1); T = V; soc = V; eta = V; Ic = ZZ(:, end);
for i = 1:n
    [~, o] = model_rhs(ZZ(i, 1:end-1)', Ic(i), cfg.Tamb, p);
    V(i) = o.V; T(i) = o.T; soc(i) = o.soc; eta(i) = o.etaLi_min;
end
[~, oe] = model_rhs(x_rest, 0, cfg.Tamb, p);

r.t = tt; r.V = V; r.T = T; r.soc = soc; r.etaLi = eta; r.I = Ic;
r.crates = crates(:)';
r.reached   = reached;
r.used_cv   = (mode == 2);
r.t_charge  = t_charge;                 % s
r.soc_end   = soc(end);
r.V_peak    = max(V);
r.T_peak    = max(T);
r.etaLi_min = min(eta);
r.Qsei      = oe.Qsei;                  % Ah, Li mat vao SEI (sac + nghi)
r.Qdead     = oe.Qdead;                 % Ah, Li chet
r.Qplate    = oe.Qplate;                % Ah, Li ma con lai sau khi nghi
r.LLI       = oe.Qsei + oe.Qdead;       % Ah
% Chi so lao hoa dung de toi uu: tinh ca Li ma con lai (truong hop xau nhat).
r.aging     = r.LLI + r.Qplate;
end

% -----------------------------------------------------------------------
function dz = rhs(z, Icmd, mode, p, cfg)
I = z(end);
[dx, o] = model_rhs(z(1:end-1), I, cfg.Tamb, p);
if mode == 1
    dI = (Icmd - I)/cfg.tau;
else
    dI = cfg.Kcv*(o.V - p.Vmax);
end
dz = [dx; dI];
end

function [val, term, dir] = ev(z, target, mode, p, cfg)
[~, o] = model_rhs(z(1:end-1), z(end), cfg.Tamb, p);
v1 = o.soc - target;
if mode == 1
    v2 = o.V - p.Vmax; v3 = 1;
else
    v2 = 1; v3 = abs(z(end)) - cfg.Icut;
end
val = [v1; v2; v3];
term = [1; 1; 1];
dir = [1; 1; -1];
end
