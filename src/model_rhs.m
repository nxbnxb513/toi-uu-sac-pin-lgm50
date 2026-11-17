function [dx, o] = model_rhs(x, I, Tamb, p)
%MODEL_RHS  Ve phai cua mo hinh pin ghep dien hoa - nhiet - lao hoa.
%
%   [dx, o] = model_rhs(x, I, Tamb, p)
%   x    vector trang thai (xem state_index)
%   I    dong dien [A], I > 0 khi xa, I < 0 khi sac
%   Tamb nhiet do moi truong [K]
%   o    cac dai luong dau ra: V, T, soc, etaLi (theo vi tri), etaLi_min, ...
%
% Mo hinh: single-particle co chat dien phan (SPMe) cho moi dien cuc,
% nhiet 0D, SEI phu thuoc dien the anode, ma Li va Li chet phan giai theo
% chieu day dien cuc am. Xem tai_lieu/mo_hinh_toan.md.

ix = state_index(p);
F = p.F; R = p.R;
T = x(ix.T);
RT = R*T;

arr = @(E) exp(E/(R*p.Tref) - E/RT);       % [1] pt. S1, S2, S4, S5

% ------------------------------------------------------------------ luoi
Nn = p.Nn; Ns = p.Ns; Np = p.Np;
dxc  = [p.n.L/Nn*ones(Nn,1); p.s.L/Ns*ones(Ns,1); p.p.L/Np*ones(Np,1)];
epsc = [p.n.eps_e*ones(Nn,1); p.s.eps_e*ones(Ns,1); p.p.eps_e*ones(Np,1)];
ce = max(x(ix.ce), 1);
in = 1:Nn; ip = Nn+Ns+(1:Np);
ce_n = mean(ce(in)); ce_p = mean(ce(ip)); ce_s = mean(ce(Nn+(1:Ns)));

% ------------------------------------------------- thong luong tai be mat
Ntot_n =  I/(F*p.n.a*p.n.L*p.A);     % mol/(m^2 s), > 0 khi xa (Li roi hat)
Ntot_p = -I/(F*p.p.a*p.p.L*p.A);

Dn = p.n.Ds*arr(p.n.EDs);
Dp = p.p.Ds*arr(p.p.EDs);
dr_n = p.n.Rp/p.Nr; dr_p = p.p.Rp/p.Nr;

cn = x(ix.cn); cp = x(ix.cp);
cns = cn(end) - Ntot_n*dr_n/(2*Dn);          % nong do be mat (ngoai suy)
cps = cp(end) - Ntot_p*dr_p/(2*Dp);
cns = min(max(cns, 1e-3*p.n.cmax), (1-1e-3)*p.n.cmax);
cps = min(max(cps, 1e-3*p.p.cmax), (1-1e-3)*p.p.cmax);
xs = cns/p.n.cmax; ys = cps/p.p.cmax;

[Up, Un, dUp, dUn] = ocp(ys, xs);

% ------------------------------------------------ dong hoc Butler-Volmer
% [1] Bang S1: N = 2 k sqrt(ce/ceq (cmax-cs) cs) sinh(F eta / 2RT)
kn = p.n.k*arr(p.n.Ek); kp = p.p.k*arr(p.p.Ek);
N0n = 2*kn*sqrt(ce_n/p.ce0*(p.n.cmax - cns)*cns);
N0p = 2*kp*sqrt(ce_p/p.ce0*(p.p.cmax - cps)*cps);
eta_n = 2*RT/F*asinh(Ntot_n/N0n);
eta_p = 2*RT/F*asinh(Ntot_p/N0p);

% ------------------------------------------------------- chat dien phan
kap = @(c) (1.297e-10*c.^3 - 7.94e-5*c.^1.5 + 3.329e-3*c)*arr(p.Ee);      % [1] S6
Dee = @(c) (8.794e-17*c.^2 - 3.972e-13*c + 4.862e-10)*arr(p.Ee);          % [1] S7
kn_eff = p.n.eps_e^p.brug*kap(ce_n);
ks_eff = p.s.eps_e^p.brug*kap(ce_s);
kp_eff = p.p.eps_e^p.brug*kap(ce_p);
sn_eff = p.n.eps_s^p.brug*p.n.sigma;
sp_eff = p.p.eps_s^p.brug*p.p.sigma;
iapp = I/p.A;
tf = 2*RT/F*(1 - p.tplus);

dphie = tf*log(ce_p/ce_n) ...
        - iapp*(p.n.L/(3*kn_eff) + p.s.L/ks_eff + p.p.L/(3*kp_eff));
dphis = -iapp*(p.n.L/(3*sn_eff) + p.p.L/(3*sp_eff));

% --------------------------------------------------------------- SEI
Lsei = max(x(ix.Lsei), 0.1*p.sei.L0);
iloc = I/(p.A*p.n.L*p.n.a);                 % A/m^2 be mat hat, > 0 khi xa
eta_sei = p.sei.rho*Lsei*iloc;              % [1] pt. (8), theo vi tri
eta_sei_avg = mean(eta_sei);

V = (Up + eta_p) - (Un + eta_n + eta_sei_avg) + dphie + dphis;

% ------------------------- dien the anode theo vi tri (de tai dan xuat)
% phi_s - phi_e tai tam cac o cua dien cuc am, x = 0 la collector.
xc = ((1:Nn)' - 0.5)*p.n.L/Nn;
dphi_avg = Un + eta_n + eta_sei_avg;
dps = -iapp/sn_eff*(xc - xc.^2/(2*p.n.L) - p.n.L/3);
dpe = -iapp/kn_eff*(xc.^2/(2*p.n.L) - p.n.L/6) + tf*log(ce(in)/ce_n);
dphi = dphi_avg + dps - dpe;                % phi_s - phi_e theo vi tri
etaLi = dphi - eta_sei;                     % [1] pt. (16)

% SEI gioi han boi khuech tan Li xen ke, [7] SI Note 2 (S2), (S5), (S6)
jsei = p.sei.cint*p.sei.Dint*arr(p.sei.E)*F .* exp(-F*dphi/RT) ./ (Lsei/2);   % A/m^2
dLsei = jsei*p.sei.V/(2*F);

% Ma Li / boc Li / Li chet, [1] pt. (12)-(15)
cLi = max(x(ix.cLi), 0);
NLi = p.pl.k*(cLi.*exp(F*p.pl.aa*etaLi/RT) - ce(in).*exp(-F*p.pl.ac*etaLi/RT));  % > 0 khi boc
gam = p.pl.gamma0*p.sei.L0./Lsei;
dcLi = -p.n.a*NLi - gam.*cLi;
dcdl = gam.*cLi;

% Thong luong xen cai thuc vao hat am: tong tru phan ung phu
Nint_n = Ntot_n + mean(jsei)/F - mean(NLi);
Nint_p = Ntot_p;

% ------------------------------------------------- khuech tan trong hat
dcn = particle_rhs(cn, Dn, p.n.Rp, Nint_n);
dcp = particle_rhs(cp, Dp, p.p.Rp, Nint_p);

% ------------------------------------- bao toan khoi luong dien phan
De_c = epsc.^p.brug.*Dee(ce);
dxf = 0.5*(dxc(1:end-1) + dxc(2:end));
De_f = dxf*2 ./ (dxc(1:end-1)./De_c(1:end-1) + dxc(2:end)./De_c(2:end));  % trung binh dieu hoa
flux = -De_f.*diff(ce)./dxf;                         % mol/(m^2 s)
fl = [0; flux; 0];
src = zeros(numel(ce), 1);
src(in) =  (1 - p.tplus)*I/(F*p.A*p.n.L);
src(ip) = -(1 - p.tplus)*I/(F*p.A*p.p.L);
dce = (-diff(fl)./dxc + src)./epsc;

% --------------------------------------------------------------- nhiet
Qirr = I*(Up - Un - V);
Qrev = -I*T*(dUp - dUn);
dT = (Qirr + Qrev - p.th.h*p.th.As*(T - Tamb))/(p.th.m*p.th.Cp);

% ------------------------------------------------------------- ghep lai
dx = zeros(ix.n, 1);
dx(ix.cn) = dcn; dx(ix.cp) = dcp; dx(ix.ce) = dce; dx(ix.T) = dT;
dx(ix.Lsei) = dLsei; dx(ix.cLi) = dcLi; dx(ix.cdl) = dcdl;
dx(ix.Qsei) = p.n.a*p.n.L*p.A*mean(jsei);            % A -> tich phan ra C

if nargout > 1
    w = shell_volumes(p.Nr);
    xbar = (w'*cn)/p.n.cmax;
    o.V = V; o.T = T;
    o.soc = (xbar - p.n.x0)/(p.n.x100 - p.n.x0);
    o.etaLi = etaLi; o.etaLi_min = min(etaLi);
    o.dphi = dphi; o.jsei = jsei; o.NLi = NLi;
    o.xs = xs; o.ys = ys;
    o.Qheat = Qirr + Qrev;
    % Luong Li [Ah] da mat vao SEI, Li chet, va Li dang ma (con boc lai duoc)
    o.Qsei   = x(ix.Qsei)/3600;
    o.Qdead  = F*mean(x(ix.cdl))*p.n.L*p.A/3600;
    o.Qplate = F*mean(cLi)*p.n.L*p.A/3600;
end
end

% =======================================================================
function dc = particle_rhs(c, D, Rp, Nsurf)
% The tich huu han cho khuech tan cau; Nsurf la thong luong roi hat.
N = numel(c);
dr = Rp/N;
rf = (0:N)'*dr;                              % mat phan cach
vol = (rf(2:end).^3 - rf(1:end-1).^3)/3;
g = zeros(N+1, 1);                           % D r^2 dc/dr tai cac mat
g(2:N) = D*rf(2:N).^2.*diff(c)/dr;
g(N+1) = -Nsurf*Rp^2;
dc = diff(g)./vol;
end

function w = shell_volumes(N)
rf = (0:N)'/N;
w = rf(2:end).^3 - rf(1:end-1).^3;           % tong bang 1
end
