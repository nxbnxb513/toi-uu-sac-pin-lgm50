function ix = state_index(p)
%STATE_INDEX  Vi tri cac bien trong vector trang thai.
%   x = [cn (Nr); cp (Nr); ce (Nn+Ns+Np); T; Lsei (Nn); cLi (Nn); cdl (Nn); Qsei]
Ne = p.Nn + p.Ns + p.Np;
k = 0;
ix.cn   = k + (1:p.Nr);  k = k + p.Nr;
ix.cp   = k + (1:p.Nr);  k = k + p.Nr;
ix.ce   = k + (1:Ne);    k = k + Ne;
ix.T    = k + 1;         k = k + 1;
ix.Lsei = k + (1:p.Nn);  k = k + p.Nn;
ix.cLi  = k + (1:p.Nn);  k = k + p.Nn;
ix.cdl  = k + (1:p.Nn);  k = k + p.Nn;
ix.Qsei = k + 1;         k = k + 1;
ix.n    = k;

% Thang do dien hinh cua tung bien (dung cho sai so tuyet doi va EKF).
s = ones(k, 1);
s(ix.cn)   = p.n.cmax;
s(ix.cp)   = p.p.cmax;
s(ix.ce)   = p.ce0;
s(ix.T)    = 300;
s(ix.Lsei) = p.sei.L0;
s(ix.cLi)  = 10;
s(ix.cdl)  = 1;
s(ix.Qsei) = 1;
ix.scale = s;
end
