# Dữ liệu mở dùng trong đồ án (LG M50 / M50T 21700)

Thư mục này **không chứa dữ liệu thô**. Nó chứa:

- `scripts/` — script Python tải lại dữ liệu từ Zenodo và sinh lại toàn bộ kết quả (xác định, không cần tài khoản, không gửi thông tin người dùng; chỉ dùng `urllib` với User-Agent chung `open-data-fetch-script/1.0`).
- `derived/` — các CSV/JSON nhỏ (< 1 MB mỗi file) do script sinh ra; MATLAB đọc trực tiếp các file này.
- `ket_qua_du_lieu.md` — các bảng số trích ra (sinh tự động bởi `scripts/make_report.py`).
- `raw_cache/` — nơi script lưu file tải về (đã `.gitignore`, không đưa lên repo).

Nguyên tắc: mọi con số đều **tính từ dữ liệu thô bằng script trong repo** hoặc lấy từ bảng số của tác giả; không đọc số từ hình vẽ; mọi giả định và chỗ không lấy được đều ghi rõ.

## Chạy lại

```bash
python -m pip install -r data/scripts/requirements.txt     # numpy, pandas, scipy, openpyxl
python data/scripts/run_all.py                              # tải (khoảng 70 MB) + sinh data/derived/*
python data/scripts/make_report.py                          # sinh data/ket_qua_du_lieu.md
# tuỳ chọn: --cache <thư mục> để đặt nơi lưu file tải về (mặc định data/raw_cache/)
```

Đã kiểm tra với Python 3.12, numpy 2.5.5, pandas 3.1.1, scipy 1.18.1, openpyxl 3.1.5. Mỗi file tải nguyên vẹn được kiểm MD5 với checksum do Zenodo API công bố (`common.zenodo_file`). Hai kho lớn (835 MB và ~49 GB) **không tải toàn bộ**: script đọc mục lục ZIP qua HTTP Range và chỉ trích các file CSV tóm tắt cần dùng (`common.fetch_members`). File tải về chỉ được **đọc như dữ liệu** (CSV/XLSX/ZIP), không thực thi mã nào trong đó.

| Script | Việc làm |
|---|---|
| `scripts/common.py` | tải file Zenodo + kiểm MD5; đọc ZIP từ xa bằng HTTP Range |
| `scripts/a_tec_noise_thermal.py` | bộ A: cấu trúc file, nhiễu cảm biến, hằng số thời gian nhiệt τ, chênh lệch cặp nhiệt |
| `scripts/b_oregan_tidy_entropy.py` | bộ B: CSV gọn + kiểm tra hàm khớp/đơn vị của Li 2025 SI (S5), (S6), (S19), (S21)–(S27) |
| `scripts/c_li2025_ageing.py` | bộ C: thực nghiệm theo cell/RPT, source data các hình (thực nghiệm + 3 mô hình), bộ tham số đầu vào |
| `scripts/d_kirkaldy_summary.py` | bộ D: file tóm tắt của Kirkaldy 2024 cho 5 thí nghiệm, bảng tổng hợp theo cửa sổ SOC × nhiệt độ |
| `scripts/make_report.py` | sinh `ket_qua_du_lieu.md` từ `derived/` |
| `scripts/run_all.py` | chạy a → b → c → d |

---

## A. TEC-reduced-model (Brosa Planella, Sheikh, Widanage 2021)

- **DOI:** 10.5281/zenodo.4864437 (bản v1.0 của GitHub `brosaplanella/TEC-reduced-model`).
- **Giấy phép:** BSD 3-Clause (file `LICENSE` trong kho: "Copyright (c) 2020, Ferran Brosa Planella"); Zenodo ghi "other-open".
- **Trích dẫn bắt buộc (theo README của kho):** F. Brosa Planella, M. Sheikh, W. D. Widanage, "Systematic derivation and validation of a reduced thermal-electrochemical model for lithium-ion batteries using asymptotic methods", *Electrochimica Acta* 388 (2021) 138524, https://doi.org/10.1016/j.electacta.2021.138524.
- **Đã tải:** `brosaplanella/TEC-reduced-model-v1.0.zip` (23 155 564 byte, toàn bộ).
- **File dùng trong ZIP:** `brosaplanella-TEC-reduced-model-978f8c3/data/{0,10,25}degC/Cell<781…796>_<0p1|0p5|1|2>C_<T>degC.csv` (48 file); ý nghĩa cột theo `tec_reduced_model/process_experimental_data.py` (chỉ đọc, không chạy).
- **Nội dung:** cell LG M50; với mỗi nhiệt độ buồng 0/10/25 °C: cell 781–784 xả C/10, 785–788 xả C/2, 789–792 xả 1C, 793–796 xả 2C. Mỗi file: nghỉ 2 h → sạc CC-CV 4,2 V → nghỉ 2 h → xả CC tới 2,5 V → nghỉ 2 h, lặp 2 lần.
- **Cột gốc và đơn vị:** `Step`, `Status`, `Step Time` [s], `Prog Time` [s], `Cycle`, `Cycle Level`, `Procedure`, `Voltage` [V], `Current` [A], `AhAccu` [Ah], `AhPrev` [Ah], `WhAccu` [Wh], `Watt` [W], `LogTempPositive`/`LogTempMid`/`LogTempNegative`/`LogTemp001`/`LogTemp002` [°C].
- **File sinh ra:**
  - `derived/A_files.csv` — mỗi file thô một dòng: `file, cell, C_rate, T_nominal_degC, measurement_id, program, start_time, n_rows, temperature_channels, units_row, step_sequence, n_discharges, dt_discharge_median_s, dt_rest_median_s, I_discharge_mean_A, discharge_duration_s, rest_after_discharge_s`.
  - `derived/A_noise.csv` — `file, cell, C_rate, T_nominal_degC, channel, unit, quantisation_step, n_rest_windows, rest_std_raw_median, rest_std_d2_median, rest_all_values_identical, cc_discharge_std_d2, note`.
  - `derived/A_thermal_tau.csv` — `file, cell, C_rate, T_nominal_degC, discharge_no, channel, skip_s, T_before_discharge_degC, T_end_discharge_degC, T_max_degC, n_points, dt_s, dT0_K, T_inf_fit_degC, A_fit_K, tau_s, rmse_K, reliable, T_amb_channel_mean_degC`.
  - `derived/A_tc_spread.csv` — chênh lệch độ tăng nhiệt giữa `T_mid`, `T_pos`, `T_neg` trong lúc xả.
  - `derived/A_summary.json` — trung vị/khoảng dùng trong báo cáo.
- **Cách tính:**
  - *Nhiễu:* trên 30 phút cuối của mỗi pha nghỉ 2 h (`Status = PAU`); `rest_std_raw` = độ lệch chuẩn mẫu; `rest_std_d2` = std(sai phân bậc hai)/√6 (không bị trôi tuyến tính làm tăng); `quantisation_step` = hiệu nhỏ nhất giữa các giá trị khác nhau trong file. Dòng điện khi nghỉ được bộ ghi báo đúng 0 nên nhiễu dòng lấy trên pha xả CC (`cc_discharge_std_d2`, bỏ 2 mẫu đầu/cuối).
  - *τ:* khớp `T = T_inf + A·exp(−t/τ)` trên pha nghỉ sau xả, bỏ `skip_s` ∈ {60, 120, 300, 600} s đầu; `reliable` khi `dT0_K ≥ 2`. T_inf là tham số khớp.
  - *Chênh lệch cặp nhiệt:* độ tăng nhiệt so với trung bình 10 mẫu cuối pha nghỉ trước khi xả.
- **Giới hạn:** chỉ nhận dạng được τ = m·C_p/(h·A); không tách được h và m·C_p (không biết công suất sinh nhiệt). Cặp nhiệt chỉ ở bề mặt.

## B. O'Regan 2021 Data Repository

- **DOI:** 10.5281/zenodo.5171874. **Giấy phép:** CC BY 4.0.
- **Trích dẫn:** K. O'Regan, F. Brosa-Planella, W. D. Widanage, E. Kendrick, "Data Repository - Thermal-electrochemical parametrisation of a lithium-ion battery: mapping Li concentration and temperature dependencies", Zenodo (2021), v1.0, https://doi.org/10.5281/zenodo.5171874; bài báo đi kèm: K. O'Regan, F. Brosa Planella, W. D. Widanage, E. Kendrick, *Electrochimica Acta* 425 (2022) 140700.
- **Đã tải:** `ORegan 2021 Data Repository.zip` (479 705 byte, toàn bộ).
- **File trong ZIP (gốc `ORegan 2021 Data Repository/`):**
  - `Entropic Term/Entropic_Term_{Negative,Positive}_Electrode_Cell_{001,002}.csv` — cột `Stoichiometry / x`, `Entropic Term / mV K-1` (12 điểm mỗi file).
  - `Specific Heat Capacity/Specific_Heat_Capacity_{Negative_Electrode,Positive_Electrode,Separator}.csv` — `Temperature / °C`, `Specific Heat Capacity / J kg-1 K-1` (4500 điểm, 25–100 °C; **độ lớn thực tế là J g⁻¹ K⁻¹**, xem kết quả).
  - `Thermal Conductivity/Thermal_Conductivity_{Negative,Positive}_Electrode.csv` — `Temperature / K`, `Thermal Conductivity / W m-1 K-1` (5 điểm, 268,15–328,15 K).
  - `Electronic Conductivity/Electronic_Conductivity_Positive_Electrode.csv` — `Temperature / K`, `Electronic Conductivity / S m-1` (5 điểm, 288–308 K).
  - `Exchange Current/Exchange_Current_{Negative,Positive}_Electrode_{15,25,35,45}deg.csv` — `Stoichiometry`, `Exchange Current Density / mA cm-2` (10 điểm mỗi file).
  - `Solid-state Diffusivity/Diffusivity_{Negative,Positive}_Electrode_Cell{001,002}_{5,15,25,35,45}_degC_{lit,delit}.csv` — `Capacity (mAh cm^-2)`, `Stoichiometry`, `Diffusion coefficient (m^2 s^-1)`, `R^2`, `Temperature (K)` (40 file).
- **File sinh ra:** `derived/B_entropic.csv` (`electrode, cell, stoichiometry, dUdT_meas_mV_per_K, Li2025_fit_value_as_printed, residual_if_fit_in_mV_per_K, residual_if_fit_in_V_per_K, source_file`), `derived/B_thermal_electronic.csv`, `derived/B_specific_heat.csv` (mỗi 10 dòng thô lấy 1), `derived/B_exchange_current.csv`, `derived/B_diffusivity.csv` (đủ 40 file, làm tròn 5 chữ số có nghĩa), `derived/B_checks.json`.
- **Cách tính:** các hàm (S5), (S6), (S19), (S21)–(S27) được chép **đúng như in** trong Li 2025 SI (theo `tai_lieu/tham_so/Li2025_tham_so.md`) rồi tính tại các điểm đo; RMSE được tính dưới hai giả thiết đơn vị (hàm cho mV/K hoặc V/K). Với điện cực âm còn tính RMSE khi bỏ 0,45 < x < 0,60. Khớp lại độc lập cùng dạng hàm bằng `scipy.optimize.curve_fit` (khởi tạo từ hệ số in).

## C. Li et al. 2025 — source data, mã và dữ liệu đầu vào

- **DOI:** 10.5281/zenodo.14995785. **Giấy phép:** CC BY 4.0.
- **Trích dẫn:** R. Li, "Code, input data, long simulation results and saved figures for paper: The importance of degradation mode analysis in parameterizing lifetime prediction models of lithium-ion battery degradation", Zenodo (2025), https://doi.org/10.5281/zenodo.14995785; bài báo: R. Li, N. D. Kirkaldy, F. F. Oehler, M. Marinescu, G. J. Offer, S. E. J. O'Kane, *Nature Communications* 16 (2025) 2776, https://doi.org/10.1038/s41467-025-57968-3.
- **Kho gồm 3 file:** `Source_Data.zip` (10,8 MB), `Scripts_to_reproduce_paper.zip` (2,6 MB), `Experiment Data, long simulation data and saved figures in the paper.zip` (835 MB, 3993 mục — danh sách đầy đủ ở `derived/C_archive_listing.tsv`).
- **Đã tải:**
  - `Source_Data.zip` toàn bộ: `Source_Data/Fig.{2…6}.xlsx`, `Source_Data/Supplementary Figure {1…7,9…16}.xlsx`.
  - Từ ZIP 835 MB, chỉ trích (HTTP Range) các file nhỏ:
    - `SimSave/InputData/Expt <N> - <tên>/Expt <N> - cell <X> (<T>degC) - Extracted Data.csv` (40 cell; N = 1; 2,2; 3; 4; 5),
    - `SimSave/InputData/Expt <N> - <tên>/DMA Output/cell <X>/Expt <N> - {DM data, Capacity and offset data, fitting parameters, RMSE data} from OCV-fitting for cell <X>.csv`,
    - `SimSave/InputData/{Full,SEI,SEI_Dry}_Exp{23_Paper_11_fine,1235_NC}/*.csv` (bộ tham số đầu vào của các lượt mô phỏng),
    - `SimSave/Li2024_Results/Save_LongRun/<lượt>/Summary of *.xlsx` (bảng sai số từng lượt).
  - `Scripts_to_reproduce_paper.zip` chỉ được **đọc như văn bản** để đối chiếu (ví dụ ánh xạ cell–nhiệt độ `Temp_Cell_Exp_*` trong `Reproduce_Li2024/Fun_NC.py`); không tải trong pipeline và không chạy.
- **Ánh xạ thí nghiệm → cửa sổ SOC** (theo `experiment_metadata.xlsx` của bộ D): Expt 1: 0–30 %; Expt 2,2: 70–85 %; Expt 3: 85–100 %; Expt 4: 0–100 % (xả theo drive cycle); Expt 5: 0–100 %. Sạc 0,3C / xả 1C; nhiệt độ buồng 10/25/40 °C.
- **File sinh ra:**
  - `derived/C_experiment_per_cell_rpt.csv` — mỗi (cell, RPT) một dòng: `expt, soc_window_pct, T_nominal_degC, cell, rpt, ageing_set, ageing_cycles, days, T_ageing_avg_degC, charge_throughput_Ah, energy_throughput_Wh, cap_C10_mAh, cap_C2_mAh, R_0p1s_Ohm, R_mean_Ohm, R_80to48SOC_Ohm, R_100SOC_Ohm, SOH_dma, LAM_PE, LAM_NE_tot, LAM_NE_Gr, LAM_NE_Si, LLI, cell_cap_dma_mAh, PE_cap_mAh, NE_tot_cap_mAh, NE_Gr_cap_mAh, NE_Si_cap_mAh, offset_mAh, ocv_fit_rmse_V, SOH_C10, source_file`. SOH, LAM, LLI là **phân số** (0–1), không phải %.
  - `derived/C_experiment_summary.csv` — tổng hợp theo (expt, nhiệt độ).
  - `derived/C_fig_ageing_long.csv` — source data Fig. 3, 4, 6 và Supplementary Figure 7 ở dạng dài: `figure, panel, expt, soc_window_pct, T_panel_degC, series, quantity, charge_throughput_kAh, value, matched_cell, matched_cell_T_nominal_degC, matched_expt, source_header`; `series` ∈ {`exp_sample1`, `exp_sample2`, `exp_cell_<X>`, `exp_avg`, `model_SEI_only`, `model_SEI_dry_out`, `model_5_coupled`}; `quantity` ∈ {`SOH_pct`, `R_0p1s_mOhm`, `LLI_pct`, `LAM_NE_tot_pct`, `LAM_PE_pct`, `R_midSOC_model_mOhm`}.
  - `derived/C_fig_small_tables_long.csv` — các bảng nhỏ của Supplementary Figure 2, 3, 5, 6, 13, 15 (`figure, panel, column, row, value`).
  - `derived/C_model_input_cases.csv` — 27 bộ tham số `Full_Exp23_Paper_11_fine` (tên cột giữ nguyên của tác giả, kiểu PyBaMM) + các cột `Error … %`.
  - `derived/C_li_dUdT_curves.csv` — đường ∂U/∂T trong Supplementary Figure 10 c, d (mỗi 10 điểm lấy 1) + giá trị (S5)/(S6).
  - `derived/C_checks.json` — kết quả so khớp panel ↔ cell, kiểm tra đơn vị ∂U/∂T, danh sách bất nhất.
- **Cách tính:** `SOH_C10` = `cap_C10_mAh`/`cap_C10_mAh`(RPT0) theo từng cell. Thí nghiệm/cell của mỗi chuỗi thực nghiệm trong source data được xác định bằng cách so khớp đồng thời (thông lượng, giá trị) với file theo cell (dung sai 2·10⁻³ kAh và 0,2 %), yêu cầu ≥ 80 % số điểm trùng. `T_panel_degC` của Fig. 3/4/6 gán theo thứ tự cột 10/25/40 °C — thứ tự này được **xác nhận bằng so khớp** cho Fig. 3/4 và là **giả định** cho Fig. 6 (ở đó chuỗi thực nghiệm không khớp nhiệt độ; xem `ket_qua_du_lieu.md`).
- **Không tải:** đường cong điện áp C/10 theo RPT (`InputData/Expt */0.1C Voltage Curves/`, ~2,3 GB), kết quả mô phỏng chi tiết (`Save_LongRun/**/Mats/*`), hình PNG; `Supplementary Figure 14.xlsx` (GITT, 9,5 MB) có trong `Source_Data.zip` nhưng không chuyển sang CSV.

## D. Kirkaldy et al. 2024 — dữ liệu lão hoá chu kỳ (≈ 49 GB)

- **DOI:** 10.5281/zenodo.10637534. **Giấy phép:** CC BY 4.0.
- **Trích dẫn:** N. Kirkaldy, M. A. Samieian, G. Offer, M. Marinescu, Y. Patel, "Data from: Lithium-ion battery degradation: comprehensive cycle ageing data and analysis for commercial 21700 cells", Zenodo (2024), v1, https://doi.org/10.5281/zenodo.10637534; bài báo: N. Kirkaldy, M. A. Samieian, G. J. Offer, M. Marinescu, Y. Patel, *Journal of Power Sources* 603 (2024) 234185, https://doi.org/10.1016/j.jpowsour.2024.234185.
- **Kho gồm 7 file:** `experiment_metadata.xlsx` (22 kB), `Battery_Degradation_Data_example_notebook.ipynb` (16 kB) và 5 ZIP: `Expt 1 - Si-based Degradation.zip` (9,1 GB), `Expt 2,2 - C-based Degradation 2.zip` (6,5 GB), `Expt 3 - Cathode Degradation and Li-Plating.zip` (12,0 GB), `Expt 4 - Drive Cycle Aging (Control).zip` (11,4 GB), `Expt 5 - Standard Cycle Aging (Control).zip` (10,4 GB).
- **Cấu trúc mỗi ZIP** (số file/dung lượng từng thư mục: `derived/D_archive_dirs.csv`): `Raw Data/{Degradation Cycling, Performance Checks}/` (hàng chục GB), `Processed Timeseries Data/{0.1C, 0.5C, GITT, Hybrid CC-Pulse} Voltage Curves/`, `Summary Data/Ageing Sets Summary/{Summary per Cycle, Summary per Set}/`, `Summary Data/Performance Summary/`.
- **Đã tải (HTTP Range, tổng ~0,35 MB):** `experiment_metadata.xlsx`; trong mỗi ZIP:
  - `<Expt>/Summary Data/Performance Summary/Expt <N> - cell <X> (<T>degC) - Processed Data.csv` — cột gốc: `Ageing Sets, Ageing Cycles, Age set start date, Age set end date, RPT start date, Days of degradation, Age set av. temperature [°C], Charge Throughput [A h], Energy Throughput [W h], C/10 Capacity [mA h], C/2 Capacity [mA h], 0.1s Resistance [Ohms], Cell Capacity [mA h], PE Capacity [mA h], NE Capacity [mA h], NE_Gr Capacity [mA h], NE_Si Capacity [mA h], Electrode Offset [mA h], SoH, LAM PE, LAM NE_tot, LAM NE_Gr, LAM NE_Si, LLI, PE_lo, NE_lo, PE_hi, NE_hi, Gr_frac, RMSE of OCV-fitting [V]`;
  - `<Expt>/Summary Data/Ageing Sets Summary/Summary per Set/expt <N> - cell <X> - set_data.csv` — `Age Set, Charge Throughput [A h], Energy Throughput [W h], Start Dates, End Dates, Av./Max./Min. Temperature [°C], Av./Max./Min. Voltage [V], Av. Voltage Range [V], Cumulative Charge/Energy Throughput`.
- **File sinh ra:**
  - `derived/D_kirkaldy_per_cell_rpt.csv` — mỗi (cell, RPT) một dòng, 40 cell, 5 thí nghiệm; cột như bộ C cộng `PE_lo, NE_lo, PE_hi, NE_hi, Gr_frac` (giới hạn stoichiometry khớp OCV của tác giả). SOH, LAM, LLI là phân số.
  - `derived/D_kirkaldy_ageing_sets.csv` — mỗi (cell, đợt lão hoá): `T_avg_degC, T_max_degC, T_min_degC, V_avg, V_max, V_min, V_range_avg, charge_throughput_set_Ah, charge_throughput_cum_Ah, …`.
  - `derived/D_kirkaldy_summary.csv` — theo (cửa sổ SOC, nhiệt độ): SOH/LLI/LAM_NE/LAM_PE/R tại thông lượng chung và tại 3 kAh, 6 kAh; tốc độ theo kAh; nhiệt độ cell trung bình/cực đại khi lão hoá.
  - `derived/D_kirkaldy_cells.csv` — bảng cell (Expt, SoC range, Cell, Temp, Rig, Channel, Age sets…).
  - `derived/D_checks.json` — số byte đã trích, đối chiếu với bản sao trong kho Li 2025.
- **Cách tính:** như bộ C (`SOH_C10`, nội suy tuyến tính từng cell tới thông lượng chung rồi lấy trung bình/min/max giữa các cell). LLI/LAM là kết quả DMA (khớp OCV) **của tác giả**, không tính lại.
- **Nếu cần tự tính lại DMA hoặc đường cong OCV theo tuổi:** tập nhỏ nhất là `Processed Timeseries Data/0.1C Voltage Curves/` của ZIP tương ứng (Expt 1: 0,54 GB; Expt 2,2: 0,20 GB; Expt 3: 0,27 GB; Expt 4: 0,17 GB; Expt 5: 0,59 GB — theo `D_archive_dirs.csv`), lấy được bằng `common.fetch_members` mà không tải cả ZIP. Chưa thực hiện.
