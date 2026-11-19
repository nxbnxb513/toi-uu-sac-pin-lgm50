function p = grid_pool(nw)
%GRID_POOL  Pool tien trinh MATLAB cho luoi day du (GD-98). Giay phep MATLAB cua repo cong
% khai chi cho phep tien trinh do matlab-actions/run-command khoi dong va cac worker cua
% Parallel Computing Toolbox; 'matlab -batch' goi rieng bi tu choi. Runner co 4 vCPU (2 nhan
% x 2 luong), profile 'Processes' mac dinh 2 worker => dat lai NumWorkers = nw.
p = gcp('nocreate');
if ~isempty(p) && p.NumWorkers == nw, return; end
if ~isempty(p), delete(p); end
c = parcluster('Processes'); c.NumWorkers = nw;
p = parpool(c, nw);
end
