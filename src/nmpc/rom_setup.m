function rom = rom_setup(par, opt)
%ROM_SETUP  Cau hinh mo hinh rut gon (ROM) dan xuat tu DFN (src/dfn).
%   rom = rom_setup(par)        par = dfn_params() (bo 'approved', luoi mac dinh)
%   rom = rom_setup(par, opt)   opt ghi de: cellsn, cellss, cellsp (so o DFN gop
%                               vao moi o ROM), shn, shp (mat vo hat theo don vi
%                               R/Nr cua DFN), ngl (so diem Gauss-Legendre)
%   rom = rom_setup(par, 'B')   cau hinh dat ten (rom_preset.m)
%
% Luoi ROM duoc chon sao cho MOI mat o / mat vo cua ROM trung voi mot mat cua
% luoi DFN. Nho vay:
%   - anh xa trang thai DFN -> ROM la trung binh the tich CHINH XAC (bao toan Li);
%   - o ROM cuoi cung cua cuc am (sat mang ngan) rong dung 1 o DFN, nen tam cua
%     no trung tam nut DFN sat mang ngan nhat (x = L_n - L_n/40): the ma lithium
%     va stoich be mat "phia mang ngan" cua hai mo hinh so sanh tai CUNG mot vi tri.
% Xem tai_lieu/mo_hinh_rut_gon.md.
if nargin < 2 || isempty(opt), opt = struct(); end
if ischar(opt), opt = rom_preset(opt); end
g = par.grid;
rom.cellsn = getopt(opt, 'cellsn', [9 6 4 1]);
rom.cellss = getopt(opt, 'cellss', g.Ns);
rom.cellsp = getopt(opt, 'cellsp', [10 10]);
rom.shn    = getopt(opt, 'shn', [0 20 32 40 46 51 55 58 60]);
rom.shp    = getopt(opt, 'shp', [0 10 15 18 20]);
rom.ngl    = getopt(opt, 'ngl', 8);
rom.name   = getopt(opt, 'name', 'tuy_chinh');
if sum(rom.cellsn) ~= g.Nn || sum(rom.cellss) ~= g.Ns || sum(rom.cellsp) ~= g.Np
    error('rom_setup: so o gop khong khop luoi DFN [%d %d %d]', g.Nn, g.Ns, g.Np);
end
if rom.shn(end) ~= g.Nrn || rom.shp(end) ~= g.Nrp || rom.shn(1) ~= 0 || rom.shp(1) ~= 0
    error('rom_setup: mat vo hat phai di tu 0 toi Nr cua DFN (%d, %d)', g.Nrn, g.Nrp);
end
Nn = numel(rom.cellsn); Ns = numel(rom.cellss); Np = numel(rom.cellsp); N = Nn + Ns + Np;
rom.Nn = Nn; rom.Ns = Ns; rom.Np = Np; rom.N = N;
rom.in = (1:Nn).'; rom.is = (Nn+1:Nn+Ns).'; rom.ip = (Nn+Ns+1:N).';
rom.dx = [rom.cellsn(:)*g.dxn; rom.cellss(:)*g.dxs; rom.cellsp(:)*g.dxp];
% anh xa o ROM -> cac o DFN (chi so toan cuc 1..g.N)
cnt = [rom.cellsn(:); rom.cellss(:); rom.cellsp(:)];
e = cumsum(cnt); b = e - cnt + 1;
rom.mapx = arrayfun(@(k) (b(k):e(k)).', (1:N).', 'UniformOutput', false);
rom.mapn = rom.mapx(rom.in);                                     % chi so o DFN cuc am
rom.mapp = cellfun(@(v) v - g.Nn - g.Ns, rom.mapx(rom.ip), 'UniformOutput', false);  % chi so cuc bo cuc duong
rom.xc = cumsum(rom.dx) - rom.dx/2;
% ---- hat: vo cau theo cac mat da chon -----------------------------------
[rom.Nrn, rom.rfn, rom.Vshn, rom.rcn, rom.rmapn, rom.cextn] = shells(rom.shn, par.neg.Rp);
[rom.Nrp, rom.rfp, rom.Vshp, rom.rcp, rom.rmapp, rom.cextp] = shells(rom.shp, par.pos.Rp);
% ---- tinh chat BOL lay tu hook cua DFN (giong het DFN) -------------------
ag = dfn_aging_state(par, []);
rom.eps = cellfun(@(v) mean(ag.eps(v)), rom.mapx);
rom.eps_region = [mean(ag.eps(g.in)), mean(ag.eps(g.is)), mean(ag.eps(g.ip))];   % nhu dfn_rhocp.m
rom.brug = [par.neg.brug_e*ones(Nn,1); par.sep.brug_e*ones(Ns,1); par.pos.brug_e*ones(Np,1)];
if any(abs(ag.as_n - ag.as_n(1)) > 0) || any(abs(ag.Rfilm_n - ag.Rfilm_n(1)) > 0) || any(abs(ag.as_p - ag.as_p(1)) > 0)
    error('rom_setup: tinh chat BOL khong deu theo x - ROM gia thiet deu');
end
rom.as_n = ag.as_n(1); rom.as_p = ag.as_p(1);
rom.Rfilm_n = ag.Rfilm_n(1); rom.Rfilm_p = ag.Rfilm_p(1);
% ---- dung luong dung de dinh nghia SOC ----------------------------------
% SOC = (x_avg - x0)/(x100 - x0) cua cuc am; dung luong tuong ung (Ah):
rom.Csoc = par.neg.Qcap*(par.neg.x100 - par.neg.x0);
% ---- Gauss-Legendre tren [0, 1] (Golub-Welsch) ---------------------------
n = rom.ngl;
bta = 0.5./sqrt(1 - (2*(1:n-1)).^(-2));
[Vv, Dd] = eig(diag(bta, 1) + diag(bta, -1));
[s, o] = sort(diag(Dd));
rom.gl.s = (s + 1)/2;
rom.gl.w = (2*Vv(1, o).'.^2)/2;
% ---- tham so lao hoa tam thoi -------------------------------------------
rom.ap = aging_params(par);
% ---- chi so vector trang thai x va bien dai so z -------------------------
k = 0;
ix.thn = (k+1 : k+rom.Nrn*Nn).'; k = k + rom.Nrn*Nn;
ix.thp = (k+1 : k+rom.Nrp*Np).'; k = k + rom.Nrp*Np;
ix.ce  = (k+1 : k+N).';          k = k + N;
ix.T   = k+1;                    k = k + 1;
ix.soc = k+1;                    k = k + 1;
ix.cLi = (k+1 : k+Nn).';         k = k + Nn;
ix.nsei = k+1;                   k = k + 1;
ix.npl  = k+1;                   k = k + 1;
ix.ndl  = k+1;                   k = k + 1;
rom.nx = k; rom.ix = ix;
k = 0;
iz.jn = (k+1 : k+Nn).'; k = k + Nn;
iz.jp = (k+1 : k+Np).'; k = k + Np;
iz.phie1  = k+1; k = k + 1;
iz.phisp1 = k+1; k = k + 1;
rom.nz = k; rom.iz = iz;
% sai so tuyet doi cho ode15s (cung muc nhu dfn_mesh.m)
at = zeros(rom.nx, 1);
at(ix.thn) = 1e-7; at(ix.thp) = 1e-7; at(ix.ce) = 1e-6; at(ix.T) = 1e-4; at(ix.soc) = 1e-7;
at(ix.cLi) = 1e-6; at(ix.nsei) = 1e-9; at(ix.npl) = 1e-9; at(ix.ndl) = 1e-12;
rom.atol_x = at; rom.atol_z = 1e-6*ones(rom.nz, 1);
end

function [Nr, rf, Vsh, rc, rmap, cext] = shells(sh, R)
Nrd = sh(end);
Nr = numel(sh) - 1;
rf = sh(:)/Nrd*R;                          % mat vo (Nr + 1)
Vsh = (rf(2:end).^3 - rf(1:end-1).^3)/3;  % the tich vo / (4 pi)
rc = (rf(1:end-1) + rf(2:end))/2;          % tam vo
rmap = arrayfun(@(s) (sh(s)+1 : sh(s+1)).', (1:Nr).', 'UniformOutput', false);
% stoich be mat: ngoai suy tuyen tinh tu tam hai vo ngoai cung (nhu dfn_rhs.m)
cext = (R - rc(end))/(rc(end) - rc(end-1));
end

function v = getopt(opt, name, default)
if isfield(opt, name) && ~isempty(opt.(name)), v = opt.(name); else, v = default; end
end
