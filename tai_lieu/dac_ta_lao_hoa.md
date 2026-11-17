# Đặc tả cài đặt mô hình lão hoá "5 coupled" (Li et al. 2025) cho LG M50T — theo đúng mã nguồn của tác giả

> Mục đích: tài liệu này là đặc tả để cài lại trong MATLAB **đầy đủ** mô hình lão hoá "5 coupled" của
> Li, Kirkaldy, Oehler, Marinescu, Offer, O'Kane, *Nat. Commun.* 16:2776 (2025), kế thừa O'Kane et al. 2022 (PCCP 24:7909).
> Mọi phương trình ở đây được viết **theo đúng cái mã của tác giả thực sự tính**, không phải theo bản in (bản in có lỗi/thiếu).
> QUY TẮC CỨNG: không cơ chế nào được bỏ hay đơn giản hoá. Chỗ nào mã khác bài báo đều được ghi rõ ở mục 12.
> Văn xuôi tiếng Việt, tên ký hiệu/biến tiếng Anh.

## 0. Nguồn và cách ghi nhãn

| Nhãn | Nguồn | Ghi chú |
|---|---|---|
| **[P]** | Bài chính Li 2025 (`tai_lieu/Li2025_NatCommun.pdf`), "tr. N" = trang PDF | qua `tham_so/Li2025_tham_so.md` + `toan_van_trich_xuat/Li2025.txt` |
| **[SI]** | Supplementary Information Li 2025, "SI tr. N" | qua ghi chú + `Li2025_SI.txt` |
| **[Z]** | Zenodo 10.5281/zenodo.14995785, `Scripts_to_reproduce_paper.zip` → `Reproduce_Li2024/Fun_NC.py`, `Get_Input_files.ipynb`, `Run_long_Full_Exp1235.py`, `Reload_Exp2.ipynb`, `Reload_Exp3.ipynb` | CC BY 4.0. Đã tải, CHỈ ĐỌC, không chạy |
| **[ZD]** | Zenodo 14995785, file zip 835 MB "Experiment Data, long simulation data…": chỉ lấy (bằng HTTP range) các file nhỏ: `SimSave/InputData/*/…csv` (file đầu vào thật của các lần chạy), log `.o`, `…Ageing_summary_only.mat`, `…xlsx` tóm tắt | số liệu, không phải hình |
| **[SD]** | Zenodo 14995785, `Source_Data.zip` (`Fig.3.xlsx`, `Fig.4.xlsx`, `Fig.6.xlsx`) | bảng số nằm dưới các hình của bài |
| **[PB]** | Fork PyBaMM của tác giả: `github.com/RuiheLi/PyBaMM`, nhánh **`GEM-2_NC`**, commit `dd80d4f792` (30/08/2024), `pybamm/version.py` = **`23.4.1`** | BSD-3. Đường dẫn file ghi tương đối so với `pybamm/` |
| **GIẢ ĐỊNH** | không có trong bài lẫn mã | phải gắn cờ trong báo cáo |

**Cách xác định phiên bản PyBaMM.** `readme.md` của [Z] không ghi phiên bản và không có `requirements`. Bằng chứng dùng để xác định:
(i) script dùng bộ tham số `"Para_Set": "OKane2023"` và các tham số không có ở PyBaMM gốc (`"Negative electrode diffusivity activation energy [J.mol-1]"`, `"Initial electrolyte excessive amount ratio"`, …);
(ii) đường dẫn trong script là `~/EnvPBGEM_NC/…` và thư mục `Reproduce_Li2024` được chèn cạnh thư mục `pybamm`;
(iii) nhánh `GEM-2_NC` của fork chứa đúng thư mục `Reproduce_Li2024/` với cùng tên file, và `input/parameters/lithium_ion/OKane2023.py`;
(iv) `Fun_NC.py` trong fork và trong Zenodo chỉ khác nhau ở cách ghép đường dẫn đọc file CSV thí nghiệm (48 dòng diff, không đụng tới mô hình).
Kết luận: mô hình = **PyBaMM 23.4.1 đã sửa (nhánh GEM-2_NC)** + lớp bọc dry-out trong `Fun_NC.py`. Đây là suy luận từ bằng chứng trên, không phải lời khẳng định của tác giả.

Các chỗ fork sửa so với PyBaMM 23.4.1 gốc (tìm bằng chú thích "Mark Ruihe"/"Mark Simon" trong mã): `a_typ` thay cho `a` trong đổi độ dày ↔ nồng độ SEI và trong porosity; trừ SEI ban đầu khỏi porosity; số hạng "spreading" của SEI trên vết nứt; `L_inner_crack_0 = L_inner_0`; offset 0.2 A/m² của OCP hysteresis; chia 3600 trong luật Paris; biến "dead lithium" riêng; E_act cho D_s và k_cr là tham số.

---

## 1. Ba mô hình và tuỳ chọn mô hình (đúng như file đầu vào)

Nguồn: [Z] `Get_Input_files.ipynb` (cell 9, 11, 14) và [ZD] `InputData/Full_Exp23_Paper_11_fine/*.csv`, `InputData/Full_Exp1235_NC/*.csv` (cột "Model option").

| Tuỳ chọn PyBaMM | SEI only | SEI + Dry out | **5 coupled** |
|---|---|---|---|
| `SEI` | interstitial-diffusion limited | interstitial-diffusion limited | interstitial-diffusion limited |
| `SEI on cracks` | **true** | **true** | true |
| `lithium plating` | none | none | partially reversible |
| `lithium plating porosity change` | false | false | true |
| `particle mechanics` | constant cracks (cả hai cực) | constant cracks | **("swelling and cracking", "swelling only")** = (âm, dương) |
| `loss of active material` | none | none | stress-driven (cả hai cực) |
| `SEI porosity change` | true | true | true |
| `SEI film resistance` | distributed | distributed | distributed |
| `open-circuit potential` | current sigmoid | current sigmoid | current sigmoid |
| `contact resistance` | true | true | true |
| `thermal` | lumped | lumped | lumped |
| `stress-induced diffusion` (mặc định ngầm, xem 2.3) | **true** | **true** | **true** |
| "Initial electrolyte excessive amount ratio" (lớp bọc dry-out) | 0.99 → dry-out TẮT | 1.0 → dry-out BẬT | 1.0 → dry-out BẬT |

Hệ quả phải nhớ:
- Cả ba mô hình đều có **SEI trên vết nứt**; ở hai mô hình đầu vết nứt không lớn (`l_cr = l_cr,0` hằng) nên diện tích SEI hiệu dụng = `S0·a_n` với `S0 = 2.908` (mục 5).
- Trong "5 coupled": **vết nứt chỉ lan ở cực âm**; cực dương là "swelling only" (`l_cr,p ≡ 0`, không nứt, không SEI). LAM do ứng suất bật ở cả hai cực.
- Dry-out bật/tắt bằng tỉ số điện giải dư: `< 1` → tắt; `≥ 1` → bật ([Z] `Run_P2_Excel`, đoạn "merge DryOut and Int_ElelyExces_Ratio").

---

## 2. Khung DFN mà các cơ chế lão hoá gắn vào

Phần lõi DFN do agent khác cài; ở đây chỉ ghi những gì mô hình lão hoá **đòi hỏi** lõi phải có, và những điểm mã làm khác mặc định thông thường.

### 2.1 Quy ước dấu và miền

- Mỗi biến lão hoá được định nghĩa **tại từng nút x** của điện cực nêu tên (không lấy trung bình theo x): tuỳ chọn `x-average side reactions` = false (mặc định), `reaction_loc = "full electrode"` ([PB] `models/full_battery_models/lithium_ion/base_lithium_ion_model.py::set_sei_submodel`, `dfn.py`: `x_average = False`).
- `j` [A/m²] = mật độ dòng giao diện trên một đơn vị diện tích bề mặt hạt, **dương khi dòng đi từ pha rắn sang điện giải** (oxy hoá / delithiation). SEI và mạ lithium là phản ứng khử ⇒ `j_SEI < 0`, `j_SEI,cr < 0`; biến mạ của PyBaMM là "dòng stripping" `j_pl`: `j_pl < 0` khi đang mạ, `> 0` khi đang hoà tan lại.
- `δφ = φ_s − φ_e` [V] tại nút x của cực âm ("Negative electrode surface potential difference").
- `i_app = I / A_cc`, `A_cc = L_y · L_z`; `I > 0` khi xả. C-rate tính theo **5 A** ("Nominal cell capacity [A.h]" = 5) ([PB] `OKane2023.py`).
- `T` là một nhiệt độ duy nhất của cả cell (mô hình nhiệt lumped) dùng cho mọi nút.

### 2.2 Cân bằng dòng giao diện (chỗ ghép chính)

Tại mỗi nút x của **cực âm** ([PB] `models/submodels/interface/total_interfacial_current.py`, `base_interface.py::_get_standard_volumetric_current_density_variables`):

```
a_n          = 3·eps_s_n / R_n                                   [1/m]   (eps_s_n là biến trạng thái, mục 7)
S            = 1 + 2·l_cr·w_cr·rho_cr                            [-]     ("roughness ratio", mục 6)
a_n·j_tot_n  = a_n·j_int_n + a_n·j_SEI + a_n·j_pl + a_n·(S − 1)·j_SEIcr      [A/m³]
d(i_e)/dx    = a_n·j_tot_n ;   d(i_s)/dx = −a_n·j_tot_n
```

Tại cực dương: `a_p·j_tot_p = a_p·j_int_p` (không có phản ứng phụ), `a_p = 3·eps_s_p/R_p`.

- **Chỉ `j_int` đi vào hạt**: điều kiện biên khuếch tán pha rắn `−D_eff·∂c_s/∂r |_(r=R) = j_int / F` (không phải `j_tot`). Phần `j_SEI`, `j_SEIcr`, `j_pl` lấy Li⁺ từ điện giải và electron từ pha rắn ⇒ LLI tự sinh ra (mục 9), không cần phương trình riêng.
- **Nguồn của điện giải**: `∂(eps·c_e)/∂t = −∂N_e/∂x + a·j_tot/F`, với `N_e = −eps^1.5·D_e·∂c_e/∂x + t_plus·i_e/F` ([PB] `electrolyte_diffusion/full_diffusion.py`). Biến trạng thái là **`eps·c_e`** (dạng bảo toàn) — bắt buộc, vì `eps_n` thay đổi theo thời gian và lớp bọc dry-out nhân trực tiếp vào `eps·c_e`.
- **Quá thế màng SEI** ("distributed", [PB] `interface/kinetics/base_kinetics.py`): `j_tot_n` là **biến đại số** tại mỗi nút x của cực âm, thoả `j_tot_n − (tổng dòng thể tích)/a_n = 0`;
  `eta_SEI = −rho_SEI · L_SEI · j_tot_n` [V], với `L_SEI = L_inner + L_outer` (chỉ SEI trên bề mặt gốc, KHÔNG gồm SEI trên vết nứt).
- **Butler–Volmer chính** (đối xứng, α = 0.5, n_e = 1): `j_int = 2·j0·sinh( F·eta / (2·R·T) )`,
  cực âm: `eta_n = δφ − U_n(c_surf) + eta_SEI = φ_s − φ_e − U_n − rho_SEI·L_SEI·j_tot_n`; cực dương: `eta_p = φ_s − φ_e − U_p`.
- **Điện áp đầu cực**: `V = φ_s(x=L) − φ_s(x=0) − I·R_contact` ([PB] `electrode/base_electrode.py`), `R_contact = 0.0115 Ω`.

### 2.3 Những điểm của lõi DFN mà mã làm khác "DFN sách giáo khoa" (bắt buộc theo để tham số lão hoá còn nhất quán)

1. **Khuếch tán do ứng suất trong hạt được BẬT** ở cả hai cực trong cả ba mô hình. Lý do: PyBaMM đặt mặc định `stress-induced diffusion = "true"` hễ `particle mechanics ≠ "none"` ([PB] `models/full_battery_models/base_battery_model.py`, dòng 324–336), và file đầu vào không ghi đè. Khi đó ([PB] `models/submodels/particle/base_particle.py::_get_effective_diffusivity`, Ai 2019 eq. 12):
   ```
   theta_M = Omega/(R·T) · 2·Omega·E / (9·(1 − nu))            [m³/mol]
   D_eff(c, T) = D_s(c/c_max, T) · ( 1 + theta_M·(c − c_ref) ),   c_ref = 0
   ```
   với `c` là nồng độ **cục bộ** tại bán kính r. Giá trị (tự tính từ tham số của mã, 298.15 K): cực âm `theta_M = 1.846e-5` ⇒ hệ số nhân 1.02 … 1.53; **cực dương `theta_M = 6.566e-3` ⇒ hệ số nhân ≈ 85 … 322** (do `E_p = 375 GPa`). Bài báo KHÔNG nhắc tới số hạng này (mục 12, mâu thuẫn C1).
2. `D_s` phụ thuộc stoichiometry và nhiệt độ (O'Regan 2022), Arrhenius với `E_act` là tham số: `D_s = D_ref(sto)·exp( E_Ds/R·(1/298.15 − 1/T) )` ([PB] `OKane2023.py::graphite_LGM50_diffusivity_ORegan2022`, `nmc_LGM50_diffusivity_ORegan2022`). Hệ số: [SI] Table 7 (đã chép ở `Li2025_tham_so.md` mục 5.5), đã đối chiếu trùng với mã.
3. **OCP hysteresis "current sigmoid"** ([PB] `interface/open_circuit_potential/current_sigmoid_ocp.py`): với `J = i_app` [A/m²], `m = (1 + tanh(100·x))/2`:
   cực dương `U_p = m(J + 0.2)·U_p,lith + (1 − m(J + 0.2))·U_p,delith`; cực âm `U_n = m(−(J + 0.2))·U_n,lith + (1 − m(−(J + 0.2)))·U_n,delith`.
   Tức khi xả và khi nghỉ: dương dùng nhánh lithiation, âm dùng nhánh delithiation; khi sạc (J < −0.2) ngược lại. Bốn hàm OCP: [SI] Note 8 (S1)–(S4), trùng với mã (`*_ocp_OKane2023`). Stoichiometry bị kẹp trong `[tol, 1 − tol]`.
4. Điện giải EC:EMC 3:7 Landesfeind–Gasteiger, bản "_Constant" ([PB] `OKane2023.py`), `c = c_e/1000` nếu `c_e < 4000`, `= 4` nếu `c_e > 4000` (đúng bằng 4000 thì mã cho 0 — lỗi vô hại):
   ```
   D_e   = 1.01e3·exp(1.01·c)·exp(−1.56e3/T)·exp(−4.87e2·c/T)·1e-10                                   [m²/s]
   kappa = 0.1·0.521·(1 + (T − 228))·c·(1 − 1.06·sqrt(c) + 0.353·(1 − 3.59e-3·exp(1000/T))·c) / (1 + c⁴·1.48e-3·exp(1000/T))   [S/m]
   t_plus= −12.8 − 6.12·c + 8.21e-2·T + 0.904·c² + 3.18e-2·c·T − 1.27e-4·T² + 1.75e-2·c³ − 3.12e-3·c²·T − 3.96e-5·c·T²
   chi   = 25.7 − 45.1·c − 0.177·T + 1.94·c² + 0.295·c·T + 3.08e-4·T² + 0.259·c³ − 9.46e-3·c²·T − 4.54e-4·c·T²
   ```
   Lưu ý hai hệ số **khác bản in của [SI]**: 0.353 (bản in 0.8353) và −6.12 (bản in −0.612) — mục 12, C6.
5. `j0` ([PB] `OKane2023.py`): `j0_n = 2.668·exp(4e4/R·(1/298.15 − 1/T))·(c_e/1000)^0.208·(c_surf/c_max)^0.792·(1 − c_surf/c_max)^0.208`; `j0_p = 5.028·exp(2.401e4/R·(1/298.15 − 1/T))·(c_e/1000)^0.57·(c_surf/c_max)^0.43·(1 − c_surf/c_max)^0.57`. `c_e` chia cho hằng 1000 mol/m³ ("Typical electrolyte concentration"), không phải trung bình ⟨c_e⟩.
6. Bruggeman: điện giải 1.5 cả ba miền; pha rắn 0 ở hai điện cực ⇒ `sigma_eff = sigma_s` (không nhân `eps_s`).
7. Entropy: mã chia 1000 (fit theo mV/K): `dU_p/dT = (0.04006·exp(−(x−0.2828)²/0.0009855) − 0.06656·exp(−(x−0.8032)²/0.02179))/1000`; `dU_n/dT = (−0.1112·x + 0.02914 + 0.3561·exp(−(x−0.08309)²/0.004616))/1000` [V/K] (hệ số cực âm lệch nhẹ so với [SI] (S6): −0.111, 0.02901, 0.3562, 0.08308, 0.004621).
8. Lưới của các lần chạy trong bài: `[x_n, x_s, x_p, r_n, r_p] = [10, 10, 10, 100, 20]` cho Expt 2 (số liệu Fig. 2–5, Table 1–2) và `[10, 5, 5, 100, 20]` cho Expt 3 (Fig. 6); lưới hạt đều (không có "Exponential mesh stretch") ([ZD] cột "Mesh list"). Thể tích hữu hạn, `CasadiSolver` mặc định.

### 2.4 Mô hình nhiệt lumped ([PB] `thermal/lumped.py`, `thermal/base_thermal.py`, `parameters/thermal_parameters.py`)

```
rho_cp_eff·dT/dt = Q_vol_av − h·A_cool/V_cell·(T − T_amb)
Q = Q_ohm + Q_rxn + Q_rev                                         [W/m³], tại từng x
Q_ohm = −i_s·dφ_s/dx − i_e·dφ_e/dx   (cộng i_app²/sigma_cc trong hai current collector)
Q_rxn = a·j_int·eta ;  Q_rev = a·j_int·T·dU/dT      (chỉ phản ứng chính; SEI/plating không sinh nhiệt)
Q_vol_av = ( ∫Q dx + Q_cn·L_cn + Q_cp·L_cp ) / (L_cn + L_n + L_s + L_p + L_cp)
rho_cp_eff = Σ_k rho_k·cp_k(T)·L_k / Σ_k L_k      (k = cn, n, s, p, cp)
```
`h = 20 W/m²/K`, `A_cool = 5.31e-3 m²`, `V_cell = 2.42e-5 m³`; nhiệt do `R_contact` KHÔNG được tính. `T_amb` = nhiệt độ lão hoá (10/25/40 °C) trong ageing set, = 25 °C trong break-in và RPT; `T(0) = 298.15 K`; trạng thái T được nối tiếp giữa các đoạn.
`cp_k(T)`: [SI] (S20)–(S23); trong mã `rho_dry` của cực âm = 1740 và của separator = 946 kg/m³ (bảng [SI] Table 6 in ngược hai số này), `rho_e = 1280`, `cp_e = 229`.

---

## 3. Cơ chế 1 — SEI hai lớp, giới hạn bởi khuếch tán interstitial

Nguồn: [PB] `models/submodels/interface/sei/sei_growth.py` (nhánh `"interstitial-diffusion limited"`), `sei/base_sei.py`; [SI] Note 2 (S2)–(S9), SI tr. 33–34.

**Biến trạng thái** (tại mỗi nút x của cực âm): `L_inner(x,t)`, `L_outer(x,t)` [m].

```
Arr_SEI = exp( E_SEI/R · (1/T_ref − 1/T) ),   T_ref = 298.15 K
j_SEI   = − ( D_int · c_int · F / L_outer ) · exp( − F·δφ / (R·T) ) · Arr_SEI          [A/m²]   (< 0)
j_inner = alpha · j_SEI ;   j_outer = (1 − alpha) · j_SEI ,   alpha = 0.5
dL_inner/dt = − Vbar_inner · j_inner / (z_SEI · F)
dL_outer/dt = − Vbar_outer · j_outer / (z_SEI · F)
L_SEI = L_inner + L_outer
```

Chi tiết phải theo đúng:
- Số mũ là **`−F·δφ/(R·T)`** (có F/RT). `δφ = φ_s − φ_e` **không trừ** `eta_SEI` và không trừ thế cân bằng nào (`U_SEI` có trong `eta_SEI` của mã nhưng nhánh interstitial không dùng).
- Mẫu số là **`L_outer`** (không phải `L_inner` như [SI] in). Vì `alpha = 0.5`, `Vbar_inner = Vbar_outer` và điều kiện đầu bằng nhau nên `L_inner ≡ L_outer ≡ L_SEI/2` mọi lúc, hai cách viết cho cùng kết quả số; nhưng cài thì dùng `L_outer`.
- Gộp lại: `dL_inner/dt = dL_outer/dt = c_int·D_int·Vbar_SEI / (4·L_outer) · exp(−F·δφ/(R·T)) · Arr_SEI` (với `z_SEI = 2`, `alpha = 0.5`). [SI] (S6) in hệ số `1/(2·L)`; mã cho `1/(4·L_outer)` (mục 12, C3).
- `T` trong `Arr_SEI` và trong số mũ là nhiệt độ cell (lumped).
- `D_int` và `c_int` chỉ xuất hiện dưới dạng tích.

**Ghép vào DFN:** `a_n·j_SEI` cộng vào `a_n·j_tot_n` (mục 2.2); `L_SEI` vào `eta_SEI`; `L_SEI` vào porosity (mục 8); `L_SEI` vào tốc độ "chết" của lithium mạ (mục 4).

**Sổ sách LLI do SEI** (biến chẩn đoán, [PB] `base_sei.py::_get_standard_concentration_variables`): dùng **`a_typ = 3·eps_s_n,0/R_n = 3.8396e5 1/m` (hằng)**, không dùng `a_n` hiện thời:
```
n_SEI(x)  = (L_inner/Vbar_inner + L_outer/Vbar_outer)·a_typ                        [mol SEI / m³ điện cực]
Q_SEI     = z_SEI·( xavg(n_SEI) − (L_inner,0/Vbar_inner + L_outer,0/Vbar_outer)·a_typ )·L_n·L_y·L_z     [mol Li]
```
(`L_y` là bề rộng hiện thời, sau dry-out.) Đại lượng này chỉ dùng cho dry-out (mục 10) và báo cáo phân rã LLI; nó KHÔNG bằng đúng tích phân `−a_n·j_SEI/F` khi `eps_s_n` đã giảm do LAM (mục 12, C8).

**Điều kiện đầu:** `L_inner(x,0) = L_outer(x,0) = L_SEI,0^layer` tính theo mục 11.2 (với "5 coupled": **9.2326e-9 m** mỗi lớp).

---

## 4. Cơ chế 2 — Mạ lithium bán thuận nghịch + lithium chết

Nguồn: [PB] `interface/lithium_plating/plating.py`, `base_plating.py`, `parameters/lithium_ion_parameters.py` (dòng 112–113), `OKane2023.py` (`plating_exchange_current_density_OKane2020`, `stripping_exchange_current_density_OKane2020`, `SEI_limited_dead_lithium_OKane2022`); [SI] Note 3 (S10)–(S13), SI tr. 35.

**Biến trạng thái** (tại mỗi nút x của cực âm): `c_Li(x,t)` — lithium mạ còn thuận nghịch; `c_dl(x,t)` — lithium chết; đơn vị [mol/m³ **thể tích điện cực**].

```
eta_pl   = δφ + eta_SEI = φ_s − φ_e − rho_SEI·L_SEI·j_tot_n                         [V]   (thế cân bằng Li/Li⁺ = 0 V)
alpha_pl = 0.65  ("Lithium plating transfer coefficient");   alpha_st = 1 − alpha_pl = 0.35
j_pl     = F·k_Li·[ c_Li·exp( alpha_st·F·eta_pl/(R·T) ) − c_e·exp( − alpha_pl·F·eta_pl/(R·T) ) ]      [A/m²]
gamma    = gamma_0 · (L_inner,0 + L_outer,0) / L_SEI                                [1/s]
dc_Li/dt = − a_n·j_pl / F − gamma·c_Li
dc_dl/dt = + gamma·c_Li
```

- `c_e` là nồng độ điện giải cục bộ tại nút x; `a_n = 3·eps_s_n/R_n` hiện thời (nhân với `j_pl`, không nhân với roughness — mạ chỉ trên bề mặt gốc).
- Không có Arrhenius cho `k_Li` và `gamma_0`.
- `L_inner,0 + L_outer,0` trong `gamma` là tổng độ dày đầu **đã ghi đè** theo mục 11.2.
- Nhãn "α_a,Li = 0.65" ở [SI] Table 8 là nhãn sai: 0.65 là hệ số của nhánh **mạ (cathodic)**, nhánh hoà tan (anodic) là 0.35 — đúng như O'Kane 2022 (α_a = 0.35, α_c = 0.65).

**Ghép vào DFN:** `a_n·j_pl` cộng vào `a_n·j_tot_n`; `c_Li`, `c_dl` vào porosity (mục 8) qua "độ dày" `L_pl = c_Li·Vbar_Li/a_typ`, `L_dl = c_dl·Vbar_Li/a_typ`.

**Sổ sách:** `Q_pl = xavg(c_Li + c_dl)·L_n·L_y·L_z` [mol Li] ("Loss of lithium to lithium plating"); `Q_dl = xavg(c_dl)·L_n·L_y·L_z`.

**Điều kiện đầu:** `c_Li = 0`, `c_dl = 0`.

---

## 5. Cơ chế 3a — Ứng suất trong hạt (cả hai cực)

Nguồn: [PB] `particle_mechanics/base_mechanics.py::_get_mechanical_results` (Ai 2019 eq. 7–10); [SI] Note 4 (S14)–(S17).

Mã KHÔNG dùng phân bố ứng suất theo r in ở (S14)–(S17); chỉ dùng giá trị **tại bề mặt hạt**, tại mỗi nút x:

```
c_rav(x)      = (3/R³)·∫_0^R c_s(r,x)·r² dr                  (trung bình thể tích của hạt)
sigma_r_surf  = 0
sigma_t_surf  = Omega·E / (3·(1 − nu)) · ( c_rav − c_surf )                         [Pa]
sigma_h_surf  = ( sigma_r_surf + 2·sigma_t_surf ) / 3 = (2/3)·sigma_t_surf           [Pa]
```

- Dấu: `sigma_t_surf > 0` (kéo) khi `c_rav > c_surf`, tức khi hạt đang **nhả lithium**: cực âm khi XẢ, cực dương khi SẠC.
- `c_ref` không ảnh hưởng tới ứng suất (chỉ vào chuyển vị và `theta_M`).
- Hệ số: cực âm `Omega·E/(3(1−nu)) = 2.2143e4 Pa/(mol/m³)`; cực dương `1.9531e6 Pa/(mol/m³)` (tự tính từ tham số).
- Mã còn tính độ dày cell thay đổi (hàm `t_change`) — chỉ là đầu ra, không hồi tiếp; không cần cho lão hoá.

---

## 6. Cơ chế 3b — Vết nứt (luật Paris) và SEI trên vết nứt

Nguồn: [PB] `particle_mechanics/crack_propagation.py`, `base_mechanics.py::_get_standard_surface_variables`, `sei/sei_growth.py` (cracks=True), `sei/base_sei.py`; [SI] Note 4 (S18)–(S20), SI tr. 36–37.

### 6.1 Vết nứt — chỉ cực âm

**Biến trạng thái** (mỗi nút x của cực âm): `l_cr(x,t)` [m].

```
K          = sigma_t_surf · b_cr · sqrt( pi·l_cr )        nếu sigma_t_surf ≥ 0 ;   K = 0 nếu sigma_t_surf < 0     [Pa·m^0.5]
dl_cr/dt   = k_cr · K^m_cr / t_0 ,     t_0 = 3600 s (viết cứng trong mã: "/ 3600 # divide by 3600 to replace t0_cr")
S          = 1 + 2·l_cr·w_cr·rho_cr                       ("roughness ratio"; w_cr hằng)
a_cr       = (S − 1)·a_n                                   [1/m]   (đại số, KHÔNG có ODE riêng cho a_cr)
```

- `k_cr`: đơn vị `m / (Pa·m^0.5)^m_cr` cho mỗi `t_0` (chú thích trong `OKane2023.py::graphite_cracking_rate_Ai2020`). Trong các lần chạy của bài, `"Negative electrode cracking rate"` bị ghi đè bằng **hằng số 5.29e-25** (không còn hàm Arrhenius; `"Negative cracking growth activation energy"` = 0 nên dù sao cũng không phụ thuộc T).
- Cực dương: `l_cr,p ≡ 0`, `S_p ≡ 1` ("swelling only"). Các tham số nứt của cực dương ở [SI] Table 9 không được dùng.
- Sự kiện dừng: `max(l_cr) ≥ R_n`.
- **Điều kiện đầu:** `l_cr(x,0) = l_cr,0 = 2e-8 m` ⇒ `S0 = 1 + 2·2e-8·1.5e-8·3.18e15 = 2.908`.

### 6.2 SEI trên vết nứt — cực âm

**Biến trạng thái** (mỗi nút x của cực âm): `L_inner_cr(x,t)`, `L_outer_cr(x,t)` [m] (độ dày SEI trên bề mặt vết nứt).

```
j_SEIcr      = − ( D_int·c_int·F / L_outer_cr )·exp( − F·δφ/(R·T) )·Arr_SEI          [A/m² diện tích vết nứt]
dL_inner_cr/dt = − Vbar_inner·alpha·j_SEIcr/(z_SEI·F)        − (dl_cr/dt)/l_cr · L_inner_cr
dL_outer_cr/dt = − Vbar_outer·(1 − alpha)·j_SEIcr/(z_SEI·F)  − (dl_cr/dt)/l_cr · L_outer_cr
```

- Số hạng thứ hai ("spreading") dàn SEI cũ ra diện tích nứt mới; bằng 0 khi vết nứt không lan (hai mô hình đầu).
- Dòng thể tích ghép vào DFN: **`a_n·(S − 1)·j_SEIcr`** [A/m³].
- Sổ sách: `n_SEIcr(x) = (L_inner_cr/Vbar_inner + L_outer_cr/Vbar_outer)·a_typ·(S − 1)`;
  `Q_SEIcr = z_SEI·( xavg(n_SEIcr) − (L_inner_cr,0/Vbar_inner + L_outer_cr,0/Vbar_outer)·a_typ·(S0 − 1) )·L_n·L_y·L_z` [mol Li].
- **Điều kiện đầu:** `L_inner_cr,0 = L_inner,0`, `L_outer_cr,0 = L_outer,0` ([PB] `lithium_ion_parameters.py` dòng 432–433; PyBaMM gốc dùng `L_0/10000`).

---

## 7. Cơ chế 4 — Mất vật liệu hoạt tính do ứng suất (cả hai cực)

Nguồn: [PB] `active_material/loss_active_material.py`, `base_active_material.py`; [SI] Note 5 (S21)–(S22), SI tr. 38.

**Biến trạng thái** (mỗi nút x của **từng** điện cực k = n, p): `eps_s_k(x,t)` [-].

```
sigma_h      = max( (2/3)·sigma_t_surf , 0 )                                  (nén không gây LAM)
d(eps_s_k)/dt = − beta_k · ( sigma_h / sigma_c_k )^m2_k                        [1/s]
a_k(x,t)     = 3·eps_s_k / R_k
```

- `beta` có đơn vị **1/s và dùng trực tiếp** (không chia `t_0`); "ứng suất thuỷ tĩnh nhỏ nhất" trong mã bị đặt bằng 0.
- **LAM → `eps_s` và `a`:** `eps_s_k` giảm; nồng độ `c_s` trong các hạt còn lại **không đổi** ⇒ lithium nằm trong phần vật liệu bị mất rời khỏi kho lithium (LLI do LAM). `a_k` giảm theo ⇒ cùng một dòng thể tích thì mật độ dòng `j` trên bề mặt hạt còn lại tăng ⇒ gradient nồng độ và ứng suất tăng (hồi tiếp dương). `sigma_eff` không đổi (Bruggeman pha rắn = 0). **Porosity KHÔNG tăng** khi `eps_s` giảm (vật liệu mất được coi là pha trơ, vẫn chiếm chỗ).
- Dung lượng điện cực: `C_k = xavg(eps_s_k)·L_k·A_cc·c_max_k·F/3600` [Ah] (A_cc hiện thời).
- Sổ sách LLI do LAM (ODE chẩn đoán trong mã): `d(LLI_LAM_k)/dt = − c_s_av_k · L_k·A_cc · xavg( d eps_s_k/dt )` [mol/s], `c_s_av_k` = trung bình theo r và x.
- **Điều kiện đầu:** `eps_s_n = 0.75`, `eps_s_p = 0.665`.
- Với giá trị fit: `beta_p = 2.98e-18 1/s` ⇒ LAM cực dương do ứng suất ≈ 0 (đầu ra của mã: `LAM_to_Crack_PE ≈ 2e-14 %` sau 9.5 kAh, [ZD] xlsx tóm tắt). LAM_PE của mô hình hoàn toàn do dry-out (mục 10). Vẫn phải cài số hạng này cho cực dương.

---

## 8. Hồi tiếp porosity (bít lỗ rỗng)

Nguồn: [PB] `porosity/reaction_driven_porosity.py` (đã bị fork sửa); bài báo và O'Kane 2022 không in phương trình này.

Porosity cực âm là **hàm đại số** của các biến trạng thái (không có ODE riêng), tại mỗi nút x:

```
L_pl = c_Li·Vbar_Li / a_typ ;      L_dl = c_dl·Vbar_Li / a_typ                      [m]
L_tot = (L_SEI − L_SEI,0) + L_pl + L_dl + (L_SEIcr − L_SEIcr,0)·(S − 1)             [m]
eps_n(x,t) = eps_n,0 − a_typ · L_tot
```

với `L_SEI = L_inner + L_outer`, `L_SEIcr = L_inner_cr + L_outer_cr`, `L_SEI,0 = L_inner,0 + L_outer,0`, `L_SEIcr,0 = 2·L_inner_cr,0`, **`a_typ = 3·eps_s_n,0/R_n` hằng** (không giảm theo LAM), `S` hiện thời.
Separator và cực dương: porosity hằng (0.47 và 0.335).

- Ghép vào DFN: `eps_n` vào `eps^1.5` của `D_e`, `kappa`; vào `c_e = (eps·c_e)/eps` (porosity giảm ⇒ `c_e` cục bộ tăng, vì trạng thái là `eps·c_e`).
- Sự kiện dừng: `min(eps_n) ≤ 0`.
- Lưu ý: số hạng nứt dùng `(S − 1)` hiện thời nhân với **độ tăng** độ dày, nên khi vết nứt lan mà SEI trên nứt mỏng đi (spreading) thì thể tích vẫn nhất quán gần đúng; đây là đúng như mã, không sửa.

---

## 9. Sổ sách lithium tuần hoàn (LLI) — mã làm gì

Không có phương trình "n_Li" riêng. Lượng lithium tuần hoàn là đại lượng dẫn xuất ([PB] `base_lithium_ion_model.py`):

```
n_Li_particles = Σ_(k=n,p)  L_k·A_cc · xavg( eps_s_k · ravg(c_s_k) )                 [mol]
```

Nó giảm theo bốn đường, tất cả đã nằm trong các phương trình trên:
1. **Phản ứng phụ** (SEI, SEI trên nứt, mạ ròng): vì hạt chỉ nhận `j_int = j_tot − j_SEI − j_pl − (S−1)·j_SEIcr`, khi sạc cực âm nhận ít lithium hơn lượng cực dương nhả ra. Lithium mạ thuận nghịch quay lại hạt khi `j_pl > 0`.
2. **LAM do ứng suất**: `eps_s` giảm ở `c_s` cố định (mục 7).
3. **Dry-out**: `A_cc` giảm ⇒ lithium trong phần điện cực bị "khô" của CẢ HAI cực bị loại (mục 10).
4. Lithium trong điện giải được bảo toàn riêng (`eps·c_e`, mục 10).

Chỉ số báo cáo ([Z] `Get_SOH_LLI_LAM`), lấy tại **cuối bước xả 0.1C** của mỗi RPT:
`LLI% = (1 − n_Li_particles/n_Li_particles[RPT0])·100`; `LAM_k% = (1 − C_k/C_k[RPT0])·100`; `SOH% = Q_dis,0.1C / 4.86491 · 100`;
`LLI do LAM = LLI − LLI_SEI − LLI_SEIcr − LLI_plating`; `LAM do dry-out = (1 − L_y/L_y,0)·100`; `LAM do ứng suất = LAM − LAM do dry-out`.

---

## 10. Cơ chế 5 — Tiêu thụ dung môi / dry-out (lớp bọc ngoài bộ giải)

Nguồn: [Z] `Fun_NC.py::Initialize_mdic_dry`, `Cal_new_con_Update`, `Run_Model_Base_On_Last_Solution(_RPT)`, `Run_P2_Excel`; [SI] Note 6 (S23)–(S43), Table 4, SI tr. 39–43.

Đây KHÔNG phải ODE; là một phép cập nhật rời rạc giữa các **đoạn mô phỏng**. Một đoạn = (break-in + RPT đầu) hoặc (một ageing set trọn vẹn) hoặc (một RPT). Vì `Update cycles for ageing = Ageing cycles between RPT`, phép cập nhật chạy **một lần trước mỗi ageing set và một lần trước mỗi RPT** (không phải mỗi chu kỳ).

**Trạng thái của lớp bọc:** `V_tot` (điện giải toàn cell) [m³], `V_JR` (điện giải trong jelly roll) [m³], `L_y` (bề rộng điện cực hiệu dụng) [m], `c_e_res`, `c_EC_res` (nồng độ Li⁺ và EC trong reservoir), `c_EC_JR`.

**Khởi tạo** (`Initialize_mdic_dry`):
```
V_pore,0 = ( L_n·eps_n,0 + L_s·eps_sep + L_p·eps_p )·L_y,0·L_z
V_JR  = V_pore,0 ;    V_tot = R_exc · V_pore,0          (R_exc = "Initial electrolyte excessive amount ratio" = 1.0 ⇒ KHÔNG có reservoir)
c_e_res = 1000 ;  c_EC_res = 4541 ;  c_EC_JR = 4541 mol/m³
```
Với "5 coupled": `V_pore,0 = 5.2362 mL` (log của tác giả in đúng "Initial electrolyte amount is 5.236163896909271 mL", [ZD]).

**Cập nhật sau mỗi đoạn** (`Cal_new_con_Update`), dùng nghiệm của đoạn vừa chạy ("đầu" = thời điểm đầu đoạn, "cuối" = cuối đoạn):
```
dLLI      = [Q_SEI(cuối) − Q_SEI(đầu)] + [Q_SEIcr(cuối) − Q_SEIcr(đầu)]                [mol Li]
V_pore_new= ( L_n·xavg(eps_n)(cuối) + L_s·eps_sep + L_p·eps_p )·L_y·L_z               (L_y hiện thời)
dV_pore   = V_JR − V_pore_new                       (dùng V_JR cũ, không dùng thể tích lỗ rỗng đầu đoạn)
V_EC      = dLLI · Vbar_EC                           (1 mol EC cho 1 mol Li; lithium chết/mạ KHÔNG tiêu thụ EC)
V_need    = V_EC − dV_pore
V_tot_new = V_tot − V_EC
```
Phân nhánh:
- **(A) `V_need < 0`** — lỗ rỗng co nhanh hơn lượng EC mất ("squeezed"): `V_squeeze = −V_need`; `V_JR_new = V_pore_new`; `L_y` giữ nguyên; `Ratio_CeLi = 1`; reservoir nhận thêm: `c_e_res_new = (V_res·c_e_res + V_squeeze·xavg(c_e)(cuối)) / (V_res + V_squeeze)`, tương tự cho EC với `c_EC_JR`; `V_res = V_tot − V_JR` (cũ).
- **(B) `V_need ≥ 0`:**
  - (B1) `V_tot > V_JR` và `V_tot − V_JR ≥ V_need`: `V_add = V_need`; `V_JR_new = V_pore_new`; `R_dry = 1`.
  - (B2) `V_tot > V_JR` nhưng reservoir không đủ: `V_add = V_tot − V_JR`; `V_JR_new = V_tot_new`; `R_dry = V_JR_new / V_pore_new`.
  - (B3) `V_tot ≤ V_JR` (hết reservoir): `V_add = 0`; `V_JR_new = V_tot_new`; `R_dry = V_JR_new / V_pore_new`.
  - Sau đó: `n_Li_e` = "Total lithium in electrolyte [mol]" cuối đoạn `= L_x·A_cc·xavg(eps·c_e)`;
    `Ratio_CeLi = (n_Li_e + V_add·c_e_res) / n_Li_e / R_dry` ;
    `Ratio_CeEC = ( V_JR·c_EC_JR − [Q_SEI(cuối) − Q_SEI(đầu)] + V_add·c_EC_res ) / V_JR_new / c_EC_JR` (mã chỉ trừ phần SEI bề mặt, không trừ SEI trên nứt);
    **`L_y_new = R_dry · L_y`** ; `c_e_res`, `c_EC_res` giữ nguyên.

**Áp vào đoạn kế tiếp** (`Run_Model_Base_On_Last_Solution`):
1. Mọi biến trạng thái của mô hình lấy từ trạng thái cuối đoạn trước.
2. **`eps·c_e` tại mọi nút (âm, separator, dương) nhân với `Ratio_CeLi`.**
3. Tham số `"Electrode width [m]"` = `L_y_new` ⇒ `A_cc` giảm ⇒ với cùng dòng I, `i_app = I/A_cc` tăng; dung lượng CẢ HAI điện cực giảm cùng tỉ lệ (**LAM_NE = LAM_PE do dry-out**), lithium trong phần điện cực mất cũng mất theo.
4. `c_EC_JR ← c_EC_JR·Ratio_CeEC` (ghi vào "Bulk solvent concentration"/"EC initial concentration"). **Nồng độ EC không hồi tiếp vào bất kỳ phương trình nào** (SEI interstitial không dùng nồng độ dung môi; tính chất điện giải không phụ thuộc EC) — chỉ để theo dõi.
5. `T_amb` đặt theo loại đoạn.

Ghi chú đúng-như-mã: ở nhánh (A) lithium bị ép ra reservoir được cộng vào reservoir nhưng **không bị trừ** khỏi jelly roll (`Ratio_CeLi = 1`); đây là hành vi của mã, giữ nguyên và gắn cờ (C9). Với `R_exc = 1.0`, lần cập nhật đầu thường rơi vào (A) (log in "Electrolyte is being squeezed out"), các lần sau vào (B2)/(B3).

Số đối chiếu ([ZD] `5_Re_0_Full_Exp1235_NC_Case_5_5.xlsx`, Expt 2, 25 °C, cuối mô phỏng 9.489 kAh): `V_tot = V_JR = 4.7839 mL`, `L_y = 1.49746 m` (từ 1.58 m) ⇒ LAM do dry-out 5.224 %.

---

## 11. Tham số

### 11.1 Ba bộ tham số fit — [P] Table 3 (tr. 8), đối chiếu với file đầu vào [ZD]

| Tham số | Đơn vị | SEI only | SEI + Dry out | **5 coupled** | Giá trị trong CSV đầu vào [ZD] |
|---|---|---|---|---|---|
| `D_int` (Inner SEI lithium interstitial diffusivity) | m²/s | 2.36e-18 | 1.2e-18 | **9.81e-19** | 2.35555e-18 / 1.2e-18 / 9.81e-19 |
| `Vbar_SEI` (inner = outer) | m³/mol | 4e-5 | 6.74e-5 | **5.22e-5** | trùng |
| `E_SEI` (SEI growth activation energy) | J/mol | 1e4 | 1e4 | **5e3** | trùng |
| `gamma_0` (Dead lithium decay constant) | 1/s | – | – | **1e-7** | (hai mô hình đầu ghi 1e-6 nhưng không dùng) |
| `k_Li` (Lithium plating kinetic rate constant) | m/s | – | – | **1e-10** | (1e-9, không dùng) |
| `beta_p` (Positive LAM proportional term) | 1/s | – | – | **2.98e-18** | (3e-7, không dùng) |
| `beta_n` (Negative LAM proportional term) | 1/s | – | – | **2.84e-9** | (3e-7, không dùng) |
| `k_cr_n` (Negative electrode cracking rate) | m/(Pa·m^0.5)^m_cr mỗi t_0 = 3600 s | – | – | **5.29e-25** | (1e-20, không dùng vì constant cracks) |
| `E_Ds_n` (Negative diffusivity activation energy) | J/mol | 6e4 | 6e4 | **2e4** | trùng |
| `R_exc` (electrolyte excess ratio) | – | 0.99 (tắt) | 1.0 | **1.0** | trùng |

Các trường hợp tác giả chọn làm "best fit": Expt 2 — thư mục `Full_Exp23_Paper_11_fine` case 4/13/22 (10/25/40 °C; `E_SEI = 5e3`, `E_Ds_n = 2e4`), `SEI_Exp23_Paper_11_fine` và `SEI_Dry_Exp23_Paper_11_fine` case 9/18/27 (`1e4`, `6e4`) ([Z] `Reload_Exp2.ipynb`); Expt 3 — `Full_Exp1235_NC`, `SEI_Exp1235_NC`, `SEI_Dry_Exp1235_NC` case 7/8/9 ([Z] `Reload_Exp3.ipynb`).

**Bộ phải dùng cho mô hình "5 coupled":** cột **"5 coupled"** nguyên vẹn, và nó chỉ tự nhất quán khi đi cùng TẤT CẢ các thứ sau (không trộn với cột khác, không trộn với DFN Chen 2020):
(a) tuỳ chọn mô hình cột "5 coupled" ở mục 1 (kể cả stress-induced diffusion bật);
(b) `E_Ds_n = 2e4`, `E_Ds_p = 1.2e4 J/mol`;
(c) `L_inner,0 = L_outer,0 = L_inner_cr,0 = L_outer_cr,0 = 9.2326e-9 m` và `eps_n,0 = 0.234965` (mục 11.2);
(d) bộ BOL `OKane2023.py` (O'Regan 2022 + OCP mới hai nhánh + hysteresis sigmoid + điện giải Landesfeind + `c_max`, stoichiometry mới);
(e) `R_contact = 0.0115 Ω`, `h = 20 W/m²/K`, `R_exc = 1.0`;
(f) toàn bộ tham số giữ nguyên ở 11.3.

### 11.2 Độ dày SEI ban đầu và porosity cực âm ban đầu — mã ghi đè cho từng `Vbar_SEI`

Nguồn: [Z] `Fun_NC.py::Overwrite_Initial_L_SEI_0_Neg_Porosity` (gọi ở cuối `Para_init`, sau khi mọi tham số đã cập nhật); [SI] Note 9 (S7)–(S11).

```
dQ        = (5.0 − 4.86491)·3600 C            (mất dung lượng do formation, 0.13509 Ah)
a_typ     = 3·0.75/5.86e-6 = 3.83959e5 1/m ;   S0 = 2.908 ;   A = 1.58·0.065 = 0.1027 m² ;  F = 96485.3
L_SEI_init = dQ·Vbar_SEI / ( z_SEI·F·A·L_n·a_typ·S0 )
eps_n,0   = 0.25 − L_SEI_init·S0·a_typ
L_inner,0 = L_outer,0 = L_SEI_init/2 + 2.5e-9                      (cộng thêm 2.5 nm mỗi lớp — có trong mã, KHÔNG có trong [SI])
```

| Mô hình | `Vbar_SEI` | `L_SEI_init` [m] | `L_inner,0 = L_outer,0` [m] | `eps_n,0` | `V_pore,0` [mL] |
|---|---|---|---|---|---|
| SEI only | 4e-5 | 1.03182e-8 | 7.65911e-9 | 0.238479 | 5.26691 |
| SEI + Dry out | 6.74e-5 | 1.73862e-8 | 1.119311e-8 | 0.230587 | 5.19786 |
| **5 coupled** | 5.22e-5 | 1.34653e-8 | **9.23265e-9** | **0.234965** | 5.23616 |
| (ví dụ của [SI], mặc định của `OKane2023.py`) | 9.585e-5 | 2.47251e-8 | 1.48625e-8 (mặc định file: 1.23625e-8) | 0.222393 | 5.12616 |

Kiểm chứng: log của tác giả in "Initial outer SEI thickness … 9.23e-09 … porosity 0.235" và "5.236163896909271 mL" cho "5 coupled"; "1.12e-08 … 0.231", "5.197856896775573 mL" cho SEI + Dry out ([ZD] `…pbs.o9805112.5`, `…pbs.o9805113.5`). Giá trị 1.23625e-8 m ở [SI] Table 8 là mặc định của file tham số (ứng với `Vbar_SEI = 9.585e-5`, không cộng 2.5 nm), **không phải** giá trị dùng trong ba mô hình.
SEI trên vết nứt ban đầu dùng cùng độ dày. Độ dày đầu thật (kể cả +2.5 nm) cũng là `L_SEI,0` trong `gamma` (mục 4) và trong porosity (mục 8).

### 11.3 Tham số lão hoá giữ nguyên (bộ "5 coupled")

| Ký hiệu | Tên tham số PyBaMM | Giá trị | Đơn vị | Nguồn |
|---|---|---|---|---|
| `z_SEI` | Ratio of lithium moles to SEI moles | 2 | – | [SI] Table 8 (SI tr. 26); [PB] `OKane2023.py` |
| `c_int` | Lithium interstitial reference concentration | 15 | mol/m³ | [SI] Table 8; [PB] |
| `rho_SEI` | SEI resistivity | 2e5 | Ω·m | [SI] Table 8; [PB] |
| `alpha` | Inner SEI reaction proportion | 0.5 | – | [SI] Table 8; [PB] |
| `T_ref` | Reference temperature | 298.15 | K | [PB] |
| `alpha_pl` | Lithium plating transfer coefficient (nhánh mạ) | 0.65 (⇒ `alpha_st` = 0.35) | – | [SI] Table 8 (nhãn sai); [PB] `lithium_ion_parameters.py` dòng 112–113 |
| `c_Li,0` | Initial plated lithium concentration | 0 | mol/m³ | [SI] Table 8; [PB] |
| `Vbar_Li` | Lithium metal partial molar volume | 1.3e-5 | m³/mol | [SI] Table 8; [PB] |
| `Vbar_EC` | EC partial molar volume | 6.667e-5 | m³/mol | [SI] Table 8; [PB] |
| `c_e_res,0`, `c_EC_res,0`, `c_EC_JR,0` | reservoir / jelly roll | 1000, 4541, 4541 | mol/m³ | [SI] Table 8; [Z] `Get_Input_files.ipynb` |
| `m2` (n, p) | LAM constant exponential term | 2, 2 | – | [SI] Table 9 (SI tr. 27); [PB] |
| `sigma_c` (n, p) | critical stress | 60e6, 375e6 | Pa | [SI] Table 9; [PB] |
| `b_cr` (n) | Paris' law constant b | 1.12 | – | [SI] Table 9; [PB] |
| `m_cr` (n) | Paris' law constant m | 2.2 | – | [SI] Table 9; [PB] |
| `rho_cr` (n) | number of cracks per unit area | 3.18e15 | 1/m² | [SI] Table 9; [PB] |
| `l_cr,0` (n) | initial crack length | 2e-8 | m | [SI] Table 9; [PB] |
| `w_cr` (n) | initial crack width (hằng) | 1.5e-8 | m | [SI] Table 9; [PB] |
| `t_0` | chu kỳ quy đổi của luật Paris | 3600 | s | [PB] `crack_propagation.py` (viết cứng) |
| `E_cr` (n) | Negative cracking growth activation energy | 0 (và bị vô hiệu vì `k_cr` là hằng) | J/mol | [ZD] CSV |
| `Omega` (n, p) | partial molar volume | 3.1e-6, 1.25e-5 | m³/mol | [SI] Table 6; [PB] |
| `E` (n, p) | Young's modulus | 15e9, 375e9 | Pa | [SI] Table 6; [PB] |
| `nu` (n, p) | Poisson's ratio | 0.3, 0.2 | – | [SI] Table 6; [PB] |
| `c_ref` (n, p) | reference concentration for free of deformation | 0, 0 | mol/m³ | [SI] Table 6; [PB] |
| `E_Ds_p` | Positive electrode diffusivity activation energy | 1.2e4 | J/mol | [SI] Table 7; [ZD] CSV |
| `R_contact` | Contact resistance | 0.0115 | Ω | [SI] Table 6; [PB] (mặc định file) |
| `h` | Total heat transfer coefficient | 20 | W/m²/K | [SI] Table 6; [PB] (mặc định file) |

Tham số có trong file nhưng **không được dùng** bởi các tuỳ chọn đã chọn (không cần cài): SEI open-circuit potential, SEI kinetic rate constant, EC diffusivity, Outer SEI solvent diffusivity, Inner SEI electron conductivity, reaction-driven LAM factor (= 0), mọi tham số nứt của cực dương, hàm `volume change`.

### 11.4 Tham số BOL liên quan (bộ `OKane2023.py`) — chỉ liệt kê những gì mô hình lão hoá đọc

`L_n = 85.2e-6`, `L_s = 12e-6`, `L_p = 75.6e-6 m`; `L_y,0 = 1.58 m`, `L_z = 0.065 m`; `R_n = 5.86e-6`, `R_p = 5.22e-6 m`; `eps_s_n,0 = 0.75`, `eps_s_p,0 = 0.665`; `eps_sep = 0.47`, `eps_p = 0.335`; `c_max_n = 32544`, `c_max_p = 52787 mol/m³`; `c_s_n(0) = 28543`, `c_s_p(0) = 12727 mol/m³` (100 % SOC); `c_e(0) = 1000 mol/m³`; `sigma_n = 215 S/m`, `sigma_p = 0.8473·exp(3500/R·(1/298.15 − 1/T))`; ngưỡng điện áp trong thí nghiệm 2.5–4.2 V. Nguồn: [SI] Table 6 (SI tr. 23–24) và [PB] `OKane2023.py::get_parameter_values` (đã đối chiếu, trùng).

---

## 12. Giải quyết các mục "KHÔNG RÕ" và các chỗ mã khác bài báo

### 12.1 Các mục của `Li2025_tham_so.md` (mục 9 và mục 10 của file đó)

| # | Vấn đề | Mã thực sự làm gì | Nguồn |
|---|---|---|---|
| 1 | Số mũ SEI không có F/(RT); có trừ `eta_SEI` không | `exp(−F·(φ_s − φ_e)/(R·T))`; KHÔNG trừ `eta_SEI`, không trừ thế cân bằng; mẫu số `L_outer`; cùng dạng cho SEI trên nứt | [PB] `sei_growth.py` |
| 2 | [SI] Table 12 in sai nhãn | Mã không in lại bảng này. Notebook [Z] `Reload_Exp3.ipynb` in MPE/RMSE điện áp theo thứ tự (10, 25, 40 °C) × mô hình, trùng [SI] Table 10–11. Cách đọc "ba khối = 10/25/40 °C, trong khối = SEI only / SEI + Dry out / 5 coupled" vẫn là **suy luận** (khớp với câu "10.58 % ở 40 °C" của [P] tr. 5) | — |
| 3 | `L_SEI,0`, `eps_n,0` thực dùng | Ghi đè theo `Vbar_SEI`, cộng 2.5 nm mỗi lớp — bảng ở 11.2 | [Z] `Overwrite_Initial_L_SEI_0_Neg_Porosity` |
| 4 | `alpha_a,Li = 0.65` | 0.65 là hệ số nhánh mạ; nhánh hoà tan = 0.35 (nhãn bảng sai, giá trị không đổi so với O'Kane 2022) | [PB] `lithium_ion_parameters.py`, `plating.py` |
| 5 | Đơn vị `beta`, `k_cr`, giá trị `t_0` | `beta` [1/s] dùng trực tiếp; `t_0 = 3600 s` chỉ trong luật Paris; `k_cr` [m/(Pa·m^0.5)^m_cr] | [PB] `loss_active_material.py`, `crack_propagation.py`, `OKane2023.py` |
| 6 | `beta_p` nhỏ hơn 9 bậc | Đúng; LAM_PE do ứng suất ≈ 2e-14 %; LAM_PE = dry-out | [ZD] xlsx tóm tắt |
| 7 | "0.3C/1C" là sạc hay xả | Sạc 0.3C, xả 1C | [Z] `Initialize_exp_text` |
| 8, 9, 18 | lỗi trích dẫn/đánh số trong [SI] | Không liên quan tới mã | — |
| 10 | Tiền tố của `D_e` | `1010·…·1e-10` | [PB] `OKane2023.py` |
| 11 | `(1 + (T − 228))` trong `kappa` | Đúng như in: `p1·(1 + (T − p2))`, `p1 = 0.521`, `p2 = 228`. Nhưng hệ số trước ngoặc thứ hai là **0.353** (không phải 0.8353), và trong `t_plus` là **−6.12·c** (không phải −0.612·c) | [PB] `OKane2023.py` |
| 12 | Đơn vị `dU/dT` | Hàm fit theo mV/K rồi chia 1000 ⇒ V/K | [PB] `OKane2023.py` |
| 13 | `E_p = 375 GPa` | Giữ nguyên; hệ quả lớn nhất là hệ số khuếch tán do ứng suất ×85–322 ở cực dương (2.3) | [PB] |
| 14 | Tham số nứt gắn nhãn lẫn lộn | Chỉ cực âm nứt; tham số nứt cực dương không dùng | [ZD] CSV "Model option" |
| 15 | `R_contact`, `h` | 0.0115 Ω, 20 W/m²/K là mặc định trong file tham số của tác giả (chỉnh tay; bài không nêu nguồn) | [PB] `OKane2023.py` |
| 16 | Số RPT của Expt 3 | Mô phỏng: 13 RPT (RPT0 sau break-in + 12), cho cả Expt 2 và 3 | [Z] `Get_tot_cyc`; [ZD] `.mat` |
| 17 | Không dùng tối ưu hoá | Đúng (quét lưới/LHS) | [Z] `Get_Input_files.ipynb` |
| (10.5) | "Initial excessive electrolyte amount = 1.0" | `R_exc = V_tot/V_pore,0`; 1.0 = không có reservoir; `< 1` tắt dry-out | [Z] `Run_P2_Excel`, `Initialize_mdic_dry` |

### 12.2 Các mục của `OKane2022_tham_so.md`

| Vấn đề | Mã thực sự làm gì | Nguồn |
|---|---|---|
| Phương trình porosity | Đại số: `eps_n = eps_n,0 − a_typ·L_tot` (mục 8) | [PB] `reaction_driven_porosity.py` |
| LLI → `n_Li` | Không có phương trình riêng; LLI sinh ra từ cân bằng dòng (mục 2.2, 9) | [PB] |
| LAM → `a` | `a = 3·eps_s/R` với `eps_s` là trạng thái (mục 7) | [PB] `base_active_material.py` |
| Diện tích vết nứt → SEI/LLI | `a_cr = (S − 1)·a`; dòng thể tích `a·(S − 1)·j_SEIcr` (mục 6) | [PB] `base_interface.py` |
| (S13) thiếu ½ | Không dùng (mô hình solvent-diffusion đã bị thay). Trong PyBaMM, dòng SEI tổng được chia theo `alpha` | [PB] `sei_growth.py` |
| (17b), (18) dạng `sigma_t`, hệ số `1/(3r³)` | Mã chỉ dùng giá trị bề mặt `sigma_t_surf = Omega·E/(3(1−nu))·(c_rav − c_surf)` với `c_rav` là trung bình thể tích (3/R³) | [PB] `base_mechanics.py` |
| (20) `da_cr/dt`, vị trí `t_0` | Không có ODE cho `a_cr`; `dl_cr/dt = k_cr·K^m/3600` | [PB] `crack_propagation.py` |
| (22) dấu của LAM | `d eps_s/dt = −beta·(…)^m2` (giảm) | [PB] `loss_active_material.py` |
| `l_cr,0 = 2e-5 m` > bán kính hạt | Trong mã: `l_cr,0 = 2e-8 m`, `w_cr = 1.5e-8 m` | [PB] `OKane2023.py` |
| Đơn vị `k_cr`, `beta` | như #5 ở trên | — |
| Arrhenius cho `k_Li`, `gamma_0`, `k_cr`, `beta` | Không có (riêng `k_cr` có tham số `E_cr` nhưng = 0 và bị ghi đè bằng hằng) | [PB], [ZD] |
| Số điểm lưới | `[10,10,10,100,20]` (Expt 2), `[10,5,5,100,20]` (Expt 3) | [ZD] |
| `E_k±`, điều kiện biên/điện áp đầu cực | Xem 2.3 (5) và 2.2; `E_j0`: 4e4 (âm), 2.401e4 (dương) J/mol | [PB] `OKane2023.py` |

### 12.3 Chỗ mã MÂU THUẪN hoặc bổ sung so với bài báo (phải nêu trong báo cáo)

- **C1.** Khuếch tán do ứng suất trong hạt bật ngầm ở cả hai cực (2.3 mục 1); bài và SI không nhắc. Ảnh hưởng mạnh tới gradient nồng độ ⇒ ứng suất ⇒ LAM và nứt, và tới `D_s` hiệu dụng của cực dương.
- **C2.** SEI trên vết nứt có mặt cả trong "SEI only" và "SEI + Dry out" (vết nứt hằng, diện tích ×2.908); tên mô hình trong bài không thể hiện.
- **C3.** Tốc độ tăng độ dày: mã `c_int·D_int·Vbar/(4·L_outer)·exp(…)`; [SI] (S6)/(S7) in `c_int/(2·L)`; mẫu số trong mã là `L_outer` cho cả hai lớp.
- **C4.** Độ dày SEI ban đầu cộng thêm 2.5 nm mỗi lớp và phụ thuộc `Vbar_SEI`; [SI] Table 8 ghi 1.23625e-8 m "unchanged".
- **C5.** Cực dương không nứt ("swelling only"); [SI] Table 9 vẫn liệt kê tham số nứt cực dương.
- **C6.** Hệ số điện giải: 0.353 và −6.12 trong mã; 0.8353 và −0.612 trong [SI] (S14), (S15).
- **C7.** `a_typ` (hằng, BOL) được dùng trong porosity và sổ sách SEI/mạ, trong khi dòng thể tích dùng `a_n` hiện thời; [SI] (S24)–(S25) viết với `a_n`.
- **C8.** Hệ quả của C7: `Q_SEI` (dùng cho dry-out) không trùng hẳn với tích phân dòng SEI khi đã có LAM.
- **C9.** Dry-out: (i) EC tiêu thụ tính 1 EC/1 Li cho SEI + SEI trên nứt, nhưng `Ratio_CeEC` chỉ trừ phần SEI bề mặt; (ii) nhánh "squeeze" không trừ Li⁺ khỏi jelly roll; (iii) cập nhật mỗi ageing set, không phải mỗi bước thời gian `dt` như [SI] mô tả; (iv) EC không hồi tiếp vào động học.
- **C10.** `k_cr` âm cực là hằng số (không Arrhenius); `t_0 = 3600 s` viết cứng.
- **C11.** Số chu kỳ mỗi ageing set: mã [Z] `Get_tot_cyc` ghi 516 (Expt 2) và 514 (Expt 3); file kết quả [ZD] của lần chạy `Full_Exp1235_NC` ghi 514 cho cả hai; thí nghiệm là 515 (Kirkaldy 2024 Table 1).
- **C12.** `rho_dry` của cực âm/separator trong hàm nhiệt dung (1740/946) ngược với [SI] Table 6 (946/1740); hệ số `dU_n/dT` lệch nhẹ.

### 12.4 Còn phải GIẢ ĐỊNH / chưa xác định được

1. Cách đọc [SI] Table 12 (suy luận).
2. Sai số/bước thời gian của bộ giải (PyBaMM `CasadiSolver` chế độ mặc định) — bản MATLAB dùng bộ giải khác nên chỉ so được ở mức sai số số học; số "0.1 s" của điện trở (mục 13.3).
3. Số chu kỳ chính xác mỗi ageing set của lần chạy cho Fig. 2–5 (514/515/516; C11) — ảnh hưởng < 0.4 % charge throughput.
4. Điều kiện nhiệt của thí nghiệm thật (base-cooling Peltier) được tác giả thay bằng `h = 20`, `A_cool = 5.31e-3` chỉnh tay.
5. Toàn bộ mục 15 (silicon).
6. Bộ tham số không duy nhất (không tối ưu hoá); `k_Li`, `gamma_0` chỉ bị ràng buộc bởi dữ liệu sạc 0.3C ⇒ dùng cho dòng sạc lớn là ngoại suy.
7. Chưa đọc: peer-review file, preprint arXiv:2311.05482, phần còn lại của file zip 835 MB (chỉ lấy file nhỏ).

---

## 13. Giao thức thí nghiệm và giao thức mô phỏng

### 13.1 Thí nghiệm (Kirkaldy 2024, Table 1–6, tr. 2–4; [SI] Table 5, SI tr. 22, 31)

Cell LG M50T; SOC định nghĩa theo 4.865 Ah; 1C = 5 A; 2.5–4.2 V; RPT luôn ở 25 °C; base-cooling.

| | Expt 2 (**70–85 %**) — dùng để fit | Expt 3 (**85–100 %**) — dùng để validate |
|---|---|---|
| Nhiệt độ | 10, 25, 40 °C | 10, 25, 40 °C |
| Số cell | 2 / 2 / 2 (cell A,B / C,D / E,F) | 3 / 3 / 3 (A,B,C / D,E,F / G,H,I) |
| Chuẩn bị | CCCV sạc 0.3C → 4.2 V tới C/100; nghỉ 1 h; xả 1C 730 mAh; nghỉ 3 h | CCCV sạc; nghỉ 4 h |
| Vòng lặp | [xả 1C 730 mAh → sạc CC 0.3C 730 mAh] × 515 (không có CV) | [xả 1C 730 mAh → sạc CC 0.3C tới 4.2 V → CV 4.2 V tới C/100] × 515 |
| RPT dài (sau set chẵn) | 0.1C xả–sạc; 0.5C xả–sạc; GITT 0.5C 25 xung × 200 mAh nghỉ 1 h; GITT 0.5C 5 xung × 1000 mAh; trước mỗi phần: CCCV 0.3C/4.2 V/C/100 + nghỉ 1 h | như bên |
| RPT ngắn (sau set lẻ) | 0.1C xả–sạc; pulse-under-load nền C/2 và 1C | như bên |

### 13.2 Giao thức mà mã mô phỏng ([Z] `Initialize_exp_text`, `Get_tot_cyc`, `Run_P2_Excel`; `V_max = 4.2`, `V_min = 2.5`)

- **Break-in + RPT0** (`T_amb = 25 °C`, bắt đầu từ `c_s` ở 100 % SOC): xả 0.5C tới 4.0 V → sạc 0.3C tới 4.2 V → giữ 4.2 V tới C/100 → nghỉ 1 h → **xả 0.1C tới 2.5 V** → nghỉ 3 h → sạc 0.1C tới 4.2 V → giữ 4.2 V tới C/100 → nghỉ 1 h → [xả 0.5C tới 2.5 V → nghỉ 3 h → sạc 0.5C tới 4.2 V → giữ tới C/100] × 2 → nghỉ 3 h → **GITT**: [nghỉ 5 phút → nghỉ 1.2 s → xả C/2 trong 4.8 phút hoặc tới 2.5 V (lấy mẫu 0.1 s) → nghỉ 1 h] × 24 → nạp lại: sạc 0.3C tới 4.2 V, giữ tới C/100, nghỉ 1 h → bước chỉnh trước lão hoá.
- **Chỉnh trước lão hoá:** Expt 2: xả 1C trong `0.15·60·4.86491/5 = 8.756838` phút (hoặc tới 2.5 V), nghỉ 3 h. Expt 3: nghỉ 1 h.
- **Ageing set** (`T_amb` = 10/25/40 °C):
  Expt 2: [xả 1C trong 8.756838 phút hoặc tới 2.5 V → sạc 0.3C trong `0.5·60·4.86491/5 = 29.18946` phút hoặc tới 4.2 V] × 516 (xem C11).
  Expt 3: [xả 1C trong 8.756838 phút hoặc tới 2.5 V → sạc 0.3C tới 4.2 V → giữ 4.2 V tới C/100] × 514.
  (1C = 5 A ⇒ mỗi nửa chu kỳ 0.729737 Ah = 15 % của 4.86491 Ah.)
- **RPT k** (`T_amb = 25 °C`): Expt 2 (cần nạp đầy trước): sạc 0.3C tới 4.2 V → giữ tới C/100 → nghỉ 1 h → nghỉ 10 s → rồi như RPT0 từ "xả 0.1C" trở đi. Expt 3 (đã đầy): nghỉ 10 s ×2 → nghỉ 1 h → nghỉ 10 s → như trên. Sau đó GITT 24 xung, nạp lại, bước chỉnh.
- Tổng: 12 ageing set, 13 RPT. RPT rút gọn so với thí nghiệm: chỉ 0.1C, 0.5C (lặp hai lần để giữ charge throughput) và GITT 25 xung ([SI] tr. 31).
- Charge throughput = ∫|I| dt cộng dồn qua mọi đoạn (kể cả RPT).
- Thứ tự mỗi vòng: [cập nhật dry-out] → ageing set → [cập nhật dry-out] → RPT.

### 13.3 Cách tính các chỉ số so sánh

- `SOH = Q_dis(0.1C)/4.86491·100` [%] ([Z] `Get_SOH_LLI_LAM`, `cap_0 = 4.86491`).
- `R_0.1s` [mΩ] ([Z] `Get_0p1s_R0`): lấy phần tử chỉ số 12 (đếm từ 0) trong 24 xung GITT, tức xung thứ 13, ≈ 50 % SOC (thí nghiệm: "xung thứ 12, ≈ 52 % SOC"): `(mean(V của 9 mẫu áp chót của bước nghỉ 1.2 s) − V tại mẫu ĐẦU của bước xả C/2) / I · 1000`. Trong mô hình không có điện dung lớp kép nên đây là bước nhảy tức thời, không phải đúng 0.1 s.
- LLI, LAM_NE, LAM_PE: mục 9; thí nghiệm lấy từ OCV-fitting ([SI] Note 12).
- `MPE = mean(|exp − model|/|exp|)·100` trên lưới charge throughput của thí nghiệm (nội suy tuyến tính mô hình), bỏ các điểm `exp = 0`; `MPE_tot = 0.5·MPE_SOH + 0.125·(MPE_LLI + MPE_LAMNE + MPE_LAMPE + MPE_Res)` ([Z] `mean_percentage_error`, `Reload_Exp2.ipynb::Calculate_MPE_re`; [P] eq. 1, tr. 8).

---

## 14. Số liệu để kiểm chứng về sau (chỉ từ bảng/văn bản/mã/dữ liệu số — không đọc từ đường cong)

### 14.1 Sai số mô hình "5 coupled" so với thí nghiệm, do bài công bố

| | T | MPE_SOH | MPE_Res | MPE_LLI | MPE_LAMNE | MPE_LAMPE | MPE_tot | MPE điện áp C/10 (mean ± std) | RMSE điện áp C/10 [mV] |
|---|---|---|---|---|---|---|---|---|---|
| Expt 2 (fit) — [P] Table 1, 2; [SI] Table 1 | 10 °C | 0.42 | 4.49 | 25.10 | 37.64 | 27.02 | 11.99 | 0.44 ± 0.13 | 23.29 ± 7.10 |
| | 25 °C | 0.88 | 5.50 | 22.75 | 20.58 | 30.94 | 10.41 | 0.48 ± 0.18 | 25.31 ± 9.75 |
| | 40 °C | 0.57 | 3.68 | 31.58 | 34.18 | 24.64 | 12.05 | 0.52 ± 0.20 | 28.45 ± 10.17 |
| Expt 3 (validation) — [SI] Table 10–12 (Table 12 theo cách đọc suy luận) | 10 °C | 5.3 | 6.95 | 38.1 | 81.06 | 61.45 | 26.1 | 2.45 ± 1.25 | 109.42 ± 55.22 |
| | 25 °C | 2.44 | 2.64 | 28.67 | 32.63 | 54.58 | 16.04 | 1.59 ± 0.57 | 72.58 ± 27.54 |
| | 40 °C | 0.75 | 5.86 | 22.67 | 19.82 | 33.32 | 10.58 | 1.01 ± 0.45 | 44.20 ± 19.81 |

(Đơn vị %; nguyên bảng cho hai mô hình còn lại ở `Li2025_tham_so.md` mục 6.) Tổng `MPE_tot` Expt 2: 34.45 % ([P] tr. 4). Notebook [Z] `Reload_Exp2.ipynb` in lại cho 40 °C: SOH 0.587, Res 3.682, LLI 31.565, LAM_NE 34.163, LAM_PE 24.640, tot 12.050 — trùng bảng.

### 14.2 Phân rã cuối mô phỏng của "5 coupled" ([ZD] xlsx tóm tắt của `Full_Exp1235_NC`; lưới [10,5,5,100,20])

| | Expt 2, 25 °C (case 5), 9.489 kAh | Expt 3, 40 °C (case 9), 9.479 kAh |
|---|---|---|
| SOH [%] | 90.579 | 86.300 |
| LLI tổng [%] | 8.194 | 11.900 |
| LLI do SEI / SEI trên nứt / mạ Li / LAM [%] | 0.895 / 1.708 / 0.103 / 5.488 | 1.208 / 2.305 / 0.157 / 8.230 |
| LAM_NE tổng = ứng suất + dry-out [%] | 5.727 = 0.503 + 5.224 | 8.833 = 1.667 + 7.166 |
| LAM_PE tổng (ứng suất ≈ 0) [%] | 5.224 | 7.166 |
| `eps_n` tại nút sát separator, cuối xả RPT | 0.20826 | 0.20205 |
| `V_tot = V_JR` cuối [mL] | 4.7839 | 4.6187 |
| `L_y` cuối [m] | 1.49746 | 1.46678 |

Expt 3, "5 coupled", cuối mô phỏng, ba nhiệt độ 10/25/40 °C ([Z] `Reload_Exp3.ipynb`, đầu ra in): LAM_NE do ứng suất = 3.007 / 2.075 / 1.667 %; LAM do dry-out = 7.059 / 6.725 / 7.166 %.

### 14.3 Chuỗi số theo RPT: thí nghiệm (trung bình cell) và mô hình "5 coupled" của tác giả

Nguồn: [SD] `Fig.3.xlsx`, `Fig.4.xlsx` (Expt 2), `Fig.6.xlsx` (Expt 3) — cột "Exp avg" và cột "5 coupled"; cột mô hình trùng với [ZD] `…Ageing_summary_only.mat` (Expt 2: `Full_Exp23_Paper_11_fine` case 4/13/22; Expt 3: `Full_Exp1235_NC` case 7/8/9). `Q_thr` = charge throughput. Bản MATLAB cần tái hiện các cột **mô hình** (cùng tham số, cùng giao thức); cột thí nghiệm để tính MPE.

**Expt 2 (70–85 %), 10 °C — thực nghiệm (trung bình các cell)**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] |
|---|---|---|---|---|
| 0.000 | 100.00 | 0.00 | 0.00 | 0.00 |
| 0.843 | 97.72 | 2.83 | 2.87 | 3.28 |
| 1.633 | 96.63 | 4.17 | 3.82 | 4.19 |
| 2.411 | 95.72 | 5.03 | 4.40 | 3.57 |
| 3.200 | 94.80 | 5.96 | 5.08 | 3.85 |
| 3.979 | 94.07 | 6.70 | 5.81 | 4.13 |
| 4.770 | 93.03 | 7.79 | 6.51 | 4.47 |
| 5.550 | 92.34 | 8.55 | 7.12 | 5.03 |
| 6.337 | 91.50 | 9.42 | 7.97 | 5.89 |
| 7.114 | 91.10 | 9.76 | 8.36 | 6.03 |
| 7.900 | 90.64 | 10.05 | 8.57 | 5.55 |
| 8.679 | 90.34 | 10.41 | 8.92 | 5.68 |
| 9.465 | 90.33 | 10.27 | 8.33 | 5.26 |

R_0.1s thực nghiệm [mΩ] (Q_thr [kAh] → R): 0.000 → 26.21; 1.633 → 26.47; 3.200 → 26.65; 4.770 → 26.70; 6.337 → 27.04; 7.900 → 27.08; 9.465 → 27.08

**Expt 2 (70–85 %), 10 °C — mô hình "5 coupled" của Li 2025**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] | R_0.1s [mΩ] |
|---|---|---|---|---|---|
| 0.039 | 100.00 | 0.00 | 0.00 | 0.00 | 26.18 |
| 0.831 | 98.43 | 1.27 | 0.87 | 0.79 | 26.56 |
| 1.623 | 97.15 | 2.40 | 1.67 | 1.51 | 26.91 |
| 2.414 | 96.02 | 3.40 | 2.38 | 2.14 | 27.22 |
| 3.204 | 95.00 | 4.30 | 3.03 | 2.71 | 27.51 |
| 3.995 | 94.06 | 5.13 | 3.64 | 3.24 | 27.78 |
| 4.785 | 93.18 | 5.90 | 4.21 | 3.73 | 28.04 |
| 5.574 | 92.36 | 6.63 | 4.75 | 4.20 | 28.30 |
| 6.364 | 91.58 | 7.31 | 5.26 | 4.63 | 28.54 |
| 7.153 | 90.83 | 7.97 | 5.76 | 5.05 | 28.78 |
| 7.942 | 90.12 | 8.60 | 6.24 | 5.45 | 29.02 |
| 8.730 | 89.44 | 9.20 | 6.70 | 5.83 | 29.25 |
| 9.519 | 88.78 | 9.78 | 7.15 | 6.20 | 29.47 |

**Expt 2 (70–85 %), 25 °C — thực nghiệm (trung bình các cell)**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] |
|---|---|---|---|---|
| 0.000 | 100.00 | 0.00 | 0.00 | 0.00 |
| 0.849 | 97.83 | 2.54 | 1.15 | 2.07 |
| 1.644 | 96.97 | 3.56 | 2.13 | 2.72 |
| 2.427 | 96.17 | 4.33 | 2.88 | 3.20 |
| 3.220 | 95.47 | 5.36 | 3.27 | 3.87 |
| 4.005 | 94.92 | 5.81 | 4.02 | 4.06 |
| 4.801 | 94.18 | 6.57 | 4.58 | 4.38 |
| 5.588 | 93.57 | 6.84 | 4.59 | 3.64 |
| 6.381 | 92.78 | 7.67 | 5.40 | 4.29 |
| 7.165 | 92.41 | 7.99 | 5.75 | 4.35 |
| 7.958 | 91.99 | 8.50 | 6.04 | 4.69 |
| 8.744 | 91.53 | 8.99 | 6.54 | 4.91 |
| 9.536 | 91.41 | 9.18 | 6.69 | 4.62 |

R_0.1s thực nghiệm [mΩ] (Q_thr [kAh] → R): 0.000 → 28.50; 1.644 → 28.94; 3.220 → 29.14; 4.801 → 29.40; 6.381 → 29.82; 7.958 → 29.98; 9.536 → 30.47

**Expt 2 (70–85 %), 25 °C — mô hình "5 coupled" của Li 2025**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] | R_0.1s [mΩ] |
|---|---|---|---|---|---|
| 0.039 | 100.00 | 0.00 | 0.00 | 0.00 | 26.18 |
| 0.831 | 98.49 | 1.20 | 0.79 | 0.75 | 26.54 |
| 1.623 | 97.27 | 2.28 | 1.53 | 1.44 | 26.86 |
| 2.414 | 96.19 | 3.23 | 2.18 | 2.06 | 27.15 |
| 3.205 | 95.22 | 4.09 | 2.78 | 2.61 | 27.42 |
| 3.995 | 94.32 | 4.88 | 3.34 | 3.13 | 27.68 |
| 4.785 | 93.49 | 5.62 | 3.86 | 3.60 | 27.93 |
| 5.575 | 92.71 | 6.31 | 4.35 | 4.05 | 28.16 |
| 6.365 | 91.97 | 6.96 | 4.81 | 4.48 | 28.39 |
| 7.154 | 91.27 | 7.58 | 5.26 | 4.88 | 28.61 |
| 7.943 | 90.61 | 8.17 | 5.69 | 5.26 | 28.83 |
| 8.732 | 89.97 | 8.74 | 6.10 | 5.63 | 29.04 |
| 9.520 | 89.35 | 9.28 | 6.50 | 5.98 | 29.24 |

**Expt 2 (70–85 %), 40 °C — thực nghiệm (trung bình các cell)**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] |
|---|---|---|---|---|
| 0.000 | 100.00 | 0.00 | 0.00 | 0.00 |
| 0.850 | 97.26 | 2.88 | 2.10 | 1.86 |
| 1.645 | 95.90 | 4.51 | 2.84 | 2.73 |
| 2.429 | 94.91 | 5.35 | 3.75 | 2.60 |
| 3.223 | 93.99 | 6.40 | 4.52 | 3.06 |
| 4.008 | 93.25 | 7.42 | 4.98 | 4.07 |
| 4.805 | 92.42 | 8.25 | 5.65 | 4.54 |
| 5.592 | 91.92 | 8.55 | 5.89 | 3.86 |
| 6.385 | 91.22 | 9.33 | 6.51 | 4.62 |
| 7.169 | 90.80 | 9.77 | 6.93 | 5.05 |
| 7.961 | 90.35 | 10.18 | 7.37 | 4.68 |
| 8.747 | 89.81 | 10.73 | 7.92 | 5.24 |
| 9.540 | 89.32 | 11.25 | 8.43 | 5.56 |

R_0.1s thực nghiệm [mΩ] (Q_thr [kAh] → R): 0.000 → 25.84; 1.645 → 26.21; 3.223 → 26.80; 4.805 → 27.14; 6.385 → 27.40; 7.961 → 27.62; 9.540 → 27.75

**Expt 2 (70–85 %), 40 °C — mô hình "5 coupled" của Li 2025**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] | R_0.1s [mΩ] |
|---|---|---|---|---|---|
| 0.039 | 100.00 | 0.00 | 0.00 | 0.00 | 26.18 |
| 0.831 | 98.34 | 1.33 | 0.86 | 0.83 | 26.57 |
| 1.623 | 97.01 | 2.51 | 1.66 | 1.60 | 26.92 |
| 2.414 | 95.85 | 3.53 | 2.36 | 2.27 | 27.24 |
| 3.204 | 94.81 | 4.46 | 2.99 | 2.87 | 27.53 |
| 3.995 | 93.86 | 5.30 | 3.57 | 3.42 | 27.81 |
| 4.784 | 92.98 | 6.08 | 4.11 | 3.94 | 28.07 |
| 5.574 | 92.16 | 6.81 | 4.62 | 4.41 | 28.32 |
| 6.363 | 91.39 | 7.49 | 5.10 | 4.86 | 28.56 |
| 7.152 | 90.66 | 8.14 | 5.55 | 5.29 | 28.80 |
| 7.941 | 89.97 | 8.75 | 5.99 | 5.69 | 29.02 |
| 8.730 | 89.31 | 9.34 | 6.40 | 6.08 | 29.24 |
| 9.518 | 88.69 | 9.89 | 6.81 | 6.44 | 29.46 |

**Expt 3 (85–100 %), 10 °C — thực nghiệm (trung bình các cell)**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] |
|---|---|---|---|---|
| 0.000 | 100.00 | 0.00 | 0.00 | 0.00 |
| 0.749 | 97.55 | 1.24 | -2.06 | 1.52 |
| 1.499 | 93.92 | 4.20 | -0.32 | 5.07 |
| 2.249 | 91.34 | 6.94 | 2.39 | 7.68 |
| 2.998 | 89.48 | 8.84 | 4.54 | 8.85 |
| 3.747 | 87.56 | 10.88 | 5.71 | 9.78 |
| 4.495 | 85.88 | 12.50 | 7.71 | 10.04 |
| 5.245 | 84.14 | 14.07 | 9.54 | 11.50 |
| 5.974 | 79.01 | 18.04 | 14.01 | 15.29 |
| 6.179 | 77.12 | 19.55 | 15.33 | 17.43 |
| 6.367 | 79.47 | 17.05 | 13.61 | 9.84 |

R_0.1s thực nghiệm [mΩ] (Q_thr [kAh] → R): 0.000 → 25.86; 0.749 → 27.59; 1.499 → 28.68; 2.249 → 29.73; 2.998 → 34.90; 3.747 → 36.35

**Expt 3 (85–100 %), 10 °C — mô hình "5 coupled" của Li 2025**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] | R_0.1s [mΩ] |
|---|---|---|---|---|---|
| 0.039 | 100.01 | 0.00 | 0.00 | 0.00 | 26.46 |
| 0.828 | 98.22 | 1.50 | 1.12 | 0.83 | 26.88 |
| 1.617 | 96.61 | 2.88 | 2.18 | 1.61 | 27.28 |
| 2.405 | 95.16 | 4.14 | 3.16 | 2.32 | 27.65 |
| 3.193 | 93.82 | 5.29 | 4.07 | 2.97 | 28.01 |
| 3.980 | 92.57 | 6.37 | 4.93 | 3.58 | 28.35 |
| 4.766 | 91.39 | 7.39 | 5.75 | 4.15 | 28.69 |
| 5.553 | 90.27 | 8.36 | 6.54 | 4.69 | 29.01 |
| 6.338 | 89.20 | 9.27 | 7.29 | 5.20 | 29.34 |
| 7.123 | 88.18 | 10.15 | 8.02 | 5.69 | 29.66 |
| 7.908 | 87.20 | 11.00 | 8.72 | 6.16 | 29.98 |
| 8.693 | 86.26 | 11.81 | 9.40 | 6.62 | 30.29 |
| 9.477 | 85.34 | 12.60 | 10.07 | 7.06 | 30.61 |

**Expt 3 (85–100 %), 25 °C — thực nghiệm (trung bình các cell)**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] |
|---|---|---|---|---|
| 0.000 | 100.00 | 0.00 | 0.00 | 0.00 |
| 0.758 | 98.39 | 1.16 | -0.45 | 1.59 |
| 1.517 | 95.76 | 3.58 | -0.86 | 4.61 |
| 2.275 | 93.72 | 5.53 | 1.21 | 6.53 |
| 3.033 | 92.05 | 7.41 | 2.97 | 8.01 |
| 3.792 | 90.59 | 8.90 | 4.17 | 9.06 |
| 4.550 | 89.10 | 10.46 | 5.72 | 10.54 |
| 5.309 | 88.73 | 10.28 | 6.98 | 8.36 |
| 6.067 | 86.30 | 12.21 | 10.32 | 9.91 |
| 6.825 | 85.34 | 13.08 | 11.23 | 10.83 |
| 7.582 | 83.09 | 15.01 | 13.73 | 12.61 |

R_0.1s thực nghiệm [mΩ] (Q_thr [kAh] → R): 0.000 → 26.34; 0.758 → 27.56; 1.517 → 29.14; 2.275 → 29.16; 3.033 → 30.32; 3.792 → 37.32

**Expt 3 (85–100 %), 25 °C — mô hình "5 coupled" của Li 2025**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] | R_0.1s [mΩ] |
|---|---|---|---|---|---|
| 0.039 | 100.01 | 0.00 | 0.00 | 0.00 | 26.46 |
| 0.828 | 98.38 | 1.37 | 0.99 | 0.77 | 26.85 |
| 1.617 | 96.91 | 2.64 | 1.94 | 1.51 | 27.22 |
| 2.406 | 95.58 | 3.80 | 2.81 | 2.19 | 27.56 |
| 3.193 | 94.35 | 4.86 | 3.62 | 2.81 | 27.88 |
| 3.981 | 93.21 | 5.85 | 4.38 | 3.39 | 28.20 |
| 4.768 | 92.14 | 6.78 | 5.10 | 3.93 | 28.50 |
| 5.555 | 91.13 | 7.66 | 5.78 | 4.45 | 28.80 |
| 6.341 | 90.16 | 8.50 | 6.43 | 4.94 | 29.09 |
| 7.127 | 89.24 | 9.30 | 7.05 | 5.41 | 29.38 |
| 7.912 | 88.36 | 10.06 | 7.66 | 5.87 | 29.66 |
| 8.697 | 87.51 | 10.80 | 8.24 | 6.30 | 29.94 |
| 9.482 | 86.70 | 11.51 | 8.80 | 6.73 | 30.22 |

**Expt 3 (85–100 %), 40 °C — thực nghiệm (trung bình các cell)**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] |
|---|---|---|---|---|
| 0.000 | 100.00 | 0.00 | 0.00 | 0.00 |
| 0.755 | 98.57 | 1.47 | 1.42 | 1.42 |
| 1.511 | 96.46 | 2.83 | 2.78 | 3.19 |
| 2.266 | 94.61 | 4.50 | 4.20 | 4.43 |
| 3.022 | 92.94 | 6.28 | 5.72 | 6.02 |
| 3.777 | 91.35 | 8.16 | 7.27 | 7.44 |
| 4.533 | 88.70 | 10.93 | 9.94 | 10.09 |
| 5.289 | 89.30 | 10.09 | 8.78 | 8.27 |
| 6.045 | 86.71 | 12.38 | 9.17 | 10.41 |
| 6.799 | 86.07 | 13.03 | 9.70 | 11.05 |
| 7.553 | 84.96 | 13.69 | 11.37 | 11.82 |
| 8.308 | 86.52 | 14.00 | 15.00 | 9.94 |

R_0.1s thực nghiệm [mΩ] (Q_thr [kAh] → R): 0.000 → 26.89; 0.755 → 27.84; 1.511 → 30.42; 2.266 → 29.05; 3.022 → 29.96; 3.777 → 31.07

**Expt 3 (85–100 %), 40 °C — mô hình "5 coupled" của Li 2025**

| Q_thr [kAh] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] | R_0.1s [mΩ] |
|---|---|---|---|---|---|
| 0.039 | 100.01 | 0.00 | 0.00 | 0.00 | 26.46 |
| 0.828 | 98.25 | 1.46 | 1.03 | 0.84 | 26.88 |
| 1.617 | 96.71 | 2.81 | 2.01 | 1.64 | 27.27 |
| 2.405 | 95.32 | 4.02 | 2.90 | 2.37 | 27.64 |
| 3.192 | 94.05 | 5.13 | 3.72 | 3.04 | 27.98 |
| 3.980 | 92.88 | 6.15 | 4.49 | 3.65 | 28.31 |
| 4.766 | 91.78 | 7.11 | 5.20 | 4.23 | 28.63 |
| 5.553 | 90.75 | 8.01 | 5.88 | 4.78 | 28.94 |
| 6.339 | 89.77 | 8.86 | 6.52 | 5.30 | 29.24 |
| 7.124 | 88.85 | 9.67 | 7.14 | 5.79 | 29.54 |
| 7.910 | 87.96 | 10.44 | 7.72 | 6.27 | 29.84 |
| 8.695 | 87.11 | 11.19 | 8.29 | 6.72 | 30.13 |
| 9.479 | 86.30 | 11.90 | 8.83 | 7.17 | 30.42 |

---

## 15. Tổng hợp biến trạng thái và thứ tự tính (để cài)

| Biến | Miền | Đơn vị | Phương trình | Điều kiện đầu ("5 coupled") |
|---|---|---|---|---|
| `L_inner`, `L_outer` | mỗi nút x cực âm | m | mục 3 | 9.23265e-9 |
| `L_inner_cr`, `L_outer_cr` | mỗi nút x cực âm | m | mục 6.2 | 9.23265e-9 |
| `c_Li`, `c_dl` | mỗi nút x cực âm | mol/m³ | mục 4 | 0, 0 |
| `l_cr` | mỗi nút x cực âm | m | mục 6.1 | 2e-8 |
| `eps_s_n` | mỗi nút x cực âm | – | mục 7 | 0.75 |
| `eps_s_p` | mỗi nút x cực dương | – | mục 7 | 0.665 |
| `j_tot_n` (đại số) | mỗi nút x cực âm | A/m² | mục 2.2 | 0 |
| `eps·c_e` | mọi nút x | mol/m³ | mục 2.2 | `eps_0·1000` |
| `T` | toàn cell | K | mục 2.4 | 298.15 |
| `LLI_LAM_n`, `LLI_LAM_p` (chẩn đoán) | toàn cell | mol | mục 7 | 0 |
| lớp bọc: `V_tot`, `V_JR`, `L_y`, `c_e_res`, `c_EC_res`, `c_EC_JR` | toàn cell, rời rạc | m³, m³, m, mol/m³ | mục 10 | 5.23616e-6, 5.23616e-6, 1.58, 1000, 4541, 4541 |

Đại lượng đại số dẫn xuất tại mỗi nút x cực âm: `S`, `a_n`, `eps_n`, `eta_SEI`, `sigma_t_surf`, `sigma_h`.

Thứ tự tính vế phải tại một thời điểm (mỗi nút x): (1) `a_k = 3·eps_s_k/R_k`, `S`, `eps_n` từ trạng thái; (2) `c_e = (eps·c_e)/eps`; (3) giải hệ đại số DFN cho `φ_s`, `φ_e`, `j_tot_n` với `j_int`, `j_SEI`, `j_SEIcr`, `j_pl` là hàm của `δφ`, `j_tot_n`, `c_surf`, `c_e`, `T` và các trạng thái lão hoá; (4) `c_rav`, `c_surf` → `sigma_t_surf`, `sigma_h`; (5) vế phải của các ODE lão hoá; (6) nhiệt. Sau mỗi đoạn: mục 10.

Kiểm tra bảo toàn nên có trong bản MATLAB: tổng lithium `n_Li_particles + n_Li_e + Q_SEI* + Q_SEIcr* + Q_pl + LLI_LAM_n + LLI_LAM_p` không đổi trong một đoạn (với `Q_SEI*`, `Q_SEIcr*` tính bằng tích phân `−a_n·j/F` chứ không bằng công thức `a_typ`, xem C8), và chỉ nhảy tại lúc cập nhật dry-out.

---

## 16. Tầng 2: lão hoá silicon ở SOC thấp (giả định)

> **TOÀN BỘ MỤC NÀY LÀ ĐỀ XUẤT, KHÔNG PHẢI MÔ HÌNH CỦA Li 2025.** Không có phương trình hay tham số nào dưới đây được Li 2025 hay mã của họ cung cấp. Mọi kết quả dùng Tầng 2 phải được gắn nhãn "giả định" trong báo cáo. Tầng 1 (mục 1–15) phải chạy được và cho đúng số khi Tầng 2 tắt (`k_LAM_Si = 0`).

### 16.1 Vì sao cần

- [P] tr. 6: cả ba mô hình thất bại với Expt 1 (0–30 %) và Expt 5 (0–100 %) vì thiếu cơ chế suy giảm cơ học của silicon ở SOC thấp; mã của họ dùng cực âm một pha "gộp" (một hạt, một OCP, một `c_max`).
- Kirkaldy 2022 (số in trong văn bản): ở 0–30 % SOC, 40 °C, sau 4 kAh mất **80 %** dung lượng silicon nhưng chỉ **10 %** dung lượng graphite (tr. 1); **> 70 %** sau 4 kAh ở nhiệt độ trung/cao (tr. 8); ở 0–100 %, 25 °C, **> 30 %** sau 5 kAh (tr. 8); giai đoạn tăng tốc nằm trong **2 kAh** đầu, sau đó tuyến tính chậm (tr. 6); cell 10 °C mất silicon ít hơn. Lý giải của họ: silicon chỉ hoạt động ở SOC thấp và chịu mật độ dòng rất cao do diện tích bề mặt nhỏ (tr. 2, 8).

### 16.2 Đề xuất tối thiểu (T2-A): thêm MỘT trạng thái `eps_Si(x,t)` và một luật LAM do ứng suất riêng cho silicon

Giữ nguyên hạt gộp và OCP gộp của Tầng 1 (không thêm PDE). Tách phần thể tích hoạt tính cực âm theo **đương lượng dung lượng**:

```
eps_s_n(x,t) = eps_Gr(x,t) + eps_Si(x,t)
eps_Si(x,0)  = f_Si·eps_s_n,0 ;   eps_Gr(x,0) = (1 − f_Si)·eps_s_n,0
d(eps_Gr)/dt = − beta_n·(sigma_h/sigma_c_n)^m2_n                    (đúng số hạng Tầng 1, mục 7 — không đổi)
d(eps_Si)/dt = − k_LAM_Si · ( dc_Si )^m_Si · ( eps_Si / eps_Si,0 )     khi dc_Si > 0 ;  = 0 khi dc_Si ≤ 0
```

với "độ chênh nồng độ tâm–mặt" của hạt silicon ước lượng bằng nghiệm tựa dừng (profile parabol) của khuếch tán cầu dưới thông lượng bề mặt không đổi:

```
w_Si(x,t)  = w_lo + (w_hi − w_lo)·( 1 − tanh( (sto_surf − sto_Si)/d_sto ) )/2        (phần dòng xen cài do silicon mang)
a_Si(x,t)  = 3·eps_s_n,0·V_Si/R_Si · ( eps_Si/eps_Si,0 )                              [1/m]   (Ai 2022 eq. 3, co theo LAM-Si)
j_Si(x,t)  = w_Si · a_n·j_int / a_Si                                                   [A/m²]
dc_Si(x,t) = j_Si·R_Si / (5·F·D_Si)                                                    [mol/m³]  (= c_avg − c_surf của hạt Si; > 0 khi nhả lithium)
```

Diễn giải: đây chính là luật (S21)–(S22) của Li 2025 áp cho silicon, `d eps/dt = −beta_Si·(sigma_h,Si/sigma_c,Si)^m`, với `sigma_h,Si = (2/3)·Omega_Si·E_Si/(3(1−nu_Si))·dc_Si` (cùng công thức ứng suất bề mặt như mục 5); gộp các hằng số cơ học chưa biết vào một hằng:
`k_LAM_Si = beta_Si·( 2·Omega_Si·E_Si / (9·(1−nu_Si)·sigma_c,Si) )^m_Si`. Nhờ vậy không phải giả định riêng `Omega_Si`, `E_Si`, `nu_Si`, `sigma_c,Si`, `beta_Si` — chỉ một hằng `k_LAM_Si` cần hiệu chỉnh.

Ghép vào Tầng 1 (không sửa gì khác): `eps_s_n = eps_Gr + eps_Si` đi vào `a_n = 3·eps_s_n/R_n`, dung lượng cực âm, LLI do LAM (mục 7, 9). Chỉ số báo cáo thêm: `LAM_Si% = (1 − xavg(eps_Si)/eps_Si,0)·100`, `LAM_Gr%` tương tự (cộng phần dry-out như mục 9).

Các tính chất cố ý của luật này (và là giả định):
- chỉ gây mất silicon khi cực âm **nhả lithium ở stoichiometry thấp** (xả sâu) và tăng theo dòng xả — khớp định tính với lý giải của Kirkaldy 2022 và nhận xét của Ai 2022 (tr. 18–19);
- thừa số `eps_Si/eps_Si,0` giữ `eps_Si ≥ 0` và tạo dạng "nhanh lúc đầu rồi chậm dần"; đồng thời `a_Si` co lại làm `j_Si` tăng (hồi tiếp dương, cùng kiểu LAM → a của Tầng 1) — hai hiệu ứng này cạnh tranh, phải kiểm tra khi hiệu chỉnh;
- phụ thuộc nhiệt độ chỉ qua `j_int`, `sto_surf` (không có Arrhenius riêng; `D_Si` hằng).

Hạn chế đã biết của T2-A (phải ghi trong báo cáo): (i) OCP gộp không đổi dạng khi mất silicon — mất `eps_Si` chỉ co đều dung lượng cực âm, không làm biến mất "đoạn silicon" ở SOC thấp như thí nghiệm ICA cho thấy; (ii) `w_Si` là hàm chuyển giả định, không phải kết quả của cân bằng thế hai pha; (iii) nồng độ trong hạt silicon không được giải nên lithium kẹt trong silicon bị mất được tính bằng `c_s` của hạt gộp; (iv) SEI/mạ/nứt của Tầng 1 vẫn tính trên diện tích hạt gộp.

### 16.3 Tham số của T2-A

| Ký hiệu | Ý nghĩa | Giá trị khởi đầu | Trạng thái / nguồn |
|---|---|---|---|
| `R_Si` | bán kính hạt silicon | 1.52e-6 m | Ai 2022 Table 3 (tr. 12), từ Chen 2020 |
| `D_Si` | hệ số khuếch tán trong silicon | 1.67e-14 m²/s | Ai 2022 Table 3 (văn liệu, hằng số) |
| `V_Si` | phần thể tích silicon trong vật liệu hoạt tính (dùng cho `a_Si`) | 0.02 | Ai 2022 Table 3 (**ước lượng** của họ; Chen 2020 nêu ~10 % từ EDS bề mặt) |
| `f_Si` | phần **dung lượng** cực âm thuộc silicon ở BOL | 0.800/5.272 = 0.152 | tính từ Kirkaldy 2024 Table 7 (tr. 6); Kirkaldy 2022 cho 0.15 và 0.13 (tr. 5). Việc dùng nó làm `eps_Si,0/eps_s_n,0` là **GIẢ ĐỊNH** |
| `sto_Si` | stoichiometry gộp mà dưới đó silicon mang phần lớn dòng | ≈ 0.14 (= 0.800 Ah / dung lượng cực âm của mô hình 5.72 Ah) | **GIẢ ĐỊNH** (coi dung lượng silicon nằm liền ở đáy dải stoichiometry) — hiệu chỉnh |
| `d_sto` | độ rộng chuyển tiếp | 0.03 | **GIẢ ĐỊNH** — hiệu chỉnh |
| `w_lo`, `w_hi` | phần dòng do silicon mang ở SOC cao / thấp | 0.1, 0.9 | **GIẢ ĐỊNH**, lấy theo mô tả định tính "∼0.9 I_app" của Ai 2022 (tr. 15, sơ đồ minh hoạ) |
| `m_Si` | số mũ | 2 (bằng `m2` của Tầng 1) | **GIẢ ĐỊNH** |
| `k_LAM_Si` | hằng tốc độ gộp | không có giá trị khởi đầu có căn cứ; bắt đầu bằng 0 rồi hiệu chỉnh | **GIẢ ĐỊNH — tham số hiệu chỉnh chính**, đơn vị (m³/mol)^m_Si / s |

Tham số có thể cần nếu không gộp hằng số cơ học (`Omega_Si`, `E_Si`, `nu_Si`, `sigma_c,Si`, `beta_Si`): không có trong bất kỳ tài liệu nào đã đọc của đồ án, ngoại trừ `sigma_c,Si = 0.72 GPa` ghi trong Bonkile 2024 (theo ghi chú cuối `Li2025_tham_so.md`; bài đó không in `beta_Si`). Vì vậy đề xuất dùng dạng gộp.

### 16.4 Số liệu dùng để hiệu chỉnh và kiểm tra (chỉ số in trong văn bản/bảng)

Giao thức cần mô phỏng (Kirkaldy 2024 Table 2 và 6, tr. 3; trùng [Z] `Initialize_exp_text` cho `index_exp = 1` và `5`):
- Expt 1 (0–30 %): xả 1C tới 2.5 V → CV 2.5 V tới C/100 → nghỉ 4 h → [sạc 0.3C trong 60 phút (1500 mAh) → xả 1C tới 2.5 V] × 258 mỗi set; 10/25/40 °C.
- Expt 5 (0–100 %): [xả 1C tới 2.5 V → sạc 0.3C tới 4.2 V → CV tới C/100] × 78 mỗi set; 10/25/40 °C.

| Mục tiêu | Giá trị | Nguồn | Vai trò |
|---|---|---|---|
| LAM-Si, 0–30 %, 40 °C, sau 4 kAh | 80 % | Kirkaldy 2022 tr. 1 | hiệu chỉnh `k_LAM_Si` |
| LAM-Si, 0–30 %, nhiệt độ trung/cao, sau 4 kAh | > 70 % | Kirkaldy 2022 tr. 8 | ràng buộc dưới |
| LAM-Gr, 0–30 %, 40 °C, sau 4 kAh | 10 % | Kirkaldy 2022 tr. 1 | kiểm tra (Tầng 1 + dry-out không được vượt xa) |
| LAM-Si, 0–100 %, 25 °C, sau 5 kAh | > 30 % (so với 80 % ở 0–30 %) | Kirkaldy 2022 tr. 8 | hiệu chỉnh `sto_Si`, `d_sto` (tỉ lệ giữa hai cửa sổ) |
| Giai đoạn mất nhanh ở 0–30 % | trong 2 kAh đầu | Kirkaldy 2022 tr. 6 | kiểm tra dạng đường (thừa số `eps_Si/eps_Si,0`) |
| 0–30 % ở 10 °C: mất silicon ít hơn 25/40 °C | định tính | Kirkaldy 2022 tr. 6, 8 | kiểm tra dấu của phụ thuộc nhiệt độ |
| Dung lượng BOL: Gr 4.471 Ah, Si 0.800 Ah, NE 5.272 Ah, PE 5.634 Ah | Table 7 | Kirkaldy 2024 tr. 6 | đặt `f_Si`; kiểm tra cân bằng điện cực |
| 70–85 % và 85–100 % | phải giữ nguyên các số ở mục 14 | [P], [SD] | **kiểm tra không phá Tầng 1**: với `sto_Si ≈ 0.14`, hai cửa sổ này hầu như không kích hoạt `w_hi` |

Kirkaldy 2024 không in con số lão hoá nào theo cửa sổ (chỉ hình) nên không cung cấp thêm mục tiêu số. Dữ liệu số từng RPT của Expt 1 và 5 (kể cả kết quả OCV-fitting) có trong Zenodo 10.5281/zenodo.10637534 và, ở dạng đã xử lý, trong [ZD] `SimSave/InputData/Expt 1 - Si-based Degradation/` (`… Extracted Data.csv`, `DMA Output/`) — **chưa đọc**; nếu đồ án dùng chúng thì đó là số liệu thật thay cho các mốc văn bản ở trên.

### 16.5 Phương án đầy đủ hơn (T2-B) — chỉ nêu, không đề xuất cài trước

Cực âm hai pha của Ai 2022 (eq. 1–7): hai hạt (graphite, silicon) tại mỗi nút x, cùng `φ_s`, mỗi pha có Butler–Volmer, OCP và khuếch tán riêng; áp ứng suất + LAM kiểu mục 5 và 7 cho từng pha (như Bonkile 2024). Ưu điểm: sửa được các hạn chế (i)–(iii). Cái giá: phải thay lõi DFN cực âm; OCP silicon/graphite không in trong Ai 2022 (chỉ có hình) — có ở dạng hàm trong [PB] `input/parameters/lithium_ion/Chen2020_composite.py` (`silicon_ocp_lithiation_Mark2016`, `silicon_ocp_delithiation_Mark2016`, `graphite_ocp_Enertech_Ai2020`; chưa chép vào đây); toàn bộ tham số BOL và tham số lão hoá của Li 2025 (fit cho cực âm gộp với OCP gộp) **mất hiệu lực** và phải fit lại; tham số cơ học của silicon vẫn là giả định. Vì thế T2-B nằm ngoài "mở rộng tối thiểu".
