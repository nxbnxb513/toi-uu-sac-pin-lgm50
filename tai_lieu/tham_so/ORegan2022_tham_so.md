# O'Regan, Brosa Planella, Widanage, Kendrick (2022) — Trích tham số nhiệt–điện hoá

**Nguồn:** K. O'Regan, F. Brosa Planella, W. D. Widanage, E. Kendrick, "Thermal-electrochemical parameters of a high energy lithium-ion cylindrical battery", *Electrochimica Acta* 425 (2022) 140700. Bản Author's Accepted Manuscript (WRAP, http://wrap.warwick.ac.uk/196287), giấy phép CC BY-NC-ND 4.0.
**Tệp đã đọc:** `tai_lieu/ORegan2022_ElectrochimActa.pdf` (40 trang). Văn bản trích xuất: `tai_lieu/toan_van_trich_xuat/ORegan2022.txt`.
**Quy ước số trang:** "tr. N" là số trang PDF (1–40). Trang 1 là bìa WRAP; trang 2 là bìa preprint ChemRxiv (doi 10.26434/chemrxiv-2022-d2q4n); nội dung chính ở tr. 3–37; tài liệu tham khảo ở tr. 37–40.
**Cách đọc:** đã đọc toàn bộ 40 trang. Các bảng và phương trình bị lỗi khi trích xuất (Bảng 5, 7, 8, Pt. [18]–[21]) đã được render lại thành ảnh để đọc chữ (tr. 14, 17, 29, 30). Không đọc bất kỳ giá trị nào từ đường cong trên hình.

> **CẢNH BÁO QUAN TRỌNG — Phụ lục (Supplementary) KHÔNG nằm trong PDF này.** Bài báo dẫn tới Table S1, S2, S3, S5, S7, S8, S9; Eq. [S1]–[S8]; Figure S1–S8. PDF 40 trang **không chứa** các mục đó (đã kiểm tra: 40 trang = bìa + bài chính + tài liệu tham khảo). Vì vậy **các hệ số khớp hàm** (D_s Pt. [10] → Table S7; j0 Pt. [14] → Table S8; dU/dT Pt. [16]–[17] → Table S9; Cp Eq. S1–S5; λ_Cu Eq. S6; OCP Eq. S7–S8) và **các phương trình mô hình nhiệt** (Table S2, S3) **không có trong tài liệu đã đọc**. Phải lấy Supplementary của bản Elsevier (VoR) hoặc từ repository (xem mục 6) thì mới có.

---

## 1. Mô hình nhiệt mà bài báo dùng

| Mục | Nội dung | Vị trí |
|---|---|---|
| Loại mô hình | Mô hình điện hoá **P2D/DFN** ghép với mô hình nhiệt **lumped 0D** (chỉ có một nhiệt độ). Câu gốc: "a pseudo-two-dimensional (P2D) electrochemical coupled to a lumped (0D) thermal model was used". | tr. 5; tóm tắt tr. 3 ("DFN and 0D thermal model"); kết luận tr. 35–36 ("A 0D electrochemical-thermal model") |
| Phân biệt lõi/bề mặt? | **KHÔNG.** "The jellyroll is considered to be a homogenous material so it has a uniform temperature, and the thermal conductivity can be neglected." Không có trạng thái riêng cho nhiệt độ lõi và nhiệt độ bề mặt/vỏ. | tr. 17 |
| Phương trình | **KHÔNG CÓ trong PDF.** Bài viết rằng các phương trình nằm ở Table S2 (DFN) và Table S3 (nhiệt). Ở tr. 31 lại ghi "Tables S1 and S2" (không nhất quán với tr. 5/8). Bài chính không in ra phương trình cân bằng năng lượng nào. → **KHÔNG RÕ** dạng chính xác. | tr. 5, 8, 31 |
| Nguồn nhiệt | Có nói bằng lời: nhiệt thuận nghịch (reversible/entropic) được tính bằng hệ số entropy đo được; nhiệt bất thuận nghịch "is accounted for in the DFN model definition". Không in biểu thức của Q_irr hay Q_rev. | tr. 18, 26 |
| Điều kiện biên / làm mát | Hệ số trao đổi nhiệt **h = 15 W m⁻² K⁻¹**, được **chỉnh tay** ("adjusted manually"). Diện tích trao đổi nhiệt hiệu dụng: jellyroll 4.84·10⁻³ m², cell 5.31·10⁻³ m² (Bảng 8). Bài **không nói** diện tích nào được dùng cùng h, và không in phương trình làm mát → **KHÔNG RÕ**. Trong thí nghiệm, buồng nhiệt có quạt, tức đối lưu cưỡng bức (tr. 7, cho các phép thử cell nhỏ); với phép thử validation, buồng nhiệt được đo nhiệt độ liên tục (tr. 8). | tr. 32; Bảng 8 tr. 30 |
| Ghép với DFN | **Có, ghép hai chiều**: các tham số điện hoá phụ thuộc T theo Arrhenius (Pt. [6], [14]), dU/dT cấp nhiệt thuận nghịch, và mô hình dự đoán nhiệt độ được so với nhiệt độ đo. Phần mềm PyBaMM v0.4.0, giải bằng finite volume (30 điểm lưới cho mỗi điện cực và separator, 150 điểm cho mỗi hạt), tổng cộng 9092 ODE và 150 phương trình đại số, solver CasADi; mỗi lần mô phỏng mất 10–20 phút. | tr. 8 |
| Mô hình 1D/2D/3D | Bài cung cấp tham số "để mở rộng ra 3D" (Bảng 6, 7, hình học Bảng 3) nhưng **không xây dựng và không kiểm chứng** mô hình nhiệt 1D/2D/3D ("further modelling work is required"). | tr. 4, 36 |

Yêu cầu tham số theo cấp mô hình (tr. 4): mô hình 0D cần năng lượng hoạt hoá, hệ số entropy và nhiệt dung lumped (theo thể tích); mô hình 1D cần thêm độ dẫn nhiệt, nhiệt dung và hình học 1D.

Các phương trình phụ trợ được in trong bài chính:
- Pt. [1] (tr. 13): θ̄ = ρ_s·C_p,s·ε_s + ρ_l·C_p,l·ε_l (nhiệt dung theo thể tích của điện cực đã thấm điện giải)
- Pt. [2] (tr. 13): ρ̄ = ρ_s·ε_s + ρ_l·ε_l
- Pt. [3] (tr. 14): C̄_p = θ̄ / ρ̄
- Pt. [4] (tr. 14): λ = α·ρ·C_p
- Pt. [5] (tr. 15): λ_total = (2L_e + L_cc) / (2L_e/λ_e + L_cc/λ_cc), là trung bình điều hoà của các lớp nối tiếp. Bài gọi đây là độ dẫn "perpendicular to the electrode" (vuông góc với điện cực, through-plane). Câu ngay trước đó lại nói "in-plane direction is the harmonic average", mâu thuẫn với chính nó → coi Pt. [5] là **through-plane**.

---

## 2. Tham số nhiệt có giá trị số

### 2.1 Bảng 7 (tr. 17) — Tính chất nhiệt vật lý ở 25 °C
(m = đo, c = tính, l = lấy từ tài liệu)

| Material | Thickness / µm | ρ / kg m⁻³ | Cp / J kg⁻¹ K⁻¹ | Θ / J m⁻³ K⁻¹ | α / mm² s⁻¹ | λ / W m⁻¹ K⁻¹ |
|---|---|---|---|---|---|---|
| NMC811 coating (dry porous) | 75.6 m | 3270 m | 990 c | 3237300 c | 0.249 c | 0.807 c |
| NMC811 coating (dry bulk) | 75.6 m | 4918 c | 990 m | 4868120 c | – | – |
| NMC811 coating (wetted porous) | 75.6 m | 3699 c | 902 c | 3335495 c | 0.242 | 0.807 c |
| Positive electrode (2-sided) | 167.2 m | 3216 c | 983 c | 3162202 c | 0.282 m | 0.892 c |
| Graphite-SiOy coating (dry porous) | 85.2 m | 1740 m | 960 c | 1670400 c | 2.271 c | 3.793 c |
| Graphite-SiOy coating (dry bulk) | 85.2 m | 2320 c | 960 m | 2227200 c | – | – |
| Graphite-SiOy coating (wetted porous) | 85.2 m | 2060 c | 846 c | 1743680 c | 2.175 c | 3.793 c |
| Negative electrode (2-sided) | 182.4 m | 2213 c | 809 c | 1790697 c | 2.266 m | 4.058 c |
| Aluminium foil | 16 m | 2702 l | 876 l | 2366952 l | 100 l | 237 l |
| Copper foil | 12 m | 8933 l | 383 l | 3421339 l | 117 l | 401 l |
| Separator (dry porous) | 12 m | 946 m | 1700 m | 1608200 c | 0.208 c | 0.3344 l |
| Separator (wetted porous) | 12 m | 1548 c | 1128 c | 1745966 c | 0.192 c | 0.3344 c |
| Electrolyte (EC:EMC:DMC 1:1:1) | – | 1280 l | 229 l | 293120 l | 0.1 l | 0.03 l |
| Jellyroll | – | 2682 c | 887 c | – | – | – |
| Casing (SS Type 304) | 340 m | 7900 l | 477 l | – | 3.87 l | 15 l |

Ghi chú:
- Các giá trị λ của điện cực là **through-plane** (đo bằng LFA, tr. 7). Bài **không cho giá trị λ in-plane** cho điện cực hay cho cả cuộn (jellyroll). Không có λ hiệu dụng theo phương bán kính hay phương trục của cell. Bài nói rõ: kết hợp các giá trị thành phần "do not provide an accurate value for the overall cell thermal conductivity" (tr. 15–16).
- Bài giả định λ của điện cực khô và điện cực thấm điện giải là như nhau, vì N₂ (0.025 W m⁻¹ K⁻¹) và điện giải (0.03 W m⁻¹ K⁻¹) có độ dẫn nhiệt gần nhau (tr. 15).
- Điện giải: C_p = 229 J kg⁻¹ K⁻¹ (literature, tham khảo [35] Bohn et al. 2016). Giá trị này nhất quán nội bộ (1280 × 229 = 293120) nhưng **thấp bất thường** so với các dung môi carbonate. Cần đối chiếu với nguồn gốc [35] trước khi dùng. Ngoài ra, điện giải dùng cho tính chất nhiệt (EC:EMC:DMC 1:1:1) **khác** với điện giải dùng trong mô hình điện hoá (EC:EMC 3:7) (tr. 12).
- Các phép đo nhiệt vật lý thực hiện ở 0 % SoC (cell xả tới 2.5 V); không đo sự phụ thuộc vào SoC (tr. 12).

### 2.2 Bảng 6 (tr. 16) — Phụ thuộc nhiệt độ

| T / K | 268.15 | 283.15 | 298.15 | 313.15 | 328.15 |
|---|---|---|---|---|---|
| α, Positive electrode (2-sided) / mm² s⁻¹ | 0.305 | 0.292 | 0.282 | 0.27 | 0.259 |
| α, Negative electrode (2-sided) / mm² s⁻¹ | 2.508 | 2.355 | 2.266 | 2.148 | 2.028 |
| Cp, Positive electrode (2-sided) / J kg⁻¹ K⁻¹ | 897 | 925 | 983 | 1057 | 1130 |
| Cp, Negative electrode (2-sided) / J kg⁻¹ K⁻¹ | 585 | 709 | 809 | 892 | 967 |
| λ, Positive electrode (2-sided) / W m⁻¹ K⁻¹ | 0.880 | 0.868 | 0.892 | 0.918 | 0.941 |
| λ, NMC811 coating (wetted porous) | 0.796 | 0.785 | 0.807 | 0.830 | 0.851 |
| λ, Negative electrode (2-sided) | 3.249 | 3.696 | 4.058 | 4.243 | 4.339 |
| λ, Graphite-SiOy coating (wetted porous) | 3.037 | 3.455 | 3.793 | 3.967 | 4.056 |

Trong mô hình, λ của graphite và NMC được đưa vào dưới dạng **interpolant** (nội suy từ bảng trên), vì đa thức bậc thấp khớp không tốt (tr. 15).

### 2.3 Bảng 5 (tr. 14) — Dùng để tính Cp của vật liệu thấm điện giải

| Parameter | NMC811 | Graphite-SiOy | Separator |
|---|---|---|---|
| Density of porous material ρ_s / kg m⁻³ | 3270 | 1740 | 946 |
| Heat capacity of bulk material C_p,s | Eq. S1 | Eq. S2 | Eq. S3 |
| Density of electrolyte ρ_l / kg m⁻³ | 1280 | 1280 | 1280 |
| Heat capacity of electrolyte C_p,l / J K⁻¹ kg⁻¹ | 229 | 229 | 229 |
| Electrolyte volume fraction ε_l | 0.335 | 0.25 | 0.47 |
| Density of wetted material ρ_s+l / kg m⁻³ | 3700 | 2060 | 1620 |

(Bảng in sai đơn vị: ghi "kg m⁻³" cho C_p,s và "J K⁻¹ kg⁻³" cho C_p,l.)

### 2.4 Các giá trị trong văn bản

| Đại lượng | Giá trị | Vị trí |
|---|---|---|
| Volumetric heat capacity, wetted positive / negative electrode | 3335500 / 1743680 J m⁻³ K⁻¹ | tr. 13 |
| Averaged density, saturated positive / negative electrode | 3700 / 2060 kg m⁻³ | tr. 13 |
| Gravimetric Cp, wetted positive / negative (không gồm current collector), 25 °C | 900 / 845 J kg⁻¹ K⁻¹ | tr. 13 |
| Wetted separator: Θ, ρ, Cp | 1745970 J m⁻³ K⁻¹; 1620 kg m⁻³; 1080 J kg⁻¹ K⁻¹ | tr. 14 |
| λ separator (wetted, literature [43]) | 0.3344 W m⁻¹ K⁻¹ | tr. 14 |
| λ laminate ở 25 °C, NMC811 / graphite | 0.807 / 3.793 W m⁻¹ K⁻¹ | tr. 15 |
| λ aluminium (hằng số) | 237 W m⁻¹ K⁻¹ | tr. 15 |
| λ copper | đa thức bậc 3 theo T, Eq. S6 (**không có trong PDF**) | tr. 15 |
| Cp Al, Cu | đa thức bậc 3, Eq. S4, S5 (**không có trong PDF**) | tr. 13 |
| Phân bố khối lượng theo diện tích, điện cực dương | 8.1 % Al, 91.9 % lớp phủ NMC | tr. 15 |
| Phân bố khối lượng theo diện tích, điện cực âm | 26.6 % Cu, 73.4 % lớp phủ graphite | tr. 15 |
| **Cp hiệu dụng của jellyroll (lumped)** | **887 J kg⁻¹ K⁻¹ (2.38·10⁶ J K⁻¹ m⁻³)** | tr. 17 (văn bản + Bảng 7) |
| **Jellyroll effective heat capacity (Bảng 8, dùng trong mô phỏng)** | **866 J kg⁻¹ K⁻¹** | tr. 30 |
| **Heat transfer coefficient h** | **15 W m⁻² K⁻¹ (chỉnh tay)** | tr. 32 |
| Effective heat transfer area, jellyroll / cell | 4.84·10⁻³ / 5.31·10⁻³ m² | Bảng 8 tr. 30 (diện tích jellyroll cũng có ở Bảng 3 tr. 11) |
| Jellyroll volume / cell volume | 2.13·10⁻⁵ / 2.42·10⁻⁵ m³ (Bảng 8); Bảng 3 ghi cell volume 2.43·10⁻⁵ m³ | tr. 30, 11 |
| Mass of cell / jellyroll (gồm điện giải) | 6.83·10⁻² / 5.71·10⁻² kg (Bảng 3); Bảng 4: 67.25 g / 57.08 g | tr. 11 |
| Jellyroll width / height | 2.03·10⁻² / 6.58·10⁻² m | Bảng 3 tr. 11 |
| Cell width / length | "2.1·10⁻² / 71·10⁻² m" (in như vậy; 71·10⁻² m rõ ràng là lỗi in, có lẽ là 7.1·10⁻² m) → **KHÔNG RÕ**, cần xác nhận | Bảng 3 tr. 11 |
| Casing thickness | 3.4·10⁻⁴ m | Bảng 3 tr. 11 |
| Lớp cách điện | Màng nhựa theo phương bán kính 20 µm; đĩa nhựa đáy 0.22 mm; màng sợi đục lỗ ở đỉnh 0.2 mm | tr. 9 |
| Số vòng cuộn | ca. 23 vòng | tr. 9 |
| Năng lượng riêng | 752 Wh L⁻¹, 267 Wh kg⁻¹ | Bảng 3 tr. 11 |

**Không nhất quán (để nguyên, KHÔNG RÕ giá trị nào đúng):**
- Cp jellyroll: 887 (tr. 17, Bảng 7) và 866 (Bảng 8, tr. 30).
- ρ của separator thấm điện giải: 1548 (Bảng 7) và 1620 (văn bản tr. 14, Bảng 5, Bảng 8).
- Cp của separator thấm điện giải: 1128 (Bảng 7) và 1080 (tr. 14).
- Bảng 8 ghi "Density (ρ_s)*" của điện cực dương = **625** kg m⁻³. Giá trị này không khớp với 3270/3699/3216 kg m⁻³ ở Bảng 7 → nghi là lỗi in. **KHÔNG RÕ.**
- Kết luận tr. 36 ghi "Cp at 990 and 950" cho hai điện cực, còn Bảng 7 ghi 990 và 960.

---

## 3. Hệ số entropy dU/dT

- Đo bằng phương pháp potentiostatic trong cell 3 điện cực, ở 25, 15, 5, −5 °C, với SoC 0–100 % cách nhau 10 % (tr. 7–8, 26–27).
- Dạng hàm (tr. 27):
  - Pt. [16]: ∂U_p/∂T(x) = a1·exp(−(x−b1)²/c1) + a2·exp(−(x−b2)²/c2)
  - Pt. [17]: ∂U_n/∂T(x) = a0·x + b0 + a1·exp(−(x−b1)²/c1)
- **Các hệ số nằm ở Table S9, KHÔNG có trong PDF.** Bài chính chỉ có hình (Hình 13).
- Thông tin định tính (tr. 27–28): với graphite, ΔS < 0 khi mức lithi hoá thấp và đổi dấu tại x ≈ 0.6. Hệ số entropy của NMC "negligible", nên nhiệt thuận nghịch do điện cực âm chi phối. Ngoài vùng đo, dU/dT được giả định tiến về 0.
- **Lưu ý (đã bị chỉnh):** hàm của điện cực âm **cố ý bỏ các điểm ở hệ số hợp thức trung gian** để khớp nhiệt độ ở 0.5C, 25 °C (tr. 28, 31; Hình 14). Bảng 8 tô xanh dU_n/dT, tức đây là tham số đã chỉnh.
- Trong bài **không có giá trị số** nào của dU/dT.

---

## 4. Phụ thuộc nhiệt độ của tham số vận chuyển và động học

Dạng chung là Arrhenius, Pt. [6] (tr. 17): n(T) = n_ref·exp[(E_a/R)(1/T_ref − 1/T)]. Pt. [7]: độ dốc của đồ thị ln(n) theo 1/T bằng E_a/R.

| Tham số | Dạng hàm | Giá trị số có trong PDF | Vị trí |
|---|---|---|---|
| **Solid diffusivity D_s (cả hai điện cực)** | Pt. [10]: log10 D_s(x) = a0·x + b0 + c0 + Σ_{i=1..4} a_i·exp(−(x−b_i)²/c_i). Đo GITT ở 5–45 °C. Mỗi nhiệt độ có một bộ khớp riêng (Hình 6); hệ số ở **Table S7 (không có)**. | Chỉ có khoảng: NMC811 ~10⁻¹⁰ đến 10⁻¹¹ cm² s⁻¹; graphite-SiOy 10⁻¹⁴ đến 10⁻¹⁰ cm² s⁻¹ (tr. 20). **Hệ số nhân 3.03** cho D_s,n (tr. 21, 31). **Hệ số nhân 2.7** cho D_s,p (chỉnh tay theo 1C, 25 °C; tr. 31). | tr. 20–21, 31 |
| E_a của D_s | Theo hệ số hợp thức (Hình 7, chỉ có hình) | NMC: 10–20 kJ mol⁻¹. Graphite-SiOy: 5–60 kJ mol⁻¹ (tr. 22). Kết luận: E_a của NMC "doubled to 24 kJ K⁻¹" khi x > 0.8 (đơn vị in sai, ý là kJ mol⁻¹) (tr. 36). Không có giá trị trung bình hay giá trị điểm nào dùng được trực tiếp. | tr. 22, 36 |
| **Exchange current density j0** | Pt. [14]: j0(c,T) = k0·(1−c_s/c_s,max)^(1−α)·(c_s/c_s,max)^α·(c_e/c_e0)^(1−α)·exp[−(E_a/R)(1/T − 1/298.15)]. Đo EIS ở 15–45 °C. k0, α, E_a ở **Table S8 (không có)**. | Ở 25 °C: NMC811 trong khoảng 0.5·10⁻⁴ đến 3.0·10⁻⁴ A cm⁻², trung bình 2.01·10⁻⁴ A cm⁻². Graphite-SiOy trong khoảng 2.0·10⁻⁵ đến 9.0·10⁻⁵ A cm⁻², trung bình 7.1·10⁻⁵ A cm⁻² (tr. 23). Diện tích S dùng trong phân tích: 3.266076·10⁻³ m² (dương), 4.151297·10⁻³ m² (âm) (tr. 22). Với điện cực dương, khớp Butler–Volmer có R² = 0.63; khớp nửa ellipse có R² = 0.9 (tr. 23). | tr. 22–24 |
| E_a của j0 | Theo hệ số hợp thức (Hình 10, chỉ có hình) | Dương: khoảng 20–50 kJ mol⁻¹, **trung bình 31.1 kJ mol⁻¹**. Âm: khoảng 45–65 kJ mol⁻¹, **trung bình 54.8 kJ mol⁻¹** (tr. 23–24). Các giá trị này thay cho 17.8 / 35 kJ mol⁻¹ của Chen 2020. | tr. 23–24 |
| Electronic conductivity σ_s,p | Arrhenius | **0.847 S m⁻¹ ở 25 °C**, ứng với x ≈ 0.9; **E_a = 3.5 kJ mol⁻¹** (tr. 25; Bảng 8). Không đo phụ thuộc SoC. | tr. 25, 30 |
| σ_s,n | hằng số | 215 S m⁻¹ (Bảng 8, trích từ Chen 2020 [23]) | tr. 30 |
| Electrolyte κ, D_e, TDF, t+ | Pt. [18]–[21] (dạng của Landesfeind & Gasteiger 2019 [79]); hệ số p_i "outlined elsewhere" [79]. Bài **không in hệ số**. | – | tr. 29 |

Ghi chú về Pt. [18]–[21] (tr. 29, đã render để đọc):
- Pt. [18]: κ(T,c) = p1·(1+(T−p2))·[1 + p3·√c·p4·(1+p5·exp(1000/T))] / [1 + c⁴·(p6·exp(1000/T))] mS/cm
- Pt. [19]: D±(T) = p1·exp(p2·c)·exp(p3/T)·exp(p4·c/T)·10⁻⁶ cm²/s
- Pt. [20] (TDF) và Pt. [21] (t+): đa thức theo c và T.
- **Có dấu hiệu lỗi in:** Pt. [20] có hai số hạng p5·T và p8·c². Ngoài ra, Bảng 8 ghép t+ với Eq. [20] và TDF với Eq. [21], ngược với thứ tự ở tr. 29.
- **Không nên chép Pt. [18]–[21] từ bài này.** Hãy lấy trực tiếp từ Landesfeind & Gasteiger 2019, J. Electrochem. Soc. 166, A3079.

Các tham số khác trong Bảng 8 (tr. 30):

| Parameter | Positive | Separator | Negative |
|---|---|---|---|
| Current collector thickness | 16·10⁻⁶ m | – | 12·10⁻⁶ m |
| Electrode thickness | 75.6·10⁻⁶ m | 12·10⁻⁶ m | 85.2·10⁻⁶ m |
| Mean particle radius | 5.22·10⁻⁶ m | – | 5.86·10⁻⁶ m |
| Electrolyte volume fraction | 33.5 % | 47 % | 25 % |
| Active material volume fraction | 66.5 % | – | 75 % |
| Bruggeman exponent | 1.5 | 1.5 | 1.5 |
| c_s,max (theo Chen 2020) | 51765 mol m⁻³ | – | 29583 mol m⁻³ |
| Current collector density | 2702 kg m⁻³ | – | 8933 kg m⁻³ |

Nồng độ ban đầu khi validation: 13975 mol m⁻³ (dương, x = 0.27) và 28866 mol m⁻³ (âm, x = 0.98) (tr. 31).

Khoảng hệ số hợp thức đo bằng half-cell (theo Chen 2020): dương x = 0.2567 đến 0.9072; âm x = 0.0279 đến 0.9014 (tr. 18).

---

## 5. Hàm OCP và diffusivity cập nhật

- **OCP:** Bảng 8 ghi Eq. [S7] và [S8] kèm chỉ dẫn tham khảo [23], tức là **lấy lại OCP của Chen et al. 2020**. Bài **không đưa OCP mới** và không in hệ số trong bài chính.
- **Diffusivity:** đã cập nhật thành hàm phụ thuộc x và T (Pt. [10]); hệ số ở Table S7, **không có trong PDF**. Khi dùng phải nhân thêm 2.7 (dương) và 3.03 (âm). Vì không có hệ số trong PDF, **không thể tái tạo từ tài liệu đã đọc**.
- **Cp(T) của bột điện cực và separator:** đa thức bậc 3 (theo lý thuyết Debye), Eq. S1–S3 (**không có**). Cp(T) của Al, Cu: Eq. S4–S5 (**không có**).

---

## 6. Validation và dữ liệu

| Mục | Nội dung | Vị trí |
|---|---|---|
| Thí nghiệm | Sạc 0.3C CC-CV (cắt ở C/100), sau đó xả C/10, C/2, 1C, 2C trong cửa sổ 2.5–4.2 V. Nghỉ 2 h giữa các bước. Thực hiện ở 0, 10, 25 °C trên máy Maccor. Nhiệt độ đo bằng **một thermocouple gắn ngoài** trên vỏ cell (tức nhiệt độ bề mặt). | tr. 8 |
| Bộ dữ liệu | Có 9 bộ (0.5C, 1C, 2C nhân với 0, 10, 25 °C). Bài phân tích 5 bộ: 0.5C ở 25/0/10 °C, 1C ở 25 °C, 2C ở 25 °C. Số cell được thử: 4 cell (Hình 14, 15), 3 cell (Hình 16). **Không có drive cycle.** **Không có thí nghiệm sạc nhanh.** | tr. 31, 33–34 |
| Tham số đã chỉnh | (1) D_s,p nhân 2.7 (chỉnh tay theo 1C, 25 °C); (2) D_s,n nhân 3.03; (3) dU_n/dT (bỏ các điểm trung gian). Ngoài ra h = 15 W m⁻² K⁻¹ cũng chỉnh tay, và nồng độ ban đầu chỉnh theo điện áp nghỉ. | tr. 31–32 |
| Sai số | Chỉ có **một** con số: RMSE ở C/2 (sau khi chỉnh theo 1C) là **0.14 với bộ Chen2020 và 0.10 với bộ ORegan2021**, tức giảm 27 % (tr. 32). Đơn vị **không ghi** (có lẽ là V) → KHÔNG RÕ. Chú thích Hình 17 (tr. 35) lại ghi **ngược** (0.10 cho Chen2020, 0.14 cho bài này) → mâu thuẫn nội bộ; văn bản và tóm tắt ủng hộ con số 0.10 cho ORegan. **Không có sai số định lượng cho nhiệt độ.** Ở 0 °C khớp kém hơn (nằm ngoài khoảng nhiệt độ đã đo tham số). | tr. 31–32, 35 |
| Dữ liệu tham số | Zenodo **DOI 10.5281/zenodo.5171874**: D_s, entropic term, j0, electronic conductivity, Cp, λ | tr. 37 |
| Dữ liệu validation | Zenodo **DOI 10.5281/zenodo.4864437** | tr. 37 |
| Bộ tham số | Có trong PyBaMM (bộ "ORegan2022"), https://www.pybamm.org/ | tr. 31, 37 |
| Giấy phép repo | **KHÔNG RÕ.** Bài không nêu giấy phép của các bản ghi Zenodo. Cần kiểm tra trên trang Zenodo. (PyBaMM dùng BSD-3-Clause, nhưng thông tin này không lấy từ bài báo.) **Chưa đọc các repository này.** | – |

---

## 7. Không có dạng số (chỉ có hình)

Các mục dưới đây chỉ có trong hình hoặc chỉ có trong phụ lục không kèm theo PDF. **Không được đọc giá trị từ hình.**
- Cp(T) của bột NMC, bột graphite, separator (Hình 3); hệ số Eq. S1–S3 không có.
- Cp(T) của Al, Cu (Eq. S4, S5) và λ_Cu(T) (Eq. S6): không có trong PDF.
- D_s(x,T) của cả hai điện cực (Hình 6, Hình S4–S5); hệ số Table S7 không có.
- E_a của D_s theo x (Hình 7); chỉ có khoảng trong văn bản.
- j0(x,T) (Hình 9) và E_a của j0 theo x (Hình 10); hệ số Table S8 không có (văn bản chỉ có khoảng và giá trị trung bình).
- σ_s,p theo 1/T (Hình 11); văn bản chỉ có 0.847 S m⁻¹ và 3.5 kJ mol⁻¹.
- dU/dT của hai điện cực (Hình 13); hệ số Table S9 không có.
- Hệ số hợp thức theo SoC (Hình 4).
- Đường điện áp và nhiệt độ thực nghiệm so với mô phỏng (Hình 14–17).
- Vị trí tab (Hình 1, Hình S1–S2); kích thước tab có trong Bảng 3: tab âm 4.00·10⁻³ × 5·10⁻² × 1·10⁻⁴ m, tab dương 3.5·10⁻³ × 7·10⁻² × 1·10⁻⁴ m.
- Phương trình DFN và phương trình nhiệt (Table S2, S3): không có.

---

## 8. Đánh giá mức độ phù hợp với đồ án

**Mô hình nhiệt hai trạng thái (lõi/bề mặt) với số liệu minh bạch: KHÔNG hỗ trợ trực tiếp.**
- Bài chỉ dùng mô hình **lumped 0D**, với giả định "uniform temperature, thermal conductivity can be neglected" (tr. 17).
- Không có **độ dẫn nhiệt hiệu dụng theo phương bán kính** của cả cuộn.
- Không có **nhiệt trở lõi–vỏ**.
- Không có **phép đo nhiệt độ lõi**: chỉ có một thermocouple gắn ngoài.
- Hệ số h là giá trị **chỉnh tay** (15 W m⁻² K⁻¹) cho mô hình 0D.

Nếu muốn suy ra R_core-surface, phải tự tính từ λ through-plane của từng lớp (Bảng 6/7, Pt. [5]) và hình học (Bảng 3/4). Khi đó cần chú ý:
1. Đó là phép tính của nhóm đồ án, không phải giá trị do bài báo công bố.
2. Bài tự cảnh báo rằng cách ghép này **không cho λ tổng chính xác**, vì bỏ qua nhiệt trở tiếp xúc giữa các lớp (tr. 15–16).
3. Muốn làm minh bạch thì phải ghi rõ công thức (chẳng hạn λ_r hiệu dụng bằng trung bình điều hoà theo bề dày của một "stack" gồm Al, 2 lớp NMC, 2 separator, 2 lớp graphite, Cu) và trích nguồn từng số. Kể cả vậy, kết quả **chưa được kiểm chứng**.

**Bài báo hỗ trợ được:**
- (a) Mô hình 0D: Cp jellyroll 887 hoặc 866 J kg⁻¹ K⁻¹ (cần chọn và ghi rõ); khối lượng, thể tích, diện tích (Bảng 3, 4, 8); h = 15 W m⁻² K⁻¹ (giá trị đã chỉnh, ghi rõ là "tuned").
- (b) Nhiệt dung theo từng lớp và λ through-plane theo T (Bảng 6, 7), dùng làm đầu vào minh bạch nếu nhóm tự xây dựng R_th và C_th cho mô hình 2 trạng thái. Với vỏ thép: ρ = 7900 kg m⁻³, Cp = 477 J kg⁻¹ K⁻¹, λ = 15 W m⁻¹ K⁻¹, dày 340 µm; vỏ có thể là node "surface".
- (c) Năng lượng hoạt hoá của j0 (trung bình 31.1 / 54.8 kJ mol⁻¹) và của σ_s,p (3.5 kJ mol⁻¹), dùng làm số trong văn bản (thay cho 17.8 / 35 kJ mol⁻¹ của Chen 2020).
- (d) Dữ liệu validation mở (Zenodo 4864437), có nhiệt độ bề mặt ở 0/10/25 °C và 0.5C–2C khi xả. Một script có thể **nhận dạng** h, C_th và có thể cả R_th từ dữ liệu này. Đây là con đường hợp lệ nhất theo quy tắc minh bạch, với điều kiện giấy phép Zenodo cho phép.

**Không hỗ trợ được nếu chỉ dùng PDF:**
- Các hàm dU/dT(x), D_s(x,T), j0(x,T), Cp(T): hệ số nằm ở phụ lục và Zenodo 5171874. Cần tải các nguồn đó và ghi giấy phép.
- Không có dữ liệu sạc nhanh, không có drive cycle, không có tham số lão hoá.
