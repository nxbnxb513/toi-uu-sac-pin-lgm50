function [Im, Vm, Tm] = ekf_sensor(c, I, V, T, seed)
%EKF_SENSOR  Tin hieu DO tu tin hieu that cua pin "that" (DFN): nhieu trang
% Gauss + lech khong cua dong (neu co) + luong tu hoa (lam tron theo buoc).
% So lieu: ekf_config.m (lab: GD-70 tu data/ket_qua_du_lieu.md; bms: GD-71 gia dinh).
rng(seed, 'twister');
s = c.sens;
Im = quant(I + s.bI + s.sI*randn(size(I)), s.qI);
Vm = quant(V + s.sV*randn(size(V)), s.qV);
Tm = quant(T + s.sT*randn(size(T)), s.qT);
end

function v = quant(v, q)
if q > 0, v = q*round(v/q); end
end
