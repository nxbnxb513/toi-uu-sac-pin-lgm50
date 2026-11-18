function [y, r] = ag_rpt(par, y, expt, first)
%AG_RPT  Mot RPT mo phong (T_amb = 25 C), Li 2025 SI Note 1 (SI tr. 31-32): chi mo phong
% (i) 0.1C xa-sac, (ii) 0.5C xa-sac LAP HAI LAN (giu dien luong thong qua), (iii) GITT
% 0.5C 25 xung x 200 mAh, nghi 1 h sau moi xung (theo bai bao). Cac thoi gian nghi va
% buoc nap lai theo code (Fun_NC.py Initialize_exp_text; bai khong ghi) - GD-59.
%   pre : Expt 2 (dang o 70-85 %): sac CCCV 0.3C, nghi 1 h; Expt 3 (vua sac day): nghi 1 h.
%         RPT0 (first = true, ngay sau break-in da sac day + nghi): khong co pre.
%   0.1C xa toi 2.5 V  -> SOH, LLI, LAM lay o CUOI buoc nay (theo code Get_SOH_LLI_LAM)
%   nghi 3 h; sac CCCV 0.1C, nghi 1 h
%   [xa 0.5C toi 2.5 V; nghi 3 h; sac CCCV 0.5C] x 2; nghi 3 h
%   GITT: 25 x [xa 0.5C 200 mAh (288 s) hoac toi 2.5 V; nghi 1 h]
%         R_0.1s = (V1 - V2)/(I2 - I1) cua xung 12 (Li 2025 SI (S1): V1 cuoi nghi truoc
%         xung, V2 tai 0.1 s sau khi dat xung) - theo bai bao
%   nap lai: CCCV 0.3C; nghi 1 h (Expt 2) / 4 h (Expt 3) (Kirkaldy 2024: chuan bi Expt 3
%         nghi 4 h); Expt 2: xa 1C 730 mAh, nghi 3 h (Kirkaldy 2024).
%   Expt 1 (0-30 %): pre nhu Expt 2; sau RPT: CCCV, nghi 1 h, xa 1C toi 2.5 V, CV 2.5 V toi C/100,
%         nghi 4 h. Expt 5 (0-100 %): nhu Expt 3 (Kirkaldy 2024 Table 2, 6; GD-94).
% CCCV: CC toi V_cv = par.V_cv (GD-43), CV toi C/100.
T25 = 298.15; Q = par.Qnom;
r = struct();
if ~first
    % Expt 1 (vua xa toi 2.5 V) nhu Expt 2; Expt 5 (vua sac day) nhu Expt 3 (GD-94)
    if expt == 2 || expt == 1, st = ag_cccv(par, 0.3*Q, T25, 3600); else, st = ag_step('I', 0, 3600, T25); end
    y = run(y, st);
end
% (i) 0.1C
y0 = y;
y = run(y, ag_step('I', 0.1*Q, 15*3600, T25, struct('Vmin', par.Vmin)));
r.Qdis01 = y(par.ix.Q) - y0(par.ix.Q);
r.inv = dfn_li_inventory(par, y);
r.ydis = y;
y = run(y, [ag_step('I', 0, 3*3600, T25), ag_cccv(par, 0.1*Q, T25, 3600)]);
% (ii) 0.5C x 2
for k = 1:2
    y = run(y, [ag_step('I', 0.5*Q, 5*3600, T25, struct('Vmin', par.Vmin)), ag_step('I', 0, 3*3600, T25), ...
        ag_cccv(par, 0.5*Q, T25, 0)]);
end
y = run(y, ag_step('I', 0, 3*3600, T25));
% (iii) GITT 25 xung
Ip = 0.5*Q; tp = 0.200/Ip*3600;
r.R = NaN(25,1); r.Vrest = NaN(25,1);
for k = 1:25
    V1 = vterm(y);
    [y, o, ok] = ag_exec(par, y, [ag_step('I', Ip, tp, T25, struct('Vmin', par.Vmin), [0.1 tp]), ...
                                  ag_step('I', 0, 3600, T25)]);
    if ~ok, error('ag_rpt: GITT xung %d that bai', k); end
    i1 = find(o.step == 1 & abs(o.t - 0.1) < 1e-9, 1);
    if ~isempty(i1), r.R(k) = (V1 - o.V(i1))/Ip; end
    r.Vrest(k) = V1;
end
r.R12 = r.R(12);
% nap lai + chuan bi
if expt == 2 || expt == 1, trest = 3600; else, trest = 4*3600; end
y = run(y, ag_cccv(par, 0.3*Q, T25, trest));
if expt == 2
    y = run(y, [ag_step('I', Q, 0.730/Q*3600, T25, struct('Vmin', par.Vmin)), ag_step('I', 0, 3*3600, T25)]);
elseif expt == 1
    % Kirkaldy 2024 Table 2: xa 1C toi 2.5 V -> CV 2.5 V toi C/100 -> nghi 4 h (GD-94)
    y = run(y, [ag_step('I', Q, 2*3600, T25, struct('Vmin', par.Vmin)), ...
                ag_step('V', par.Vmin, 30*3600, T25, struct('Icut', Q/100)), ag_step('I', 0, 4*3600, T25)]);
end

    function yy = run(yy, st)
        [yy, oo, okk] = ag_exec(par, yy, st);
        if ~okk, error('ag_rpt: buoc that bai (%s)', strjoin(cellfun(@char, oo.reason, 'UniformOutput', false), '/')); end
    end
    function V = vterm(yy)
        ctl = struct('mode', 'I', 'value', 0, 'Tamb', T25);
        [yc, okc] = dfn_consistent_init(0, yy, par, ctl);
        if ~okc, yc = yy; end
        [~, a] = dfn_rhs(0, yc, par, ctl);
        V = a.V;
    end
end
