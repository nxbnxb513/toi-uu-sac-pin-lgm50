# Li et al. 2025 — mô hình lão hoá 5 cơ chế cho LG M50T, SEI phụ thuộc thế cực âm

> Đã đọc TOÀN VĂN bài chính (Nature Communications, 10 trang) + Supplementary Information (57 trang).
> File: `tai_lieu/Li2025_NatCommun.pdf`, `tai_lieu/Li2025_NatCommun_SI.pdf`; text: `toan_van_trich_xuat/Li2025.txt`, `Li2025_SI.txt`.
> "tr. N" = trang PDF bài chính; "SI tr. N" = trang PDF của SI.
> Bài này chính là bản đăng tạp chí của preprint arXiv:2311.05482 ("Lithium-ion battery degradation: using degradation mode analysis to validate lifetime prediction modelling", 11/2023) — tên đã đổi. Bản arXiv KHÔNG đọc, không lưu.

## 1. Trích dẫn, tạp chí, giấy phép

- R. Li, N. D. Kirkaldy, F. F. Oehler, M. Marinescu, G. J. Offer, S. E. J. O'Kane, "The importance of degradation mode analysis in parameterising lifetime prediction models of lithium-ion battery degradation", *Nature Communications* **16** (2025) 2776. DOI: https://doi.org/10.1038/s41467-025-57968-3
- Nhận 17/06/2024, chấp nhận 10/03/2025 (tr. 1).
- Giấy phép: **open access, CC BY 4.0** (tr. 10).
- Tác giả cuối là S. O'Kane (tác giả chính của O'Kane 2022) → kế thừa trực tiếp mô hình cũ.

## 2. Ma trận thí nghiệm (dữ liệu dùng để fit/validate)

Dữ liệu lấy từ Kirkaldy et al. 2024 (ref. 32), cell **LG M50T**, SiOx-graphite / NMC811, 5 Ah danh định (tr. 6).

| Vai trò | Experiment (theo Kirkaldy 2024) | SOC window | Nhiệt độ | Sạc / xả | Số cell | Số RPT dùng |
|---|---|---|---|---|---|---|
| **Parameterisation** | Expt 2 | **70–85%** | 10, 25, 40 °C | 0.3C / 1C | 2 mỗi nhiệt độ | 13 RPT (Table 1) |
| **Validation** | Expt 3 | **85–100%** | 10, 25, 40 °C | 0.3C / 1C | 3 mỗi nhiệt độ | KHÔNG RÕ số RPT |
| Thử thêm, **thất bại** | Expt 1 và Expt 5 | 0–30% và 0–100% | chỉ nêu 40 °C | 0.3C / 1C | — | SI Fig. 7 |
| Không thử | Expt 4 | 0–100% drive cycle | — | — | — | (quá tốn thời gian tính, tr. 6) |

- Supplementary Table 5 (SI tr. 22) chép lại Table 1 của Kirkaldy 2024 (258/515/515/78/78 chu kỳ mỗi ageing set; số cell 3-3-3 / 2-2-2 / 3-3-3 / 3-2-3 / 3-2-3).
- Mô phỏng RPT rút gọn: chỉ 0.1C, 0.5C (lặp hai lần để giữ charge throughput), và GITT 0.5C 25 xung (SI tr. 31).
- So sánh trực tiếp Expt 2 vs Expt 3 tại charge throughput **6.37 kAh** (chú thích SI Fig. 6, SI tr. 7) — giá trị chỉ ở dạng hình.
- Chỉ số so khớp: SOH (C/10), R0.1s (xung thứ 12 ≈ 52% SOC), LLI, LAM_NE, LAM_PE, và đường áp C/10 (tr. 3–4, 8).

## 3. Kết quả dạng SỐ theo SOC window

Bài KHÔNG in số capacity fade/LLI/LAM thực nghiệm theo window. Số có trong bảng là **sai số mô hình** (mục 6). Nhận định định tính về SOC window:
- Capacity loss của Expt 3 (85–100%) ở 10 °C "much larger" so với Expt 2 (70–85%) ở 10 °C; ở 40 °C chênh lệch nhỏ hơn (tr. 5–6).
- Mô hình 5 coupled dự đoán tốt nhất ở SOC cao nhờ **LAM_NE do ứng suất tăng thêm ở dải SOC cao** (tr. 5; SI Fig. 5).
- Cả ba mô hình **không tái hiện được** phụ thuộc SOC giữa Expt 2 và Expt 3 ở 10 °C và 25 °C; chỉ 5 coupled bắt được ở 40 °C (tr. 6).
- Cả ba mô hình **thất bại** với Expt 1 (0–30%) và Expt 5 (0–100%) vì thiếu cơ chế suy giảm cơ học của silicon ở SOC thấp (tr. 6).
- SI tr. 55: trong SEI + Dry out, LLI do dry-out "almost twice" LLI do SEI ở cả ba nhiệt độ; trong 5 coupled, LAM chiếm phần lớn nhất của LLI.

## 4. Phương trình mô hình

Nền: DFN (P2D) + lumped thermal (tr. 6). Năm cơ chế: (1) SEI growth, (2) electrolyte dry-out, (3) lithium plating, (4) LAM, (5) particle cracking (tr. 2). Ba mô hình: **SEI only**; **SEI + Dry out**; **5 coupled** (tr. 3).

Lưu ý đánh số: SI dùng lại nhãn (S1)–(S27) cho cả Note 1–6 lẫn Note 8–11. Dưới đây ghi kèm tên Note để phân biệt.

### 4.1 SEI — interstitial-diffusion limited (SI Note 2, SI tr. 33–34) — **THAY cho eq. solvent-diffusion của O'Kane 2022**

Tác giả viết: mô hình solvent-diffusion limited của O'Kane "has no dependence on SoC, despite SoC dependence also being observed throughout the literature"; ở đây theo Single et al. 2018 và von Kolzenberg et al. 2020, tốc độ SEI bị giới hạn bởi khuếch tán lithium interstitial trung hoà qua lớp SEI trong (SI tr. 33).

- (Note 2, S2) `j_SEI = (c_int,Li / L_SEI^inner) · D_int · F · exp(−(φ_s − φ_e))` [A/m²]
- (S3) `j_SEI,inner = 0.5 j_SEI`; (S4) `j_SEI,outer = 0.5 j_SEI`
- (S5) `j_SEI(T) = j_SEI(T_ref) · exp(E_SEI/(R T_ref) − E_SEI/(R T))`, T_ref = 298.15 K
- (S6) `dL_SEI,inner/dt = j_SEI,inner/(2F) · V̄_SEI^inner = c_int/(2 L_SEI^inner) · D_int · V̄_SEI^inner · e^{−(φ_s−φ_e)}`
- (S7) tương tự cho outer với `L_SEI^outer`, `V̄_SEI^outer`
- (S8) `L_SEI = L_SEI,inner + L_SEI,outer`
- (S9) `η_SEI = ρ_SEI · j_n^tot · L_SEI`

**Phụ thuộc SOC/thế:** tốc độ SEI ∝ exp(−(φ_s − φ_e)) / L_SEI, tức tăng theo hàm mũ khi thế bề mặt cực âm (φ_s − φ_e) giảm — SOC cao, và càng thấp hơn trong lúc sạc do quá thế. Đây là chỗ mô hình phân biệt được 20–50% với 0–30% và phân biệt được profile sạc khác nhau. `c_int` và `D_int` chỉ xuất hiện dưới dạng tích → thực chất là một tham số (SI tr. 34).

**KHÔNG RÕ (quan trọng khi tự cài trong MATLAB):** số mũ in trong (S2), (S6), (S7), (Note 4, S20) là `−(φ_s − φ_e)` **không có hệ số F/(RT)** → không vô thứ nguyên. Dạng gốc trong tài liệu được trích (Single 2018 / von Kolzenberg 2020) và trong PyBaMM, theo trí nhớ của người tóm tắt (CHƯA kiểm chứng bằng nguồn đã đọc), là `exp(−F(φ_s − φ_e)/(RT))`. Phải đối chiếu với code trong Zenodo 14995785 trước khi dùng; nếu không kiểm được thì ghi là giả định.
Tương tự, `φ_s − φ_e` có trừ `η_SEI` hay không: KHÔNG RÕ (plating eq. S10 thì có trừ).

### 4.2 Lithium plating (SI Note 3, SI tr. 35) — "unchanged from O'Kane et al."

- (S10) `j_Li = F k_Li ( c_Li · exp(F α_a,Li (φ_s − φ_e − η_SEI)/(RT)) − c_e · exp(−F α_c,Li (φ_s − φ_e − η_SEI)/(RT)) )`
- (S11) `∂c_Li/∂t = −a_n j_Li / F − ∂c_dl/∂t`
- (S12) `∂c_dl/∂t = γ c_Li`
- (S13) `γ = γ_0 · L_SEI,0 / L_SEI`

### 4.3 Stress, cracking, SEI on cracks (SI Note 4, SI tr. 36–37) — giống O'Kane 2022, riêng SEI-on-cracks đổi sang dạng interstitial

- (S14) `σ_r = 2ΩE/(1−ν) · [c_avg(R_i) − c_avg(r)]`
- (S15) `σ_t = ΩE/(1−ν) · [2 c_avg(R_i) + c_avg(r) − c̄/3]`
- (S16) `u = (1+ν)/(1−ν) · Ω r c_avg(r) + 2(1−2ν)/(1−ν) · Ω r c_avg(R_i)`
- (S17) `c_avg(r) = 1/(3r³) ∫_0^r c̄ r² dr`, `c̄ = c − c_ref`
- (S18) `dl_cr/dt = (1/t_0) dl_cr/dN = (k_cr/t_0) (σ_t b_cr √(π l_cr))^{m_cr}`, σ_t > 0
- (S19) `da_cr/dt = (a_± ρ_cr w_cr / t_0) · k_cr (σ_t b_cr √(π l_cr))^{m_cr}`, σ_t > 0
- (S20) `∂L_SEI,cr/∂t = c_int,Li/(2 L_SEI,cr) · D_int V̄_SEI · e^{−(φ_s−φ_e)} − (∂l_cr/∂t) · L_SEI,cr / l_cr`

### 4.4 LAM cơ học (SI Note 5, SI tr. 38) — giống O'Kane 2022

- (S21) `∂ε_a/∂t = (β/t_0) (σ_h/σ_c)^{m_2}`, σ_h > 0
- (S22) `σ_h = (σ_r + 2σ_t)/3`

### 4.5 Solvent consumption / dry-out (SI Note 6, SI tr. 39–43; Supplementary Table 4, SI tr. 21) — **MỚI so với O'Kane 2022** (từ Li et al. 2022, JES 169)

Giả thiết: có reservoir điện giải ngoài jelly roll; chỉ EC bị tiêu thụ; cài như "wrapper" cập nhật sau mỗi Δt, không thêm ODE.
- (S23) `2Li⁺ + 2EC + 2e⁻ ↔ (CH2OCO2Li)2 + C2H4`
- (S24) `dε_n/dt = −d(L_total · a_n)/dt`
- (S25) `L_total = L_SEI + 2 l_cr w_cr ρ_cr L_SEI,cr + c_Li V̄_Li/a_n + c_dl V̄_Li/a_n`
- (S26) `dV_pore = d ∫_0^{L_n} ε_n A_cell dx`
- (S27) `dn_EC = 2 dn_SEI = −2 d ∫ (L_SEI + 2 l_cr,n w_cr,n ρ_cr,n L_SEI,cr)/V̄_SEI · a_n A_cell dx`
- (S28) `dV_EC = dn_EC · V̄_EC`; (S29) `B_SEIcr = 2 V̄_EC (L_SEI + 2 l_cr,n w_cr,n ρ_cr,n L_SEI,cr)/V̄_SEI`; (S30) `dV_EC = −d ∫ B_SEIcr a_n A_cell dx`
- (S31) `dV_e^need = dV_pore − dV_EC`
- (S32) `dV_e = dV_EC + dV_e^add − dV_e^squeeze`; (S33) `dV_e^res = −dV_e^add + dV_e^squeeze`; (S34) `V_e(t) = V_pore(t)`; (S35)–(S36) cập nhật thể tích
- (S37) `R_dry = V_e(t+dt)/V_pore(t+dt)`; (S38) `A_cell(t+dt) = R_dry · A_cell(t)` → dry-out làm mất diện tích điện cực ⇒ LAM_NE = LAM_PE (tr. 6)
- (S39)–(S43) cập nhật nồng độ Li⁺ và EC trong reservoir và jelly roll; 5 trường hợp ở Supplementary Table 4.

### 4.6 Hysteresis zero-state (SI Note 7, SI tr. 44)

- (S46) `U_p^OCP = (1+tanh[100(J+0.2)])/2 · U_p,lith + (1−tanh[100(J+0.2)])/2 · U_p,delith`
- (S47) `U_n^OCP = (1−tanh[100(J+0.2)])/2 · U_n,lith + (1+tanh[100(J+0.2)])/2 · U_n,delith`
- J [A/m²]: mật độ dòng áp, dương khi xả; offset 0.2 A/m² để dùng nhánh xả khi nghỉ.

### 4.7 OCP mới (SI Note 8, SI tr. 45–46) — x là stoichiometry

- (Note 8, S1) `U_p,lith = −0.7983·x + 4.513 − 0.03269·tanh(19.83·(x−0.5424)) − 18.23·tanh(14.33·(x−0.2771)) + 18.05·tanh(14.46·(x−0.2776))`
- (S2) `U_p,delith = −0.7836·x + 4.513 − 0.03432·tanh(19.83·(x−0.5424)) − 19.35·tanh(14.33·(x−0.2771)) + 19.17·tanh(14.45·(x−0.2776))`
- (S3) `U_n,lith = 0.5476·e^{−422.4·x} + 0.5705·e^{−36.89·x} + 0.1336 − 0.04758·tanh(13.88·(x−0.2101)) − 0.01761·tanh(36.2·(x−0.5639)) − 0.0169·tanh(11.42·(x−1))`
- (S4) `U_n,delith = 1.051·e^{−26.76·x} + 0.1916 − 0.05598·tanh(35.62·(x−0.1356)) − 0.04483·tanh(14.64·(x−0.2861)) − 0.02097·tanh(26.28·(x−0.6183)) − 0.02398·tanh(38.1·(x−1))`
- Fit bằng MATLAB Curve Fitting Toolbox, RMSE < 8 mV, adjusted R² > 0.998 cho cả bốn (SI tr. 46).
- (S5) `∂U_p/∂T = 0.04006·exp(−(x−0.2828)²/0.0009855) − 0.06656·exp(−(x−0.8032)²/0.02179)`
- (S6) `∂U_n/∂T = −0.111·x + 0.02901 + 0.3562·exp(−(x−0.08308)²/0.004621)` (đơn vị ghi ở Table 6 là V/K — xem mục 9)

### 4.8 Initial SEI và porosity (SI Note 9, SI tr. 48–49)

- (S7) `L_SEI,0^inner = L_SEI,0^outer = L_SEIcr,0^inner = L_SEIcr,0^outer = 1800 · Q_loss,0/(F z_SEI) · V̄_SEI/(S_r a_n V_n)`, với `Q_loss,0 = 5 − 4.865 = 0.135 Ah`
- (S8) `S_r = 2 l_cr w_cr ρ_cr + 1`; (S9) `a_n = 3 ε_s,n/R_n`
- (S10) `Δε = 2 L_SEI,0^inner · S_r a = 3600 · Q_loss,0/(F z_SEI) · V̄_SEI/V`; (S11) `ε_n,0 = 0.25 − Δε`
- Ví dụ: V̄_SEI = 9.585·10⁻⁵ m³/mol → bốn độ dày ban đầu = 1.236·10⁻⁸ m, ε_n,0 = 0.222.

### 4.9 Điện giải (SI Note 10, SI tr. 50) — EC:EMC 3:7, Landesfeind & Gasteiger 2019

- (S12) `c_e^cor = c_e/1000` nếu c_e < 4000 mol/m³; `= 4` nếu c_e ≥ 4000
- (S13) `D_e = 10⁻¹⁰ · 1010 · e^{1.01·c_e^cor} · e^{−1560/T} · e^{c_e^cor·(−487)/T}` (xem mục 9: bản in ghi "10^10")
- (S14) `κ_e = 0.1 · 0.521 · (1 + (T−228)) · c_e^cor · (1 − 1.06√c_e^cor + 0.8353(1 − 0.00359 e^{1000/T}) c_e^cor) / (1 + (c_e^cor)⁴ · 0.00148 e^{1000/T})`
- (S15) `t_+^0 = −12.8 − 0.612 c + 0.0821 T + 0.904 c² + 0.0318 c T − 1.27·10⁻⁴ T² + 0.0175 c³ − 3.12·10⁻³ c² T − 3.96·10⁻⁵ c T²`
- (S16) `χ = 25.7 − 45.1 c − 0.177 T + 1.94 c² + 0.295 c T + 3.08·10⁻⁴ T² + 0.259 c³ − 9.46·10⁻³ c² T − 4.54·10⁻⁴ c T²` (c = c_e^cor)

### 4.10 Các hàm BOL khác (SI Note 11, SI tr. 51–52)

- (S17) `log10(D_s^ref/R_cor) = a0·x + b0 + a1·exp(−(x−b1)²/c1) + a2·exp(−(x−b2)²/c2) + a3·exp(−(x−b3)²/c3) + a4·exp(−(x−b4)²/c4)`
- (S18) `D_s = D_s^ref · exp(−E_act/R · (1/T − 1/T_ref))`
- (S19) `σ_s,p = 0.8473 · exp(−3500/R · (1/T − 1/298.15))`
- (S20) `θ̄ = ρ_s C_p,s ε_s + ρ_l C_p,l ε_l`
- (S21) `C_p,pos = −0.0008414 T³ + 0.7892 T² − 241.3 T + 2.508·10⁴`; (S22) `C_p,neg = 0.0004932 T³ − 0.491 T² + 169.4 T − 1.897·10⁴`; (S23) `C_p,sep = 0.001494 T³ − 1.444 T² + 475.5 T − 5.13·10⁴` (T [K])
- (S24) `λ_pos = 2.063·10⁻⁵ T² − 0.01127 T + 2.331`; (S25) `λ_neg = −2.61·10⁻⁴ T² + 0.1726 T − 24.49`
- (S26) `j_0,p = 5.028 · exp(−2.401·10⁴/R · (1/T − 1/298.15)) · (c_e/⟨c_e⟩)^0.57 · (c_s,surf/c_s,max)^0.43 · (1 − c_s,surf/c_s,max)^0.57`
- (S27) `j_0,n = 2.668 · exp(−4·10⁴/R · (1/T − 1/298.15)) · (c_e/⟨c_e⟩)^0.208 · (c_s,surf/c_s,max)^0.792 · (1 − c_s,surf/c_s,max)^0.208`

### 4.11 Degradation modes và chỉ số sai số

- (Note 12, S28–S36, SI tr. 53–54): `Ṽ = U_p(y) − U_n(x)`; `x = x_100 − Q/C_n`; `y = y_100 + Q/C_p`; `C = C_n(x_100 − x_0) = C_p(y_0 − y_100)`; `n_Li = 3600/F · (x_100 C_n + y_100 C_p)`; `LAM_NE = (1 − C_n/C_n,0)·100%`; `LAM_PE = (1 − C_p/C_p,0)·100%`; `LLI = (1 − n_Li/n_Li,0)·100%`.
- (Note 1, S1, SI tr. 32): `R_0.1s = (V_2 − V_1)/(I_2 − I_1)`.
- (bài chính, eq. 1, tr. 8): `MPE_tot = 1/2 MPE_SOH + 1/8 MPE_Res + 1/8 MPE_LLI + 1/8 MPE_LAMNE + 1/8 MPE_LAMPE`.
- Supplementary Table 2 (DFN) và Table 3 (thermal: `ρ C_p ∂T/∂t = ∇·(k∇T) + q_tot`, `q_tot = q_rev + q_j + q_r`, biên `−k ∂T/∂n = h(T − T_amb)`) ở SI tr. 19–20.

## 5. Bảng tham số — chép nguyên, kèm trạng thái

### 5.1 Table 3 (tr. 8) — tham số lão hoá được quét và giá trị khớp tốt nhất — trạng thái: **FITTED** (trial-and-error + Latin Hypercube trên Expt 2, không dùng thuật toán tối ưu)

| Ageing mechanism | Parameter | Unit | SEI only | SEI + Dry out | 5 coupled |
|---|---|---|---|---|---|
| SEI | Inner SEI lithium interstitial diffusivity (D_int) | m²/s | 2.36 × 10⁻¹⁸ | 1.2 × 10⁻¹⁸ | 9.81 × 10⁻¹⁹ |
| SEI | Inner or outer SEI partial molar volume (V̄_SEI^inner or V̄_SEI^outer) | m³/mol | 4 × 10⁻⁵ | 6.74 × 10⁻⁵ | 5.22 × 10⁻⁵ |
| SEI | SEI growth activation energy (E_act^SEI) | J/mol | 1 × 10⁴ | 1 × 10⁴ | 5 × 10³ |
| Lithium plating | Dead lithium decay constant (γ_0) | 1/s | – | – | 1 × 10⁻⁷ |
| Lithium plating | Lithium plating kinetic rate constant (k_Li) | m/s | – | – | 1 × 10⁻¹⁰ |
| LAM model | Positive electrode LAM constant proportional term (β_pos) | 1/s | – | – | 2.98 × 10⁻¹⁸ |
| LAM model | Negative electrode LAM constant proportional term (β_neg) | 1/s | – | – | 2.84 × 10⁻⁹ |
| Mechanical and cracking | Negative electrode cracking rate (k_cr^neg) | (không in đơn vị) | – | – | 5.29 × 10⁻²⁵ |
| DFN model | Negative electrode diffusivity activation energy (E_act^{Ds,n}) | J/mol | 6 × 10⁴ | 6 × 10⁴ | 2 × 10⁴ |

Số tham số quét: 4 (SEI only và SEI + Dry out), 9 (5 coupled) (tr. 8).

### 5.2 Supplementary Table 8 (SI tr. 26) — tham số lão hoá cực âm GIỮ NGUYÊN — trạng thái: **ASSUMED / lấy từ O'Kane 2022 hoặc tài liệu** (bài chỉ nói "sourced from O'Kane et al.", không ghi nguồn từng dòng)

| Ageing mechanism | Parameter | Unit | Value |
|---|---|---|---|
| SEI | Ratio of lithium moles to SEI moles (z_SEI) | – | 2 |
| SEI | Lithium interstitial reference concentration (c_int,Li) | mol/m³ | 15 |
| SEI | SEI resistivity (ρ_SEI) | Ω·m | 2 × 10⁵ |
| SEI | Inner SEI reaction proportion (α) | – | 0.5 |
| SEI | Initial inner SEI thickness (L_SEI,inner,0) | m | 1.23625 × 10⁻⁸ |
| SEI | Initial outer SEI thickness (L_SEI,outer,0) | m | 1.23625 × 10⁻⁸ |
| SEI (in lặp) | Initial Li⁺ concentration in electrolyte in the reservoir | mol/m³ | 1000 |
| SEI (in lặp) | Initial EC concentration in electrolyte in the reservoir | mol/m³ | 4541 |
| Solvent consumption | Initial Li⁺ concentration in electrolyte in the reservoir (c_Li+,0^res) | mol/m³ | 1000 |
| Solvent consumption | Initial excessive electrolyte amount | – | 1.0 |
| Solvent consumption | Initial EC concentration in electrolyte in the reservoir (c_EC,0^res) | mol/m³ | 4541 |
| Solvent consumption | EC partial molar volume (V̄_EC) | m³/mol | 6.667 × 10⁻⁵ |
| Lithium plating | Lithium plating transfer coefficient (α_a,Li) | – | 0.65 |
| Lithium plating | Initial plated lithium concentration (c_Li,0) | mol/m³ | 0 |
| Lithium plating | Lithium metal partial molar volume (V̄_Li) | m³/mol | 1.3 × 10⁻⁵ |

### 5.3 Supplementary Table 9 (SI tr. 27) — tham số lão hoá cả hai điện cực GIỮ NGUYÊN — trạng thái: **ASSUMED / từ O'Kane 2022**

| Ageing mechanism | Parameter | Unit | Positive | Negative |
|---|---|---|---|---|
| LAM model | LAM exponential term (m_2) | – | 2 | 2 |
| Mechanical and cracking | Electrode stress intensity factor correction (b_cr) | – | 1.12 | 1.12 |
| | Paris' law exponential term (m_cr) | | 2.2 | 2.2 |
| | Number of cracks per unit area (ρ_cr) | 1/m² | 3.18 × 10¹⁵ | 3.18 × 10¹⁵ |
| | Initial crack length (l_cr,0) | m | 2 × 10⁻⁸ | 2 × 10⁻⁸ |
| | Initial crack width (w_cr,0) | m | 1.5 × 10⁻⁸ | 1.5 × 10⁻⁸ |
| | Electrode critical stress (σ_c) | MPa | 375 | 60 |

### 5.4 Supplementary Table 6 (SI tr. 23–24) — tham số DFN + thermal. "Lấy từ O'Regan et al. trừ các mục có dấu *" — trạng thái: **MEASURED bởi O'Regan 2022**, dấu * = **đã đổi trong bài này**

| Parameter | Unit | Positive electrode | Separator | Negative electrode |
|---|---|---|---|---|
| Active material | | LixNi0.8Mn0.1Co0.1O2 | Ceramic coated polyolefin | LixC6 + SiOx |
| Current collector thickness (L_CC) | m | 1.6×10⁻⁵ | | 1.2×10⁻⁵ |
| Current collector conductivity (σ_CC) | S/m | 3.6914×10⁷ | | 5.8411×10⁷ |
| Current collector density (ρ_CC) | kg/m³ | 2700 | | 8960 |
| Current collector specific heat capacity (C_p,cc) | J/kg/K | 897 | | 385 |
| Current collector thermal conductivity (λ_cc) | W/m/K | 237 | | 401 |
| Electrode thickness (L) | m | 7.56×10⁻⁵ | 1.2×10⁻⁵ | 8.52×10⁻⁵ |
| Electrode length (w) | m | | 1.58 | |
| Electrode width (h) | m | | 6.5×10⁻² | |
| Cell cooling surface area (A_cool) | m² | | 5.31×10⁻³ | |
| Cell volume (V_cell) | m³ | | 2.42×10⁻⁵ | |
| Cell thermal expansion coefficient (α_th) | m/K | | 1.1×10⁻⁶ | |
| Total heat transfer coefficient (h_th) | W/m²/K | | 20 | |
| Mean particle radius (R_s) | m | 5.22×10⁻⁶ | | 5.86×10⁻⁶ |
| Electrolyte volume fraction (ε_e) | – | 0.335 | 0.47 | See Eq. (S11)* (= 0.25 − Δε) |
| Active material volume fraction (ε_s) | – | 0.665 | | 0.75 |
| Contact resistance (R_0) | mΩ | | 11.5 | |
| Bruggeman exponent (electrode) (b) | – | 0 | 1.5 | 0 |
| Bruggeman exponent (electrolyte) (b) | – | 1.5 | 1.5 | 1.5 |
| Solid phase lithium diffusivity (D_s) | m²/s | Eq. (S18) | | Eq. (S18) |
| Solid phase electronic conductivity (σ_s) | S/m | Eq. (S19) | | 215 |
| Density (wet, ρ_s+l) | kg/m³ | 3700 | 1548 | 2060 |
| Density (porous, ρ_s) | kg/m³ | 3270 | 1740 | 946 |
| Poisson's ratio (ν) | – | 0.2 | | 0.3 |
| Young's modulus (E) | GPa | 375 | | 15 |
| Reference concentration for free of deformation (c_ref) | mol/m³ | 0 | | 0 |
| Partial molar volume (Ω) | m³/mol | 1.25×10⁻⁵ | | 3.1×10⁻⁶ |
| Wet electrode specific heat capacity (θ̄) | J/kg/K | Eq. (S20) | | Eq. (S20) |
| Thermal conductivity (wet, λ) | W/m/K | Eq. (S24) | 0.3344 | Eq. (S24) |
| Maximum concentration (c_s^max) | mol/m³ | 52787* | | 32544* |
| Initial concentration (c_s^int) | mol/m³ | 12727* | | 28543* |
| Li⁺ diffusivity in the electrolyte (D_e) | m²/s | Eq. (S13)* | | |
| Electrolyte ionic conductivity (κ_e) | S/m | Eq. (S14)* | | |
| Cation transference number (t_+^0) | – | Eq. (S15)* | | |
| Thermodynamic factor (χ) | – | Eq. (S16)* | | |
| Initial Li⁺ concentration in electrolyte in the jelly roll (c_e,0) | mol/m³ | 1000 | | |
| Initial EC concentration in electrolyte in the jelly roll (c_EC,0) | mol/m³ | 4541 | | |
| Heat capacity of electrolyte (C_p,l) | (in "J/K/kg3") | 229 | | |
| OCPs | V | Eq. (S1), (S2) | | Eq. (S3), (S4)* |
| Entropy change (∂U/∂T) | V/K | Eq. (S5) | | Eq. (S6) |
| Exchange current density (j_0) | A/m² | Eq. (S26) | | Eq. (S27) |

Stoichiometry (SI tr. 46–47): cực âm 0.0279 (0% SOC) và 0.9014 → giảm xuống **0.8771** (100% SOC, để ra 4.865 Ah); cực dương **0.9256** (0%) và **0.2411** (100%). Kiểm tra: 0.8771 × 32544 = 28544 ≈ 28543 ✓; 0.2411 × 52787 = 12727 ✓.

### 5.5 Supplementary Table 7 (SI tr. 25) — hệ số hàm D_s (S17) — trạng thái: **từ O'Regan 2022**, riêng E_act cực âm **đã đổi (FITTED)**

| Fitting parameter | Positive electrode | Negative electrode |
|---|---|---|
| a0 | – | 11.17 |
| a1 | −0.9231 | −1.553 |
| a2 | −0.4066 | −6.136 |
| a3 | −0.993 | −9.725 |
| a4 | – | 1.85 |
| b0 | −13.96 | −15.11 |
| b1 | 0.3216 | 0.2031 |
| b2 | 0.4532 | 0.5375 |
| b3 | 0.8098 | 0.9144 |
| b4 | – | 0.5953 |
| c1 | 0.002534 | 0.0006091 |
| c2 | 0.003926 | 0.06438 |
| c3 | 0.09924 | 0.0578 |
| c4 | – | 0.001356 |
| E_act | 12000 | xem Table 3 bài chính* (6×10⁴ hoặc 2×10⁴ J/mol) |
| R_cor | 2.7 | 3.0321 |

### 5.6 Quét năng lượng hoạt hoá (SI Note 13, SI tr. 55)

E_act^SEI ∈ {5×10², 5×10³, 5×10⁴} J/mol × E_act^{Ds,n} ∈ {2×10⁴, 4×10⁴, 6×10⁴} J/mol (9 tổ hợp). Tổ hợp tái hiện được dạng chữ V bất đối xứng của capacity loss theo nhiệt độ: SEI only — (5×10³, 2×10⁴), (5×10³, 4×10⁴), (1×10⁴, 6×10⁴); 5 coupled — (5×10³, 2×10⁴), (5×10³, 4×10⁴).

## 6. Sai số fit và validation (chép nguyên)

### Table 1 (tr. 3) — MPE đường áp C/10, trung bình 13 RPT, Expt 2 (fit)

| Model | T / °C | Mean MPE / % | Std of MPE / % |
|---|---|---|---|
| SEI only | 10 | 0.72 | 0.08 |
| SEI only | 25 | 0.70 | 0.08 |
| SEI only | 40 | 0.80 | 0.07 |
| SEI + Dry out | 10 | 0.58 | 0.11 |
| SEI + Dry out | 25 | 0.32 | 0.18 |
| SEI + Dry out | 40 | 0.63 | 0.18 |
| 5 coupled | 10 | 0.44 | 0.13 |
| 5 coupled | 25 | 0.48 | 0.18 |
| 5 coupled | 40 | 0.52 | 0.20 |

### Supplementary Table 1 (SI tr. 18) — RMSE đường áp C/10, Expt 2 (fit)

| Model | T / °C | Mean RMSE / mV | Std / mV |
|---|---|---|---|
| SEI only | 10 | 34.91 | 5.35 |
| SEI only | 25 | 31.42 | 4.16 |
| SEI only | 40 | 39.39 | 4.42 |
| SEI + Dry out | 10 | 32.40 | 5.23 |
| SEI + Dry out | 25 | 29.26 | 8.51 |
| SEI + Dry out | 40 | 35.18 | 9.72 |
| 5 coupled | 10 | 23.29 | 7.10 |
| 5 coupled | 25 | 25.31 | 9.75 |
| 5 coupled | 40 | 28.45 | 10.17 |

### Table 2 (tr. 4) — MPE các chỉ số, Expt 2 (70–85%, fit)

| Model | T / °C | MPE_SOH / % | MPE_Res / % | MPE_LLI / % | MPE_LAMNE / % | MPE_LAMPE / % | MPE_tot / % |
|---|---|---|---|---|---|---|---|
| SEI only | 10 | 0.83 | 4.41 | 44.45 | 100.00 | 100.00 | 31.52 |
| SEI only | 25 | 0.15 | 5.74 | 41.69 | 100.00 | 100.00 | 31.00 |
| SEI only | 40 | 0.86 | 3.77 | 45.86 | 100.00 | 100.00 | 31.63 |
| SEI + Dry out | 10 | 0.87 | 6.13 | 36.25 | 53.57 | 35.88 | 16.91 |
| SEI + Dry out | 25 | 0.32 | 4.05 | 33.84 | 38.17 | 32.89 | 13.78 |
| SEI + Dry out | 40 | 0.86 | 5.77 | 37.56 | 44.36 | 24.45 | 14.45 |
| 5 coupled | 10 | 0.42 | 4.49 | 25.10 | 37.64 | 27.02 | 11.99 |
| 5 coupled | 25 | 0.88 | 5.50 | 22.75 | 20.58 | 30.94 | 10.41 |
| 5 coupled | 40 | 0.57 | 3.68 | 31.58 | 34.18 | 24.64 | 12.05 |

Tổng MPE_tot ba nhiệt độ: 5 coupled 34.45%; SEI + Dry out 45.14% (tr. 4).

### Supplementary Table 10 và 11 (SI tr. 28–29) — đường áp C/10, Expt 3 (85–100%, VALIDATION)

| Model | T / °C | Mean RMSE / mV | Std / mV | Mean MPE / % | Std / % |
|---|---|---|---|---|---|
| SEI only | 10 | 124.58 | 62.42 | 2.80 | 1.42 |
| SEI only | 25 | 89.35 | 36.86 | 1.96 | 0.78 |
| SEI only | 40 | 62.17 | 31.09 | 1.41 | 0.69 |
| SEI + Dry out | 10 | 119.96 | 58.57 | 2.63 | 1.31 |
| SEI + Dry out | 25 | 85.64 | 33.49 | 1.80 | 0.68 |
| SEI + Dry out | 40 | 56.49 | 27.59 | 1.22 | 0.58 |
| 5 coupled | 10 | 109.42 | 55.22 | 2.45 | 1.25 |
| 5 coupled | 25 | 72.58 | 27.54 | 1.59 | 0.57 |
| 5 coupled | 40 | 44.20 | 19.81 | 1.01 | 0.45 |

### Supplementary Table 12 (SI tr. 30) — MPE các chỉ số, Expt 3 (VALIDATION) — chép NGUYÊN NHƯ IN (nhãn cột Model/T có vẻ in sai, xem mục 9)

| Model (như in) | T / °C (như in) | MPE_SOH | MPE_Res | MPE_LLI | MPE_LAMNE | MPE_LAMPE | MPE_tot |
|---|---|---|---|---|---|---|---|
| SEI only | 10 | 7.14 | 7.36 | 54.8 | 100 | 100 | 36.3 |
| SEI only | 10 | 7.19 | 6.22 | 48.9 | 83.06 | 67.03 | 29.2 |
| SEI only | 10 | 5.3 | 6.95 | 38.1 | 81.06 | 61.45 | 26.1 |
| SEI + Dry out | 25 | 4.02 | 3.14 | 49.51 | 100.00 | 100.00 | 33.59 |
| SEI + Dry out | 25 | 4.06 | 1.85 | 42.38 | 53.44 | 60.34 | 21.78 |
| SEI + Dry out | 25 | 2.44 | 2.64 | 28.67 | 32.63 | 54.58 | 16.04 |
| 5 coupled | 40 | 1.98 | 6.07 | 42.58 | 100.00 | 100.00 | 32.07 |
| 5 coupled | 40 | 1.97 | 4.22 | 33.08 | 40.24 | 38.39 | 15.47 |
| 5 coupled | 40 | 0.75 | 5.86 | 22.67 | 19.82 | 33.32 | 10.58 |

Cách đọc hợp lý nhất (suy luận của người tóm tắt): ba khối là 10 / 25 / 40 °C, trong mỗi khối thứ tự là SEI only / SEI + Dry out / 5 coupled. Căn cứ: (i) LAM = 100% chỉ có thể là SEI only, và xuất hiện ở dòng đầu mỗi khối; (ii) bài chính tr. 5 ghi 5 coupled ở 40 °C có MPE_tot = 10.58% = dòng cuối. Khi đó 5 coupled: MPE_tot = 26.1% (10 °C), 16.04% (25 °C), 10.58% (40 °C).

Nhận xét của tác giả về validation (tr. 5): 5 coupled dự đoán tốt cả 5 chỉ số ở 40 °C; kém hơn ở 25 °C; **"completely failed at 10 °C"**.

Chi phí tính: 5 coupled cần trung bình 16 h (4 GB RAM, 2 CPU) cho một lần chạy; ở 10 °C có thể > 72 h (tr. 8) — bằng PyBaMM.

## 7. Dữ liệu / mã nguồn (ghi nhận, KHÔNG tính là đã đọc)

- **Zenodo https://doi.org/10.5281/zenodo.14995785** (09/03/2025, CC BY 4.0): `Source_Data.zip` (10.8 MB — số liệu của mọi hình), `Scripts_to_reproduce_paper.zip` (2.6 MB — script PyBaMM, chứa cài đặt thật của eq. SEI), `Experiment Data, long simulation data and saved figures in the paper.zip` (835 MB). Bài ghi script theo CC BY 4.0 (tr. 8).
- Dữ liệu thí nghiệm gốc: Zenodo 10.5281/zenodo.10637534 (Kirkaldy 2024, CC BY 4.0).
- Peer review file có trên trang Nature (chưa đọc).
- Preprint: arXiv:2311.05482 (chưa đọc).

## 8. Không có dạng số (chỉ có hình)

- SOH, R0.1s, LLI, LAM_NE, LAM_PE thực nghiệm và mô phỏng theo charge throughput cho Expt 2 (Fig. 3, 4) và Expt 3 (Fig. 6).
- So sánh trực tiếp Expt 2 vs Expt 3 tại 6.37 kAh: SOH loss, LLI, R0.1s, LAM_NE, LAM_PE (SI Fig. 6) — đây chính là số "phụ thuộc SOC window", chỉ ở dạng cột.
- Đóng góp từng cơ chế vào LLI/LAM (SI Fig. 3, 5).
- Kết quả thất bại với Expt 1 và Expt 5 ở 40 °C (SI Fig. 7).
- Đường OCP mới so với Chen 2020 (SI Fig. 10), tính chất điện giải (SI Fig. 11), D_s theo stoichiometry (SI Fig. 12), bản đồ E_act (SI Fig. 13), validation GITT (SI Fig. 14), hysteresis (SI Fig. 9), DVA (Fig. 5, SI Fig. 4).
- Số liệu của các hình này có trong `Source_Data.zip` (chưa mở).

## 9. Mâu thuẫn / KHÔNG RÕ

1. **Số mũ SEI không có F/(RT)** — (S2), (S6), (S7), (S20). Xem mục 4.1. KHÔNG RÕ dạng thực dùng.
2. **Supplementary Table 12 in sai nhãn** cột Model và T (mục 6).
3. **V̄_SEI vs độ dày SEI ban đầu:** SI Note 9 nói V̄_SEI là tham số tuning và làm thay đổi L_SEI,0 và ε_n,0; ví dụ V̄_SEI = 9.585·10⁻⁵ cho 1.236·10⁻⁸ m. Nhưng Table 8 liệt kê L_SEI,inner,0 = L_SEI,outer,0 = 1.23625·10⁻⁸ m là "unchanged", trong khi V̄_SEI fit = 4×10⁻⁵ / 6.74×10⁻⁵ / 5.22×10⁻⁵. KHÔNG RÕ giá trị L_SEI,0 và ε_n,0 thực dùng cho từng mô hình (phải tính lại bằng S7, S10, S11 — nhưng V_n và S_r phụ thuộc cách hiểu).
4. **α_a,Li = 0.65** ở Table 8, trong khi O'Kane 2022 ghi α_a,Li = 0.35, α_c,Li = 0.65. KHÔNG RÕ là đổi giá trị hay ghi nhầm nhãn; α_c,Li không được liệt kê.
5. **Đơn vị β** ghi 1/s trong khi (S21) viết β/t_0; đơn vị k_cr không in; **t_0** ("time for one cycle") không có giá trị. Nhiều khả năng giá trị β [1/s] đã gộp 1/t_0 (suy luận) — KHÔNG RÕ.
6. **β_pos = 2.98×10⁻¹⁸ 1/s** nhỏ hơn β_neg 9 bậc → LAM_PE do ứng suất gần như bằng 0; LAM_PE mô phỏng thực chất đến từ dry-out (LAM_NE = LAM_PE). Bài không bình luận trực tiếp.
7. **Supplementary Table 5** ghi cột "Current (discharge/charge)" = 0.3C/1C; theo Kirkaldy 2024 thì 0.3C là SẠC, 1C là XẢ.
8. SI tr. 46–47: câu "maximum lithium concentration of 32544 mol/m³ in the negative electrode" lặp lại ở đoạn nói về cực dương — hẳn phải là 52787 mol/m³ (cực dương).
9. SI tr. 46 trích "Eq. (S26)" cho phép bisection OCP — tham chiếu sai (S26 là exchange current); (Note 12) trích "Eq. (S78)" không tồn tại.
10. (S13) in "10⁻¹⁰ · 10¹⁰ · e^{…}" (text trích xuất: "10−10 ∙1010"); theo trí nhớ của người tóm tắt (chưa kiểm chứng), dạng gốc Landesfeind–Gasteiger có tiền tố 1010 → nhiều khả năng đọc là `1010 × 10⁻¹⁰`. KHÔNG RÕ nếu chỉ dựa vào bản in.
11. (S14) in "(1 + (T − 228))" — KHÔNG RÕ có thiếu hệ số hay không (không đối chiếu được với nguồn gốc).
12. Đơn vị ∂U/∂T ghi V/K; hệ số (S5), (S6) cỡ 0.03–0.36 → gần như chắc là mV/K (như O'Regan 2022). KHÔNG RÕ.
13. Young's modulus cực dương 375 GPa và σ_c cực dương 375 MPa: O'Kane 2022 đã tự nhận E của NMC811 "set too high"; bài này giữ nguyên.
14. Table 9: dòng "Number of cracks per unit area" gắn ký hiệu ρ_cr^neg, "Initial crack length/width" gắn ^pos, nhưng cho giá trị cả hai cực.
15. Contact resistance R_0 = 11.5 mΩ và h_th = 20 W/m²/K: không có trong O'Regan 2022 (h = 15, chỉnh tay) → là giá trị riêng của bài này, không đánh dấu *. Trạng thái: KHÔNG RÕ (nhiều khả năng chỉnh tay).
16. Số RPT dùng cho validation Expt 3: KHÔNG RÕ.
17. "No optimisation methods have been used" → bộ tham số không duy nhất (tr. 6, 8).
18. SI tr. 55 trích "Supplementary Figure 14/15" cho phân rã LLI, nhưng Fig. 14/15 trong SI là GITT và MPE — đánh số hình lệch.

## 10. Khớp với 5 bài cũ

- **Cùng cell: CÓ** — LG M50T (LG GBM50T2170), NMC811 / graphite-SiOx, 5 Ah. Cùng nhóm, O'Kane là đồng tác giả.
- **Bộ tham số nền: O'Regan 2022** (D_s phụ thuộc stoichiometry và nhiệt độ, j_0 dạng (S26)/(S27), nhiệt dung, dẫn nhiệt, entropy), KHÔNG phải bộ Chen 2020 thuần. Chen 2020 chỉ còn dùng cho giới hạn stoichiometry cực âm (0.0279, 0.9014). Bài nói rõ O'Regan có "temperature dependency of many parameters that were not included in O'Kane et al.'s model" (tr. 7).
- **Phương trình so với O'Kane 2022:**
  - THAY: SEI solvent-diffusion limited → interstitial-diffusion limited, 2 lớp inner/outer (Note 2, S2–S9); SEI-on-cracks cũng đổi (Note 4, S20).
  - THÊM: solvent consumption / dry-out với reservoir (Note 6, S23–S43); hysteresis OCP (Note 7); mô hình nhiệt lumped; D_s(x, T); giới hạn bão hoà muối 4000 mol/m³ (S12).
  - GIỮ NGUYÊN: lithium plating bán thuận nghịch (S10–S13), stress (S14–S17), Paris' law cracking (S18–S19), LAM (S21–S22).
- **Giá trị KHÁC với Chen 2020 / O'Kane 2022 / O'Regan 2022** (so với các file tham_so đã có):

| Tham số | Li 2025 | Bài cũ |
|---|---|---|
| c_s,max cực dương | 52787 mol/m³ | Chen 2020: 51765 (63104 sau chỉnh) |
| c_s,max cực âm | 32544 mol/m³ | Chen 2020: 29583 (33133 sau chỉnh) |
| Stoichiometry cực dương 0% / 100% | 0.9256 / 0.2411 | Chen 2020: 0.9084 / 0.2661 (0.27 sau chỉnh) |
| Stoichiometry cực âm 100% | 0.8771 | Chen 2020: 0.9014 |
| OCP hai cực | (Note 8, S1–S4), có nhánh lith/delith | Chen 2020 eq. 8–9 (một nhánh) |
| Điện giải | EC:EMC 3:7, Landesfeind–Gasteiger (S13–S16) | Chen 2020: Nyman |
| ε_e cực âm | 0.25 − Δε (≈ 0.222 trong ví dụ) | Chen 2020: 0.25 |
| E_act của D_s,n | 2×10⁴ (5 coupled) hoặc 6×10⁴ J/mol | O'Kane 2022: 30300 J/mol |
| E_act của D_s,p | 12000 J/mol | O'Kane 2022: 25000 J/mol |
| h | 20 W/m²/K | O'Regan 2022: 15 W/m²/K (chỉnh tay) |
| Contact resistance | 11.5 mΩ | (không có trong ghi chú bài cũ) |
| SEI: tham số tốc độ | D_int = 9.81×10⁻¹⁹ m²/s, c_int = 15 mol/m³ | O'Kane 2022: D_sol = 2.5×10⁻²² m²/s, c_sol,0 = 2636 mol/m³ |
| E_act của SEI | 5×10³ J/mol (5 coupled) | O'Kane 2022: E_sol = 37000 J/mol |
| V̄_SEI | 5.22×10⁻⁵ m³/mol (5 coupled) | O'Kane 2022: 9.585×10⁻⁵ |
| L_SEI,0 | 1.23625×10⁻⁸ m mỗi lớp (2 lớp) | O'Kane 2022: 5×10⁻⁹ m (1 lớp) |
| k_Li | 1×10⁻¹⁰ m/s | O'Kane 2022: 10⁻⁹ (assumed) |
| γ_0 | 1×10⁻⁷ 1/s | O'Kane 2022: 10⁻⁶ (assumed) |
| k_cr cực âm | 5.29×10⁻²⁵ | O'Kane 2022: 3.9×10⁻²⁰ |
| β cực âm / dương | 2.84×10⁻⁹ / 2.98×10⁻¹⁸ 1/s | O'Kane 2022: 0.001 / 0.001 (đơn vị không ghi) |
| l_cr,0 ; w_cr | 2×10⁻⁸ m ; 1.5×10⁻⁸ m | ghi chú O'Kane 2022: 2×10⁻⁵ ; 1.5×10⁻⁵ (đã bị nghi là vô lý vì > bán kính hạt) |
| ρ_SEI, ρ_cr, b_cr, m_cr, m_2, σ_c, E, ν, Ω | giống | giống O'Kane 2022 |

- **Hệ quả:** các tham số lão hoá fit ở Table 3 chỉ nhất quán khi đi cùng bộ BOL của bài này (O'Regan + OCP mới + stoichiometry mới + E_act^{Ds,n} đã đổi). Nếu đồ án giữ DFN theo Chen 2020 thì D_int phải coi là **giá trị khởi đầu cần hiệu chỉnh lại**, không phải giá trị đã validate — vì tốc độ SEI phụ thuộc hàm mũ vào thế cực âm, mà thế này thay đổi theo OCP/stoichiometry/D_s.
- **Tham số vẫn phải GIẢ ĐỊNH (gắn cờ) nếu dùng bài này:**
  1. Dạng chính xác của số mũ SEI (F/RT; có trừ η_SEI hay không) — cho tới khi đối chiếu code Zenodo.
  2. L_SEI,0 và ε_n,0 ứng với V̄_SEI đã fit (mâu thuẫn 3).
  3. α_c,Li (không liệt kê) và ý nghĩa α_a,Li = 0.65.
  4. t_0 và đơn vị của β, k_cr.
  5. Thể tích reservoir tuyệt đối ("initial excessive electrolyte amount = 1.0" không có đơn vị/định nghĩa trong SI) nếu cài dry-out.
  6. Điều kiện nhiệt của đề tài (h, diện tích, T_amb) — bài dùng base-cooling với h = 20.
  7. Toàn bộ cơ chế mất silicon ở SOC thấp — bài KHÔNG có; mọi window chạm 0% SOC nằm ngoài vùng mô hình đã kiểm chứng.
  8. Mọi tham số plating (k_Li, γ_0) chỉ được ràng buộc bởi dữ liệu sạc 0.3C → ngoại suy sang dòng sạc lớn là giả định.

## 11. Đánh giá mức liên quan

**Liên quan cao — đây là tài liệu (b), thay được mô hình SEI của O'Kane 2022.**

- Dùng được ngay: eq. SEI interstitial-diffusion limited (S2–S9) với c_int,Li = 15 mol/m³ và D_int, V̄_SEI, E_act^SEI ở Table 3; giữ plating/stress/LAM của O'Kane nhưng với giá trị fit mới. Phương án gọn cho MATLAB: mô hình **"SEI only"** (D_int = 2.36×10⁻¹⁸ m²/s, V̄_SEI = 4×10⁻⁵ m³/mol, E_act^SEI = 1×10⁴ J/mol, E_act^{Ds,n} = 6×10⁴ J/mol) — khớp SOH với MPE 0.15–0.86% ở 70–85% nhưng đánh giá thấp LLI ~42–46% và không có LAM; hoặc **"5 coupled"** nếu chấp nhận cài LAM + cracking + plating + dry-out.
- Giới hạn bắt buộc phải nêu: (i) fit trên MỘT window (70–85%), validate trên MỘT window (85–100%), cả hai ở 0.3C sạc; (ii) validation chỉ tốt ở 40 °C (MPE_tot 10.58%), kém ở 25 °C, hỏng ở 10 °C; (iii) thất bại ở 0–30% và 0–100%; (iv) không dùng thuật toán tối ưu, tham số không duy nhất; (v) bộ BOL là O'Regan 2022 đã chỉnh, không phải Chen 2020.
- Với mục tiêu đề tài (so profile I(t) tối ưu với CCCV theo từng window): mô hình cho phụ thuộc đúng hướng vào thế cực âm nên phân biệt được window và dạng dòng, nhưng kết luận định lượng chỉ đáng tin trong dải SOC trung–cao (≈70–100%) ở nhiệt độ ấm; các window thấp là ngoại suy.

## 12. Ghi chú: ứng viên thứ tư đã đọc nhưng KHÔNG chọn (không lưu file)

M. P. Bonkile, Y. Jiang, N. Kirkaldy, V. Sulzer, R. Timms, H. Wang, G. Offer, B. Wu, "Is silicon worth it? Modelling degradation in composite silicon–graphite lithium-ion battery electrodes", *J. Power Sources* **606** (2024) 234256, DOI https://doi.org/10.1016/j.jpowsour.2024.234256, open access CC BY (bản PDF có ở Spiral: hdl.handle.net/10044/1/110966). Đã đọc toàn văn + SI (8 trang).
- Cùng cell LG M50T, bộ nền Chen 2020 + composite electrode của Ai et al. 2022 (hai loại hạt Gr và Si chung thế bề mặt; eq. 5–11), stress/cracking/LAM kiểu O'Kane cho từng pha (eq. 12–14), SEI **solvent-diffusion limited** (eq. 15–21) — tức KHÔNG phụ thuộc SOC. Dữ liệu: 0–30% và 0–100% ở 25 °C, 0.3C/1C (3 và 2 cell).
- Số trong văn bản: LAM_NE ~21% và LAM_PE ~6.7% tại 9.5 kAh (0–100%); LAM_Si ở 0–30% "approximately doubles" so với 0–100%; ~80% LAM_Si ở EoL; σ_c của Si = 0.72 GPa; composite cell tụt dưới cell thuần graphite sau 7 kAh.
- Lý do không chọn: (i) các tham số được "estimated" cho Si (β_Si, cracking rate) và D_sol **không được in giá trị** (SI Table 1 chỉ có k_cr = 3.9×10⁻²⁰ cho mọi pha; "Data will be made available on request"); (ii) không có sai số validation dạng số; (iii) SI có lỗi rõ (E_Ds ghi "3.03×10⁻⁴ J/mol"; Ω cực dương 1.25×10⁻⁶ thay vì 1.25×10⁻⁵); (iv) cần đổi cực âm sang mô hình hai pha — vượt phạm vi đồ án MATLAB. Nên trích nếu đề tài muốn mô hình hoá mất silicon ở các window chạm 0% SOC; khi đó β_Si, k_cr,Si là tham số GIẢ ĐỊNH.
