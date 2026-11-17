function V = v_limit(par)
%V_LIMIT  Gioi han dien ap sac DUNG CHUNG cho CCCV (diem chuyen CC->CV, ap giu CV)
% va rang buoc V cua NMPC: par.V_cv (dfn_params.m, tham so chung) khi da co;
% truoc do dung par.Vmax = 4.2 V. Khong viet cung 4.2 V o noi khac trong src/nmpc.
if isfield(par, 'V_cv') && ~isempty(par.V_cv), V = par.V_cv; else, V = par.Vmax; end
end
