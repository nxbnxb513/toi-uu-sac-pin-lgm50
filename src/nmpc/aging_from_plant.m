function nat = aging_from_plant(par, a)
%AGING_FROM_PLANT  Doc lao hoa CUA CHINH DFN (khi buoc C da cai lao hoa vao src/dfn).
%   nat = aging_from_plant(par, a)    a: cell cac struct aux cua dfn_rhs.m doc theo quy dao
% Tra ve [] neu DFN chua co lao hoa => chay hau kiem TAM THOI (aging_track.m).
% Neu co, tra ve nat.nsei, nat.ndl, nat.npl (vector cot, mAh, gia tri TICH LUY trong
% trang thai DFN): lithium mat do SEI (ca vet nut), lithium chet, lithium ma (thuan
% nghich + chet, cung quy uoc voi aging_track.m). plant_run.m tru gia tri dau vung.
%
% Quy uoc giao dien (DAY LA NOI DUY NHAT phai sua neu src/dfn dat ten khac):
%   aux.aging.nsei_mAh, aux.aging.ndl_mAh, aux.aging.npl_mAh   (vo huong, mAh)
% hoac, neu chi co luong mol/dien tich: aux.aging.Q_sei, Q_dead, Q_plated [C].
% Neu DFN da co phan ung phu (aux.aging ton tai) ma khong khop quy uoc nao o tren
% thi BAO LOI, khong am tham dung hau kiem (de khong tron hai cach cham diem).
nat = [];
if isempty(a) || ~isfield(a{1}, 'aging') || isempty(a{1}.aging), return; end
ag = a{1}.aging;
if all(isfield(ag, {'nsei_mAh', 'ndl_mAh', 'npl_mAh'}))
    f = {'nsei_mAh', 'ndl_mAh', 'npl_mAh'}; sc = 1;
elseif all(isfield(ag, {'Q_sei', 'Q_dead', 'Q_plated'}))
    f = {'Q_sei', 'Q_dead', 'Q_plated'}; sc = 1/3.6;      % C -> mAh
else
    error(['aging_from_plant: DFN co aux.aging nhung khong co truong theo quy uoc ' ...
        '(nsei_mAh, ndl_mAh, npl_mAh). Sua anh xa trong src/nmpc/aging_from_plant.m.']);
end
g = @(k) sc*cellfun(@(q) q.aging.(f{k}), a);
nat.nsei = g(1); nat.ndl = g(2); nat.npl = g(3);
nat.source = 'plant';
end
