function y = dfn_aging_sync_xav(par, y)
%DFN_AGING_SYNC_XAV  Dat x_av (trung binh the tich cua stoich trong hat) bang dung
% sum(theta Vsh)/sum(Vsh) tu cac vo hat trong y. Goi sau moi lan sua theta ngoai bo giai.
if ~(isfield(par, 'aging') && par.aging.on), return; end
g = par.grid; ix = par.ix;
thn = reshape(y(ix.thn), g.Nrn, g.Nn); thp = reshape(y(ix.thp), g.Nrp, g.Np);
y(ix.ag.xavn) = (g.Vshn.'*thn).'/sum(g.Vshn);
y(ix.ag.xavp) = (g.Vshp.'*thp).'/sum(g.Vshp);
end
