function [x, z0] = rom_from_dfn(rom, par, y, trk)
%ROM_FROM_DFN  Anh xa trang thai DFN day du y (va bo dem lao hoa trk) sang
% trang thai ROM x. Dung cho NMPC "biet het trang thai" (bo uoc luong EKF o
% buoc sau se tra ve truc tiep x).
%   - stoich trong hat: trung binh THE TICH cua cac vo DFN nam trong moi vo ROM,
%     va trung binh cac nut DFN nam trong moi o ROM (moi mat ROM trung mat DFN,
%     rom_setup.m) => tong lithium trong pha ran duoc bao toan dung;
%   - c_e: trung binh cac o DFN trong o ROM (cung eps, cung dx) => bao toan Li dien giai;
%   - T: giong; SOC = (x_avg - x0)/(x100 - x0) cua cuc am;
%   - c_Li: trung binh bo dem hau kiem theo nut; n_SEI = 0 (NMPC dem tu luc giai);
%     n_pl = luong lithium ma hien co (mAh).
% z0: doan dau cho bien dai so (trung binh j, phi_e, phi_s cua DFN tren o ROM).
g = par.grid; ix = par.ix;
thn = reshape(y(ix.thn), g.Nrn, g.Nn); thp = reshape(y(ix.thp), g.Nrp, g.Np);
x = zeros(rom.nx, 1);
x(rom.ix.thn) = avg_particles(thn, rom.mapn, rom.rmapn, g.Vshn);
x(rom.ix.thp) = avg_particles(thp, rom.mapp, rom.rmapp, g.Vshp);
ce = y(ix.ce);
x(rom.ix.ce) = cellfun(@(v) mean(ce(v)), rom.mapx);
x(rom.ix.T) = y(ix.T);
xavg = mean((g.Vshn.'*thn)/sum(g.Vshn));
x(rom.ix.soc) = (xavg - par.neg.x0)/(par.neg.x100 - par.neg.x0);
if nargin < 4 || isempty(trk), trk = aging_track('init', par); end
x(rom.ix.cLi) = cellfun(@(v) mean(trk.cLi(v)), rom.mapn);
x(rom.ix.nsei) = 0;
x(rom.ix.npl) = trk.npl;
if nargout > 1
    jn = y(ix.jn); jp = y(ix.jp); phie = y(ix.phie); phisp = y(ix.phisp);
    z0 = zeros(rom.nz, 1);
    z0(rom.iz.jn) = cellfun(@(v) mean(jn(v)), rom.mapn);
    z0(rom.iz.jp) = cellfun(@(v) mean(jp(v)), rom.mapp);
    z0(rom.iz.phie1) = mean(phie(rom.mapx{1}));
    z0(rom.iz.phisp1) = mean(phisp(rom.mapp{1}));
end
end

function v = avg_particles(th, mapc, mapr, Vsh)
Nc = numel(mapc); Nr = numel(mapr);
v = zeros(Nr, Nc);
for c = 1:Nc
    for s = 1:Nr
        r = mapr{s}; w = Vsh(r);
        v(s, c) = mean((w.'*th(r, mapc{c}))/sum(w));
    end
end
v = v(:);
end
