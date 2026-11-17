function cfg = default_cfg(user)
%DEFAULT_CFG  Cau hinh mo phong. Truong nao co trong 'user' se ghi de mac dinh.
%
% Cac gia tri duoi day la GIA DINH cua de tai (khong co nguon truc tiep),
% tru khi ghi chu khac.

cfg.Tamb   = 298.15;   % K, nhiet do moi truong va nhiet do ban dau (25 C)
cfg.Cbase  = [0.3 1.0];% C-rate cua baseline CCCV. 0.3C la giao thuc sac cua
                       % O'Kane 2022 va Kirkaldy 2024; 1C la muc sac nhanh GIA DINH.
cfg.Cmax   = 2.0;      % C-rate sac toi da cho phep (GIA DINH)
cfg.Tmax   = 318.15;   % K, nhiet do toi da 45 C (GIA DINH)
cfg.margin = 0.010;    % V, bien an toan cho qua the ma Li (GIA DINH)
cfg.Nseg   = 4;        % so doan dong khong doi trong profile toi uu
cfg.maxEval= 40;       % so lan mo phong toi da cho moi bai toan toi uu
cfg.step   = 10;       % % SOC, buoc luoi cua cac vung sac
cfg.t_rest = 1800;     % s, nghi sau khi sac (de Li da ma boc lai hoac chet)

% Tham so so hoc
cfg.tau    = 1.0;      % s, hang so thoi gian bam dong dat
cfg.Kcv    = 20;       % A/(V s), he so bo giu dien ap (pha CV)
cfg.Icut   = 5.0/50;   % A, dong cat cua pha CV (C/50)
cfg.tmax   = 20*3600;  % s, gioi han thoi gian mo phong
cfg.outdir = 'results';

if nargin > 0 && isstruct(user)
    f = fieldnames(user);
    for i = 1:numel(f), cfg.(f{i}) = user.(f{i}); end
end
end
