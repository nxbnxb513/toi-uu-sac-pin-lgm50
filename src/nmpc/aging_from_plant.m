function nat = aging_from_plant(par, Y)
%AGING_FROM_PLANT  Doc lao hoa CUA CHINH DFN (buoc C, src/dfn, mo hinh "5 coupled").
%   nat = aging_from_plant(par, Y)    Y: cac trang thai DFN (cot) doc theo quy dao
% Tra ve [] neu DFN chay KHONG co lao hoa (par.aging.on = false) => plant_run.m dung
% bo dem hau kiem TAM THOI (aging_track.m). Neu co, tra ve vector cot (mAh, gia tri
% TICH LUY trong trang thai DFN, tinh bang so sach lithium dfn_li_inventory.m cua src/dfn):
%   nat.nsei = SEI be mat + SEI tren vet nut
%   nat.ndl  = lithium chet
%   nat.npl  = lithium ma (thuan nghich + chet, cung quy uoc voi aging_track.m)
%   nat.nlam = lithium nam trong vat lieu hoat tinh da mat (LAM, ca hai cuc)
% plant_run.m tru gia tri dau vung. Mat VINH VIEN = nsei + ndl + nlam (eval_discharge.m).
nat = [];
if ~(isfield(par, 'aging') && isfield(par.aging, 'on') && par.aging.on), return; end
nt = size(Y, 2);
nat.nsei = zeros(nt, 1); nat.ndl = zeros(nt, 1); nat.npl = zeros(nt, 1); nat.nlam = zeros(nt, 1);
mAh = par.F/3.6;                                  % mol -> mAh
for i = 1:nt
    L = dfn_li_inventory(par, Y(:, i));
    nat.nsei(i) = (L.sei + L.seicr)*mAh;
    nat.ndl(i)  = L.dead*mAh;
    nat.npl(i)  = (L.plated + L.dead)*mAh;
    nat.nlam(i) = (L.lam_n + L.lam_p)*mAh;
end
nat.source = 'plant';
end
