function V = v_limit(par)
%V_LIMIT  Gioi han dien ap sac DUNG CHUNG cho CCCV (diem chuyen CC->CV, ap giu CV)
% va rang buoc V cua NMPC: par.V_cv (dfn_params.m) = 4.2 (1 - 0.02) = 4.116 V (GD-43,
% nguoi dung quyet dinh 17/11/2026, sai so mo hinh 2 %). par.Vmax = 4.2 V chi la gioi han
% danh dinh cua cell (ghi chep); chi dung khi par khong co V_cv. Khong viet cung 4.2 V o noi khac trong src/nmpc.
if isfield(par, 'V_cv') && ~isempty(par.V_cv), V = par.V_cv; else, V = par.Vmax; end
end
