# Chen et al. 2020 — Tham số P2D cho cell LG M50 (21700)

**Trích dẫn:** C.-H. Chen, F. Brosa Planella, K. O'Regan, D. Gastol, W. D. Widanage, E. Kendrick, "Development of Experimental Techniques for Parameterization of Multi-scale Lithium-ion Battery Models", *J. Electrochem. Soc.* **167**, 080534 (2020). DOI: 10.1149/1945-7111/ab9050. Giấy phép bài báo: CC BY-NC-ND 4.0 (PDF tr. 2).

**Quy ước số trang:** "tr. N" = số trang của file PDF `Chen2020_JES.pdf` (23 trang; trang 1 là trang bìa IOP, nên trang 1 của bài báo = PDF tr. 2; trang bài báo = N − 1). Bài báo không in số trang trên từng trang.

**Phương pháp trích xuất:** đọc toàn văn `toan_van_trich_xuat/Chen2020.txt` (tất cả 23 trang). Các trang có công thức/bảng bị vỡ trong file txt (tr. 5, 6, 7, 8, 13, 14, 17, 18, 19) đã được render lại bằng PyMuPDF và đọc trực tiếp để chép đúng ký hiệu. Không có giá trị nào được đọc từ đồ thị.

---

## 1. Hệ phương trình P2D (Table I, tr. 6)

Chỉ số k ∈ {p, s, n} (điện cực dương, separator, điện cực âm). Mô hình **đẳng nhiệt**, T = 298.15 K (tr. 6). F: hằng số Faraday, R: hằng số khí. Mốc điện thế: φ_{s,n}|_{x=0} = 0 (tr. 6). Tại các mặt phân cách x = L_n và x = L − L_p áp đặt liên tục của nồng độ, điện thế, thông lượng mol và dòng (tr. 6, chỉ nêu bằng lời, không viết trong Table I).

**Điện cực (Electrodes)**

| Mô tả | Phương trình | Điều kiện biên |
|---|---|---|
| Mass conservation (rắn) | ∂c_{s,k}/∂t = (1/r²) ∂/∂r ( r² D_{s,k} ∂c_{s,k}/∂r ) | ∂c_{s,k}/∂r \|_{r=0} = 0 ;  −D_{s,k} ∂c_{s,k}/∂r \|_{r=R_k} = J_k / (a_k F) |
| Charge conservation (rắn) | ∂/∂x ( σ_{s,k} ∂φ_{s,k}/∂x ) = J_k | −σ_{s,n} ∂φ_{s,n}/∂x \|_{x=0} = −σ_{s,p} ∂φ_{s,p}/∂x \|_{x=L} = i_app ;  −σ_{s,n} ∂φ_{s,n}/∂x \|_{x=L_n} = −σ_{s,p} ∂φ_{s,p}/∂x \|_{x=L−L_p} = 0 |

**Điện giải (Electrolyte)**

| Mô tả | Phương trình | Điều kiện biên |
|---|---|---|
| Mass conservation | ε_k ∂c_{e,k}/∂t = ∂/∂x ( ε_k^b D_e ∂c_{e,k}/∂x ) + (1 − t⁺) J_k / F | ∂c_{e,n}/∂x \|_{x=0} = ∂c_{e,p}/∂x \|_{x=L} = 0 |
| Charge conservation | ∂/∂x ( ε_k^b σ_{e,k} ( ∂φ_{e,k}/∂x − (2(1 − t⁺) R T / F) ∂ log c_{e,k}/∂x ) ) = −J_k | ∂φ_{e,n}/∂x \|_{x=0} = ∂φ_{e,p}/∂x \|_{x=L} = 0 |

**Động học phản ứng (Reaction kinetics)**

- Butler–Volmer (chép **đúng như in**): J_k = a_k j_{0,k} sinh( (1/2)(R T / F) η_k ) với k ∈ {n, p}; J_k = 0 với k = s.
- Exchange current: j_{0,k} = k_k √( c_{e,k} c_{s,k} (c_{s,k}^max − c_{s,k}) ) |_{r=R_k}
- Overpotential: η_k = φ_{s,k} − φ_{e,k} − U_k( c_{s,k}|_{r=R_k} ), k ∈ {n, p}

**Điều kiện đầu:** c_{s,k} = c_{k0}, c_{e,k} = c_{e0}.

**Điện áp đầu cực (chép đúng như in):** V = φ_{e,p}|_{x=L} − φ_{e,n}|_{x=0}.

> **Ghi chú / KHÔNG RÕ (lỗi in có khả năng trong Table I):**
> 1. Trong BV, đối số sinh in là (1/2)(RT/F)η — sai thứ nguyên; dạng chuẩn đối xứng (α = 0.5, tr. 5 "we assume the reaction to be symmetric") phải là (1/2)(F/(RT))η. Bài cũng không có hệ số 2 trước a_k j_0 (dạng thường gặp là 2 a j_0 sinh(...)). Không thể xác định từ bài báo dạng nào PyBaMM v0.2.0 thực sự dùng → **KHÔNG RÕ**, cần đối chiếu mã nguồn PyBaMM hoặc O'Kane 2022.
> 2. Điện áp đầu cực in bằng φ_e; về vật lý phải là φ_{s,p}|_{x=L} − φ_{s,n}|_{x=0}. Coi là lỗi in.
> 3. D_e trong phương trình khối lượng điện giải không có chỉ số k, trong khi σ_{e,k} có; Bruggeman áp dụng dạng ε_k^b cho cả hai.
> 4. Không có hệ số hoạt độ (thermodynamic factor) — giả thiết điện giải lý tưởng (tr. 18).

Các phương trình phụ trợ trong văn bản:
- (1) ρ = (π t / ln 2)(V / I), độ dẫn điện σ = 1/ρ, đo 4 mũi dò (tr. 5).
- (2) ε = 1 − ε_act = 1 − M_coat / (L ρ) (tr. 7).
- (3) τ = ε^{1−b} (Bruggeman) (tr. 8).
- (4) x = c_s / c_s^max (tr. 11).
- (5) c_s^max = M_coat z / (m_a L ε_act); (6) c_s^max = ρ z / m_a; (7) c_s^max = Q / (F L ε_act) (tr. 13).
- (10) S = n SA_particle = (ε_act V_electrode / V_particle) SA_particle (tr. 14).
- (11) c_surf = c_0 + 2 I/(S F √(D_s π)) √t; (12) V = U(c_0) + (c_surf − c_0)U′(c_0) − R_IR I; (13) V = U(c_0) − R_IR I + 2 U′(c_0) I/(S F √(D_s π)) √t; (14) D_s = (4/π)( I U′(c_0) / (F S m_fit) )² (tr. 14).
- (15) j = j_0 { exp[α F η/(RT)] − exp[−(1−α) F η/(RT)] }; (16) j = j_0 F η/(RT); (17) η = j S R_ct; (18) R_ct = R T/(j_0 S F) (tr. 16–17).
- (19) j_0 = k √( c_e c_s (c_s^max − c_s) ) (α = 0.5); (20) k = 2 j_0 / (c_s^max √c_e) (với c_s = c_s^max/2 ở 50% SOC); (21) j_0 = k̂ F c_s^max √(c_e/c_{e,ref}) √( (c_s/c_s^max)(1 − c_s/c_s^max) ); (22) k̂ = k √c_{e,ref} / F (tr. 17).
- (26) a_k = 3 ε_{act,k} / R_k (tr. 18).

Lời giải số (tr. 6–7): PyBaMM v0.2.0, finite volume, 10 điểm/hạt, 20 điểm/điện cực, 20 điểm separator (đã thử tới 40/80/80, không khác biệt đáng kể); solver CasADi; 461 ODE + 101 phương trình đại số; ~20 s mỗi mô phỏng xả + nghỉ.

---

## 2. Table VII — Parameter set for the Newman P2D model (tr. 19, chép nguyên văn)

Bảng gốc **không có cột nguồn/phương pháp**. Cột "Nguồn trong bài" dưới đây do tôi thêm (chỉ vị trí trong văn bản), không phải một phần của Table VII.

| Nhóm | Parameter | Unit | Positive electrode (k = p) | Separator (k = s) | Negative electrode (k = n) | Nguồn trong bài (thêm) |
|---|---|---|---|---|---|---|
| — | Active material | | LiNi_{1−x−y}Mn_xCo_yO_2 | Ceramic coated polyolefin^a) | Graphite + silicon | ICP-OES/EDS, tr. 8–9 |
| Design specifications | Current collector thickness | m | 16·10⁻⁶ | — | 12·10⁻⁶ | đo, tr. 7 (Table II ghi 16.3 / 11.7 μm) |
| | Electrode thickness (L_k) | m | 75.6·10⁻⁶ | 12·10⁻⁶ | 85.2·10⁻⁶ | đo bằng length gauge, tr. 4, 7 |
| | Electrode length | m | 1.58 | | | Table II (79+79 cm), tr. 6 |
| | Electrode width | m | 6.5·10⁻² | | | Table II, tr. 6 |
| | Mean particle radius (R_k) | m | 5.22·10⁻⁶ | — | 5.86·10⁻⁶ | SEM + ImageJ, tr. 7 |
| | Electrolyte volume fraction (ε_k) | % | 33.5 | 47 | 25 | trung bình mật độ & FIB-SEM, tr. 7–8 |
| | Active material volume fraction (ε_{act,k}) | % | 66.5 | — | 75 | = 1 − ε_k (eq. 2) |
| | Bruggeman exponent (b) | — | 2.43 | 2.57 | 2.91 | FIB-SEM tortuosity + eq. 3, tr. 8 |
| Electrode | Solid phase lithium diffusivity (D_{s,k}) | m² s⁻¹ | 1.48·10⁻¹⁵ | — | 1.74·10⁻¹⁵ | GITT + Sand eq., Table V, tr. 15 |
| | Solid phase electronic conductivity (σ_{s,k}) | S m⁻¹ | 0.18 | — | 215 | 4-point probe, tr. 10 |
| | Maximum concentration (c_{s,k}^max) | mol m⁻³ | 51765 | — | 29583 | eq. 5 / eq. 7, tr. 13 |
| | Stoichiometry at 0% SOC | — | 0.9084 | — | 0.0279 | GITT-OCV balancing, tr. 13 |
| | Stoichiometry at 100% SOC | — | 0.2661 | — | 0.9014 | GITT-OCV balancing, tr. 13 |
| Electrolyte | Electrolyte ionic diffusivity (D_{e,k}) | m² s⁻¹ | | See 23 | | Nyman et al. 2008, tr. 18 |
| | Electrolyte ionic conductivity (σ_{e,k}) | S m⁻¹ | | See 24 | | Nyman et al. 2008, tr. 18 |
| | Transference number (t⁺) | — | | 0.2594 | | eq. 25 tại 1 mol dm⁻³, tr. 18 |
| | Initial electrolyte concentration (c_{e0}) | mol m⁻³ | | 1000 | | tr. 17–18 |
| Reaction | Open Circuit Voltages (U_k) | V | see Fig. 12 or 8 | — | see Fig. 12 or 9 | GITT-OCV, tr. 11–13 |
| | Activation energy | J mol⁻¹ | 17.8·10³ | — | 35.0·10³ | EIS + Arrhenius, tr. 17 |
| | Reaction rate (m_k) | A m⁻² (m³ mol⁻¹)^1.5 | 3.42·10⁻⁶ | — | 6.48·10⁻⁷ | eq. 20, tr. 17 |

a) (nguyên văn chú thích) LGchem have been using a ceramic coated separator (SRS) since about 2006 which is a nanoceramic coating on polyolefin, they have licensed bhoemite coated separator from Optodot in 2016.

Bài nói Table VII có 37 tham số, mô hình chỉ cần 35 (chỉ dùng một trong hai stoichiometry 0%/100% làm điều kiện đầu; bài bắt đầu từ pin đầy → dùng 100% SOC) (tr. 18).

**Mâu thuẫn / KHÔNG RÕ trong bài:**
- c_{s,n}^max: văn bản (tr. 13) ghi **29603** mol m⁻³, Table VII ghi **29583** mol m⁻³. KHÔNG RÕ giá trị nào đúng; Table IX (tr. 20) dùng 29583 làm giá trị "Experiments".
- Reaction rate âm: tái tính bằng eq. 20 với j_0(25 °C) = 2.95·10⁻² mA cm⁻² = 0.295 A m⁻², c_e = 1000 mol m⁻³, c_max = 29583 cho k_n ≈ 6.31·10⁻⁷, không phải 6.48·10⁻⁷ (chênh ~2.7%). Giá trị dương tái tính được: 3.42·10⁻⁶ ✓. KHÔNG RÕ nguyên nhân sai lệch ở điện cực âm.
- Ký hiệu: Table I gọi hằng số tốc độ là k_k; Table VII gọi là m_k.
- Bruggeman âm 2.91 trong Table VII = trung bình của 2.92/2.90 (Table II L/A) — suy luận, bài không nói rõ.
- "Mean particle radius": Table II gọi 5.22/5.86 μm là "Average particle size", văn bản tr. 7 gọi là "average particle radii". KHÔNG RÕ là bán kính hay đường kính; bài dùng như bán kính (Table VII, Table V).
- Bán kính SiOx: tr. 7 ghi 1.52 μm (silicon), tr. 14 & Table IV ghi 1.2 μm (SiOx). Không nhất quán.
- Activation energy: được liệt kê nhưng **không dùng** trong mô hình (tr. 17, 18).

**Tham số thực sự dùng trong mô phỏng (đã hiệu chỉnh) — Table IX (tr. 20), cho dữ liệu 1C:**

| Parameter | Units | Experiments | Simulations | Variation (%) |
|---|---|---|---|---|
| Positive electrode diffusion coefficient | m² s⁻¹ | 1.48·10⁻¹⁵ | 4·10⁻¹⁵ | 170 |
| Negative electrode diffusion coefficient | m² s⁻¹ | 1.74·10⁻¹⁵ | 3.3·10⁻¹⁴ | 1797 |
| Positive electrode maximum concentration | mol m⁻³ | 51765 | 63104 | 22 |
| Negative electrode maximum concentration | mol m⁻³ | 29583 | 33133 | 12 |
| Positive electrode 100% SOC stoichiometry | — | 0.2661 | 0.27 | 1.47 |
| Bruggeman constants (pos/sep/neg) | — | 2.43/2.57/2.91 | 1.5 | 38/42/48 |

Chú thích Table IX: với C/2 và 1.5C, D_s âm đặt lần lượt **1.3·10⁻¹⁴** và **6.3·10⁻¹⁴** m² s⁻¹; các tham số không có trong bảng không được hiệu chỉnh. Bruggeman 1.5 = giá trị lý thuyết cho hạt cầu; dùng giá trị Table VII cho kết quả phi vật lý (điện giải cạn sau vài phút xả 1C) (tr. 18).

---

## 3. Hàm OCP fit U₊(x), U₋(x) (tr. 13, eq. [8], [9])

x = c_s / c_s^max (eq. 4). Fit bằng SciPy optimize; R² = 0.9999 (dương), 0.9982 (âm).

**Eq. [8] — positive electrode (NMC 811):**

U₊(x) = −0.8090 x + 4.4875 − 0.0428 × tanh(18.5138 (x − 0.5542)) − 17.7326 × tanh(15.7890 (x − 0.3117)) + 17.5842 × tanh(15.9308 (x − 0.3120))

**Eq. [9] — negative electrode (graphite-SiOx):**

U₋(x) = 1.9793 e^{−39.3631 x} + 0.2482 − 0.0909 × tanh(29.8538 (x − 0.1234)) − 0.04478 × tanh(14.9159 (x − 0.2769)) − 0.0205 × tanh(30.4444 (x − 0.6103))

(Đơn vị V vs Li/Li⁺ — suy từ ngữ cảnh half-cell; bài không ghi đơn vị cạnh eq. 8–9.)

- **Khoảng stoichiometry hợp lệ:** KHÔNG RÕ — bài không nêu khoảng hợp lệ của fit. Dải vận hành của cell (Table VII): dương 0.2661–0.9084, âm 0.0279–0.9014. Half-cell dương chỉ đo được tới x = 0.318 (tr. 12), phần dưới đó là ngoại suy (tr. 11).
- **Nhánh (branch):** KHÔNG RÕ cho phương trình fit. Bài nói mô phỏng **dùng nội suy dữ liệu thực nghiệm** (không dùng fit), với nhánh **delithiation cho điện cực âm** và **lithiation cho điện cực dương** (tức nhánh xả) (tr. 13); fit được cho "for completeness". Có thể fit làm trên cùng nhánh đó nhưng bài không khẳng định.
- **Loại OCV:** GITT-OCV (không phải pseudo-OCV C/20) (tr. 11, 22).
- **Nhiệt độ:** KHÔNG RÕ — bài không nêu nhiệt độ khi đo GITT half-cell (chỉ PEIS được nêu trong buồng nhiệt; validation ở 25 °C).
- **Hysteresis:** có hysteresis nhỏ lithiation/delithiation, lớn hơn ở điện cực âm SOC thấp (tr. 11, 16, 22); không có giá trị số.

---

## 4. Table V (hệ số khuếch tán) và Table VI (R_ct, j_0 theo nhiệt độ)

**Table V. Diffusion coefficients calculated for positive electrode and negative electrode (tr. 15)**

| Electrode | Potential (V) | Current (mA) (0.1 C) | Pulse (min) | Particle radius (μm) | D_s (10⁻¹⁵ m² s⁻¹) |
|---|---|---|---|---|---|
| NMC | 3.66–4.25 | 0.73 | 2.5 | 5.22 | 1.48 ± 1.05 |
| Graphite-SiOx | 0.005–1.0 | 0.58 | 2.5 | 5.86 | 1.74 ± 4.10 |

Ghi chú (tr. 14–16): giá trị là **trung bình biểu kiến trên toàn dải SOC**, từ phương trình Sand (eq. 11–14); điện cực âm đã áp hệ số giãn nở tuyến tính 0.85 (0% SOC) → 11.64 (100% SOC) (Table IV); điện cực âm chỉ fit 10 điểm cuối của xung; điện cực dương bỏ 5 điểm đầu. Bậc độ lớn nêu trong văn bản (không phải giá trị dùng được cho mô hình): NMC giảm xuống 10⁻¹⁴ cm² s⁻¹ ở SOC rất thấp, tới 10⁻¹⁰ ở SOC trung gian, 10⁻¹³ ở SOC đầy; graphite-SiOx trong khoảng 10⁻¹⁰–10⁻¹⁶ cm² s⁻¹ (tr. 15–16). Đường cong D_s(SOC) chỉ có trong Fig. 13.

**Table IV (tr. 14) — ảnh hưởng giãn nở hạt lên hệ số khuếch tán** (thể tích điện cực 9.64·10⁻³ cm³):

| Particle/Electrode | Unit | C₆ Spherical | SiOx Spherical | LiC₆ Spherical | Li_ySiOx Spherical | Electrode 0% SOC 9C₆:1SiOx | Electrode 100% SOC 9LiC₆:1Li_ySiOx |
|---|---|---|---|---|---|---|---|
| Radii | μm | 5.86 | 1.2 | 6.48 | 141.6 | 5.394 | 19.992 |
| Volume (V_particle) | cm³ | 8.43·10⁻¹⁰ | 7.24·10⁻¹² | 1.14·10⁻⁹ | 1.19×10⁻⁵ | 6.57·10⁻¹⁰ | 3.35·10⁻⁸ |
| Surface Area (SA_particle) | cm² | 4.32·10⁻⁶ | 1.81·10⁻⁷ | 5.28·10⁻⁶ | 2.52·10⁻³ | 3.66·10⁻⁶ | 5.02·10⁻⁵ |
| Surface Area (S) | cm² | 37.00 | 180.67 | 33.46 | 1.53 | 40.19 | 10.84 |
| (1/S)² | cm⁻⁴ | 7.31·10⁻⁴ | 3.06·10⁻⁵ | 8.93·10⁻⁴ | 4.27·10⁻¹ | 6.19·10⁻⁴ | 8.50·10⁻³ |
| Diffusion Factor | — | 1 | 0.04 | 1.22 | 583.89 | 0.85 | 11.64 |

(Giãn nở thể tích: graphite tới 10.6 % (tr. 14; tr. 22 ghi 10%), SiOx ~118 %.)

**Table VI. Charge transfer resistance and exchange current densities of NMC and graphite-SiOx electrodes at different temperature (tr. 17)**

| Electrode | Quantity | 25 °C | 30 °C | 40 °C | 50 °C | 60 °C |
|---|---|---|---|---|---|---|
| NMC | R_ct (Ω)^a) | 1.80 | 1.48 | 1.17 | 1.01 | 0.94 |
| NMC | j_0 (mA cm⁻²)^b) | 2.80·10⁻¹ | 3.48·10⁻¹ | 4.53·10⁻¹ | 5.44·10⁻¹ | 6.02·10⁻¹ |
| Graphite-SiOx | R_ct (Ω)^a) | 14.72 | 12.51 | 7.93 | 5.66 | 3.74 |
| Graphite-SiOx | j_0 (mA cm⁻²)^b) | 2.95·10⁻² | 3.54·10⁻² | 5.76·10⁻² | 8.32·10⁻² | 1.30·10⁻¹ |

a) All R_ct values are obtained from EIS obtained at 50% SOC. b) Surface areas used for calculating j_0 are 50.83 cm² for positive electrode and 59.09 cm² for negative electrode.

- j_0 tính từ R_ct theo eq. 18: j_0 = RT/(R_ct S F). R_ct dương là R3 (bán nguyệt thứ hai, 2–180 Hz); R_ct âm là R3 (bán nguyệt ~142 Hz) (tr. 16).
- PEIS: 10 mHz–500 kHz, biên độ 10 mV, buồng nhiệt 30/40/50/60 °C, half-cell ở 50% SOC (tr. 5, 16). **KHÔNG RÕ** cột 25 °C đo thế nào: phần thực nghiệm chỉ liệt kê 30–60 °C; có thể là bộ EIS "room temperature" ban đầu (tr. 16) nhưng bài không nói rõ.
- **Năng lượng hoạt hoá (tr. 17):** E_a = **17.8 kJ mol⁻¹** (NMC), **35.0 kJ mol⁻¹** (graphite-SiOx), từ độ dốc đồ thị Arrhenius (Fig. 16). Bài **không viết** dạng Arrhenius tường minh; dạng ngầm định: j_0(T) = j_0(T_ref) exp[ −(E_a/R)(1/T − 1/T_ref) ]. Kiểm tra bằng hồi quy ln j_0 theo 1/T trên 5 điểm của Table VI (script, không đọc đồ thị): 17.87 kJ/mol và 35.04 kJ/mol — **khớp** giá trị bài báo (nếu chỉ dùng 30–60 °C: 15.4 và 35.9 kJ/mol). Bài nói E_a **không được dùng** trong mô hình (tr. 17).
- **Reaction rate (tr. 17):** từ j_0 ở nhiệt độ phòng và c_e = 1 mol dm⁻³: k_p = 3.42·10⁻⁶, k_n = 6.48·10⁻⁷ A m⁻² (m³ mol⁻¹)^1.5; dạng m s⁻¹ với c_{e,ref} = 1000 mol m⁻³: k̂_p = 1.12·10⁻⁹, k̂_n = 2.12·10⁻¹⁰ m s⁻¹. ECM fit EIS (Fig. 14): R1 nối tiếp, R2‖CPE1 (giao diện), R3‖CPE2 (chuyển điện tích vật liệu hoạt động), CPE3 (đuôi tần thấp) — giá trị các phần tử ngoài R_ct **không được công bố**.
- Văn bản (tr. 16): "maximum current exchange density at 50% SOC" từ bộ EIS theo SOC (Fig. S8, bổ sung) — không có số.

---

## 5. Tính chất điện giải (tr. 4, 18)

Nguồn: **Nyman, Behm, Lindbergh, Electrochim. Acta 53, 6356 (2008)** (ref. 48). Lý do: điện giải thực của LGM50 không biết (datasheet chỉ nói gốc EC); thí nghiệm dùng R&D 281 (Soulbrain): 1 mol dm⁻³ LiPF₆ trong EC/EMC (3/7 V/V) + 1 wt% VC — cùng loại Nyman nghiên cứu (tr. 4–5, 18). Trong cả ba biểu thức, **c_e tính bằng mol dm⁻³**.

- (23) Diffusivity (m² s⁻¹): D_e = 8.794·10⁻¹¹ c_e² − 3.972·10⁻¹⁰ c_e + 4.862·10⁻¹⁰
- (24) Conductivity (S m⁻¹) [bài gọi nhầm là "electronic conductivity"]: σ_e = 0.1297 c_e³ − 2.51 c_e^1.5 + 3.329 c_e
- (25) Transference number: t⁺ = −0.1287 c_e³ + 0.4106 c_e² − 0.4717 c_e + 0.4492; trong mô phỏng dùng hằng số t⁺ = **0.2594** (eq. 25 tại 1 mol dm⁻³).
- **Thermodynamic factor / activity coefficient:** **không dùng** — giả thiết điện giải lý tưởng; giá trị của Nyman không được dùng (tr. 18). Bài không đưa số nào.
- Nhiệt độ hợp lệ của (23)–(25): KHÔNG RÕ (bài không nêu; không có phụ thuộc nhiệt độ).
- Ghi chú (tr. 20): nồng độ điện giải thực trong cell thương mại có thể cao hơn (tới 1.2 mol dm⁻³), dung môi/phụ gia khác.

---

## 6. Giới hạn stoichiometry, dung lượng, điện áp, hình học

| Đại lượng | Giá trị | Vị trí |
|---|---|---|
| Stoichiometry dương 0% SOC / 100% SOC | 0.9084 / 0.2661 | tr. 13, Table VII |
| Stoichiometry âm 0% SOC / 100% SOC | 0.0279 / 0.9014 | tr. 13, Table VII |
| Nồng độ Li tương ứng (dương, max/min stoich.) | 2.35·10⁻⁴ / 6.89·10⁻⁵ mol cm⁻² | tr. 13 |
| Dung lượng định danh (2.5–4.2 V) | 5 Ah ("rated capacity ... is cited to be 5 Ah") | tr. 9 |
| Dung lượng chuẩn hoá theo diện tích dương | 4.87 mAh cm⁻² (tr. 9); tr. 20 ghi 4.88 mAh cm⁻² | tr. 9, 20 |
| Dung lượng thực tế half-cell (C/20) | âm 5.0 mAh cm⁻², dương 4.5 mAh cm⁻² | tr. 9 |
| Dung lượng điện cực âm dùng cho eq. 7 | 5.07 mAh cm⁻² | tr. 13 |
| Delithiation half-cell dương | 4.7 mAh cm⁻² → 1.75·10⁻⁴ mol cm⁻² → Li₀.₃₁₈BO₂ | tr. 12 |
| Giới hạn điện áp cell | 2.5–4.2 V; 2.5 V tại C/50 (0.1 A) = 0% SOC theo nhà sản xuất | tr. 4, 5, 9 |
| Giới hạn half-cell | NMC 2.5–4.2 V; graphite-SiOx 0.005–1.5 V | tr. 5 |
| 1C | 5 A; i_app = 48.69 A m⁻² (với A = 0.1027 m²) | tr. 18 |
| 1C cho cell thử nghiệm nhỏ | 4.5 mA cm⁻² | tr. 5 |
| Kích thước cell | cao 70.00 mm, đường kính 21.00 mm; khối lượng 68.38 g (có vỏ), 57 g (không vỏ) | tr. 7 |

**Table II. Geometrical measurements (tr. 6)** — L: kích thước từ collector tới separator; A: phân tích ảnh top-down.

| Parameter | Unit | Positive electrode | Negative electrode | Separator |
|---|---|---|---|---|
| Length (side 1/2) | cm | 79/79 | 77.5/83.5 | — |
| Width | cm | 6.5 | 6.5 | — |
| Electrode plating area | cm² | 1027 | 1046.5 | — |
| Current collector thickness | μm | 16.3 | 11.7 | — |
| Electrode coating thickness | μm | 75.6 | 85.2 | 12 |
| Electrode loading | mg cm⁻² | 24.69 | 14.85 | — |
| Average particle size | μm | 5.22 | 5.86 | — |
| Electrolyte volume fraction | % | 33.5 | 25 | 47 |
| Tortuosity (L/A) | — | 4.8/4.8 | 14.25/13.93 | 3.27/3.27 |
| Bruggeman constant | — | 2.43/2.43 | 2.92/2.90 | 2.57/2.57 |

Bổ sung từ văn bản:
- Diện tích hai mặt: dương 1027 cm², âm 1046.5 cm² (tr. 7). Lớp phủ dương đối xứng hai mặt, âm không đối xứng (tr. 7). Diện tích bản cực dùng trong mô hình A = 0.1027 m² (tr. 18).
- Độ xốp: phương pháp mật độ 32% (dương) / 23% (âm, giả thiết 100% graphite) (tr. 7); FIB-SEM 35% / 27% (tr. 8); trung bình 33.5% / 25% (tr. 8). Mật độ tinh thể: NMC 811 4.95 g cm⁻³, graphite-SiOx 2.26 g cm⁻³ (tr. 7).
- Bán kính hạt trung bình: NMC 5.22, graphite 5.86, silicon 1.52 μm (tr. 7) (xem mâu thuẫn 1.2 μm ở tr. 14).
- Separator: polyme phủ gốm, dày ~12 μm (độ dày không đều) (tr. 7).
- Thành phần: Ni:Mn:Co:Al = 82.9:5.1:10.6:1.4 (EDS); Li:Ni:Mn:Co:Al = 82.4:78.7:5.5:9.8:5.9 (ICP-OES); giả định Li₀.₈₃₃Ni₀.₈₀Mn₀.₀₈Co₀.₀₈Al₀.₀₄O₂ (94.87 g mol⁻¹); dạng lithi hoá hoàn toàn 96.03 g mol⁻¹; SiOx với x = 0.64; graphite:SiOx = 90:10 wt% (tr. 8–9, 12; Table III tr. 9: assumed composition Li 83.3, Ni 80.08, Mn 8.06, Co 7.96, Al 3.6).
- Độ dẫn điện tử đo được: dương 0.174–0.186 S m⁻¹, âm 180–250 S m⁻¹; dùng trung bình 0.18 và 215 (tr. 10).
- c_s^max dương: 51765 mol m⁻³ (eq. 5, M_coat = 24.99 mg cm⁻²); lý thuyết 51545 mol m⁻³ (eq. 6) (tr. 13).

---

## 7. Thí nghiệm validation, sai số, công bố dữ liệu

- **Thí nghiệm (tr. 5):** 3 cell LGM50 trong buồng **25 °C**; sạc **C/3 CC-CV**, xả CC **C/2, 1C, 1.5C**, giữa 2.5 V và 4.2 V; mỗi pha sạc/xả theo sau **2 h nghỉ**. So sánh điện áp đầu cực (xả + nghỉ). Mô phỏng bắt đầu từ pin đầy (100% SOC) (tr. 18).
- **Table VIII (tr. 20):** RMSE và peak error giữa mô phỏng P2D và dữ liệu (trung bình 3 cell):

| C-rate | RMSE (mV) | Peak Error (mV) |
|---|---|---|
| C/2 | 46 | 302 |
| 1C | 41 | 271 |
| 1.5C | 36 | 272 |

- Peak error ở cuối xả; đóng góp chính vào RMSE là giai đoạn nghỉ; quá độ đầu giai đoạn nghỉ không khớp tốt (tr. 20). Sai số này đạt được **sau khi hiệu chỉnh 8 tham số** (Table IX), D_s âm hiệu chỉnh riêng cho từng C-rate (tr. 18, 20).
- **Công bố dữ liệu (tr. 22, "Data availability"):** chỉ nói bộ tham số (gồm OCV đo theo stoichiometry) có trong **PyBaMM** như một default dataset, repo https://github.com/pybamm-team/PyBaMM. **Bài không đưa link Zenodo hay WRAP**, không nói dữ liệu điện áp validation thô được công bố ở đâu → KHÔNG RÕ/không có. Giấy phép dữ liệu PyBaMM: không nêu trong bài (KHÔNG RÕ). Bài báo: CC BY-NC-ND 4.0 (tr. 2). Có tài liệu bổ sung (supplementary S1–S10) tại stacks.iop.org/JES/167/080534/mmedia (tr. 5) — chưa đọc, không có trong thư mục.

---

## 8. Không có dạng số (chỉ có hình)

Các đại lượng sau **chỉ có trong hình** (hoặc tài liệu bổ sung) → **KHÔNG được dùng** theo quy tắc minh bạch (trừ khi lấy từ dữ liệu thô mở, ví dụ file CSV OCV trong PyBaMM, bằng script):

1. Đường cong OCV dạng dữ liệu (GITT-OCV và pseudo-OCV, cả hai nhánh) — Fig. 10, 12. (Dạng số duy nhất trong bài là fit eq. 8–9; dữ liệu đo có trong PyBaMM theo tr. 22.)
2. Độ lớn hysteresis OCV sạc/xả — Fig. 10, 13d.
3. dQ/dV — Fig. 11.
4. OCV ba điện cực của full cell và kết quả cân bằng (balancing) — Fig. 12.
5. **D_s theo SOC** (cả hai điện cực, hai chiều lithi hoá/delithi hoá) — Fig. 13a,b; chỉ có trung bình ± độ lệch trong Table V và bậc độ lớn trong văn bản.
6. Phân bố kích thước hạt — Fig. 5.
7. Phổ EIS theo nhiệt độ — Fig. 15; giá trị các phần tử ECM khác R_ct (R1, R2, CPE1–3) — Fig. 14/15, không có bảng.
8. EIS theo SOC, j_0 theo SOC — Fig. S8 (bổ sung); chỉ biết "cực đại ở 50% SOC".
9. Đường thẳng Arrhenius (hệ số chặn) — Fig. 16 (nhưng E_a có số; j_0 có trong Table VI).
10. Đường điện áp validation và sai số theo thời gian — Fig. 17 (chỉ RMSE/peak có số, Table VIII).
11. R² của fit Sand theo SOC — Fig. S10; xung GITT mẫu — Fig. S9.
12. Phân bố tortuosity/vi cấu trúc 3D — Fig. 6.

**Hoàn toàn không có trong bài (kể cả trong hình)** — cần nguồn khác (vd. O'Kane 2022, O'Regan 2022):
- Mọi tham số nhiệt: nhiệt dung, khối lượng riêng các lớp, độ dẫn nhiệt, hệ số truyền nhiệt, hệ số entropy dU/dT (mô hình đẳng nhiệt).
- Phụ thuộc nhiệt độ của D_s, D_e, σ_e, t⁺ (chỉ có E_a của j_0, và bài nói không dùng).
- Thermodynamic factor của điện giải.
- Mọi tham số lão hoá: SEI, lithium plating, mất hoạt chất, điện trở màng.
- Điện trở tiếp xúc/collector, dung lượng điện cực kép.
- Dữ liệu sạc nhanh / sạc với dòng cao (chỉ có xả).

---

## 9. Kết luận về mức độ liên quan

**Liên quan và CẦN THIẾT.** Đây là nguồn gốc của bộ tham số "Chen2020" cho LG M50 mà O'Kane et al. 2022 dùng làm nền cho mô hình DFN + nhiệt + SEI + plating. Đồ án nên trích dẫn trực tiếp bài này cho: hình học (Table II/VII), độ xốp, c_max, stoichiometry 0%/100% SOC, OCP fit eq. 8–9, j_0/k và E_a (Table VI, tr. 17), điện giải Nyman (eq. 23–25), và phương trình P2D (Table I).

**Cần lưu ý:**
- Dùng giá trị **đã hiệu chỉnh (Table IX)** hay **đo (Table VII)** phải nêu rõ; O'Kane 2022 có thể dùng bộ khác — đối chiếu khi đọc O'Kane.
- Table I có lỗi in (đối số sinh, điện áp đầu cực) — không chép máy móc.
- Bài **không cung cấp** gì về nhiệt, lão hoá, plating, hay sạc → các phần này phải lấy từ O'Kane 2022 / O'Regan 2022.
- Phần không liên quan đến đồ án: quy trình tháo cell, ICP-OES/EDS, FIB-SEM, đo 4 mũi dò, thảo luận thuật ngữ OCV/EMF — chỉ là bối cảnh phương pháp, không cần cho mô phỏng MATLAB.
- Phần liên quan một phần: E_a 17.8/35.0 kJ mol⁻¹ (hữu ích cho mô hình nhiệt dù bài không dùng); D_s(SOC) chỉ có trong hình nên không dùng được.
