# Đối chiếu tham số: Li 2025 (bản in) — mã nguồn tác giả — nguồn gốc

Mục đích: với mỗi chỗ bản in của Li et al. 2025 (Nat. Commun. 16:2776, SI) sai hiển nhiên hoặc lệch mã nguồn của chính tác giả, tìm **nguồn gốc** của mục đó để phân xử, không đoán.

**Nguồn gốc đã lấy và đã đọc toàn văn cho bảng này**

| Ký hiệu | Tài liệu | Ghi chú chi tiết |
|---|---|---|
| [LG] | Landesfeind & Gasteiger, J. Electrochem. Soc. 166 (14) A3079–A3097 (2019), DOI 10.1149/2.0571912jes, CC BY-NC-ND | `tham_so/Landesfeind2019_tham_so.md` |
| [S18] | Single, Latz, Horstmann, ChemSusChem 11:1950–1955 (2018), DOI 10.1002/cssc.201800077 — **bản thảo tác giả + SI** (kho DLR; = arXiv:1812.03841); bản Wiley không truy cập được | `tham_so/SEI_Single2018_vonKolzenberg2020_tham_so.md` |
| [vK] | von Kolzenberg, Latz, Horstmann, ChemSusChem 13:3901–3910 (2020), DOI 10.1002/cssc.202000867, CC BY | như trên |
| [OR-SI] | **Supplementary của O'Regan 2022** (Electrochim. Acta 425:140700), file Word của nhà xuất bản `tai_lieu/ORegan2022_ElectrochimActa_SI.docx` (mới lấy; trước đây đồ án chưa có). Text + bảng: `toan_van_trich_xuat/ORegan2022_SI.txt`; phương trình (OMML) đọc bằng cách tuyến tính hoá XML. Gồm Table S1–S7, Eq. S1–S8, Figure S1–S7. Đã đọc toàn bộ phần chữ, bảng, phương trình; không đọc số từ hình. | mục 3 dưới đây (chép nguyên các bảng hệ số) |
| [OR] | O'Regan 2022 bài chính (đã có sẵn trong đồ án) | `tham_so/ORegan2022_tham_so.md` |
| [OK] | O'Kane 2022 (đã có sẵn) | `tham_so/OKane2022_tham_so.md` |
| [DL] | Số liệu thô của O'Regan (Zenodo 5171874), đã phân tích trong `data/ket_qua_du_lieu.md` | – |

"Mã nguồn" = như định nghĩa trong `gia_dinh.md`; các giá trị ở cột mã nguồn lấy lại từ `gia_dinh.md` và `dac_ta_lao_hoa.md` (bảng này không đọc lại mã).

Lưu ý đánh số: bài chính O'Regan trỏ tới "Table S7 / S8 / S9" cho D_s / j_0 / dU/dT, nhưng trong file SI thật các bảng đó mang số **S5 / S6 / S7**.

---

## 1. Bảng quyết định

Cột "Phán quyết": **ĐÃ GIẢI QUYẾT** = nguồn gốc (hoặc đại số trên chính các phương trình in) phân xử được; **CHƯA GIẢI QUYẾT** = không có nguồn gốc nào phân xử.

### 1.1 Điện giải (Li 2025 SI Note 10, SI tr. 50)

| # | Mục (mã GD) | Li 2025 in | Mã nguồn | Nguồn gốc | Phán quyết và kiểm tra số | Dùng trong MATLAB |
|---|---|---|---|---|---|---|
| E1 | Hệ số p4 của κ_e, (S14) (GD-03) | 0.8353 | 0.353 | [LG] Bảng II tr. A3090: p4 = 3.53E−01 (EC:EMC 3:7); dạng hàm pt. [15] tr. A3088 | **ĐÃ GIẢI QUYẾT — bản in sai (lỗi in), mã đúng.** Tại 1 M, 25 °C: bản in → 2.452 S/m; [LG] → 0.913 S/m (9.13 mS/cm). Dạng hàm đã kiểm bằng cột EC:DMC: tính ra 10.76/12.89/17.28 mS/cm ở 20/30/50 °C, bài in "10.8–12.9" và "∼17". | **0.353** |
| E2 | Hệ số p2 (bậc nhất theo c) của t₊, (S15) (GD-04) | −0.612 | −6.12 | [LG] Bảng II tr. A3090: p2 = −6.12E+00; dạng hàm pt. [20] tr. A3092 | **ĐÃ GIẢI QUYẾT — bản in sai (lỗi in), mã đúng.** Tại 1 M, 25 °C: bản in → t₊ = 5.729 (phi vật lý); [LG] → 0.221 (20 °C: 0.160, đúng bằng số đo 0.16 in ở tr. A3092). | **−6.12** |
| E3 | Tiền tố của D_e, (S13) (GD-22) | "10⁻¹⁰ · 1010" | 1.01e3 × 1e-10 | [LG] Bảng II: p1 = 1.01E+03; pt. [18] tr. A3090 có thừa số 10⁻⁶ cm²/s = 10⁻¹⁰ m²/s | **ĐÃ GIẢI QUYẾT — bản in đúng**, đọc là 1010 × 10⁻¹⁰ m²/s. D_e(1 M, 25 °C) = 2.892×10⁻¹⁰ m²/s. | 1010 × 10⁻¹⁰ m²/s |
| E4 | Thừa số "(1 + (T − 228))" trong (S14) (KHÔNG RÕ #11) | (1 + (T − 228)) | như in | [LG] pt. [15] tr. A3088: p1·(1 + (T − p2)), p2 = 2.28E+02 | **ĐÃ GIẢI QUYẾT — bản in đúng**, không thiếu hệ số. | như in |
| E5 | Các hệ số còn lại của (S13)–(S16) | – | – | [LG] Bảng II | Đã so từng hệ số: giống hết (κ: 0.521, 228, −1.06, −0.00359, 0.00148; D: 1.01, −1560, −487; TDF: cả 9; t₊: 8 hệ số còn lại). 0.1 trong (S14) là đổi mS/cm → S/m. | như in |
| E6 | Vị trí của thermodynamic factor χ trong phương trình thế điện giải (GD-18) | SI Table 2 không có χ; Table 6 liệt kê χ là tham số | i_e = −κ_eff(∂φ_e/∂x − 2(1 − t₊)χ(RT/F)∂ln c_e/∂x) | [LG] pt. [2] tr. A3082: số hạng khuếch tán = (ν₊+ν₋)/(z₊ν₊)·(RT/F)·κ_eff·[1 + dln f±/dln c]·(1 − t₊)·(1/c)∇c; muối 1:1 → hệ số 2. t₊ và TDF của [LG] được tách từ a ≡ TDF·(1 − t₊) và b ≡ TDF·(1 − t₊)² (pt. [9], [11], [13], [14]) | **ĐÃ GIẢI QUYẾT — dạng có χ (trùng mã) là dạng của nguồn gốc.** Bảng phương trình của Li 2025 chép từ [OR-SI] Table S2, ở đó cũng không có χ (xem B2). Tại 1 M, 25 °C: χ = 2.182, tức bỏ χ làm số hạng thế khuếch tán nhỏ đi 2.2 lần. | có χ: `2·(1 − t₊)·χ·(RT/F)·∂ln c_e/∂x` |
| E7 | Khoảng hiệu lực | (S12): dùng tới 4000 mol/m³, trên đó giữ giá trị tại 4 M | như in | [LG]: đo 0.1–3.0 M, −10…+50 °C; với EC:EMC điểm 0.1 M bị loại khi khớp TDF, t₊ (tr. A3091–A3092) | Không phải mâu thuẫn: 3–4 M là **ngoại suy** của Li 2025 (tại 4 M, 25 °C: χ = 12.8, t₊ = 0.45). Hàm t₊ âm ở nhiệt độ thấp (1 M, −10 °C: −0.38; 1.5 M, 10 °C: −0.07). Ghi là giới hạn mô hình. | như in (S12) |

Về "O'Regan 2022 như in": [OR] tr. 29 chỉ in **dạng hàm** pt. [18]–[21], **không in hệ số nào**, và dạng in có lỗi (thiếu `·c` và dấu `+` trong [18]; thiếu c ở số hạng p5 và thiếu T ở số hạng p8 trong [20]; thiếu T ở p8 trong [21]). Không dùng.

### 1.2 SEI (Li 2025 SI Note 2, SI tr. 33–34)

| # | Mục | Li 2025 in | Mã nguồn | Nguồn gốc | Phán quyết | Dùng trong MATLAB |
|---|---|---|---|---|---|---|
| S1 | Số mũ của luật SEI, (S2), (S6), (S7) | exp(−(φ_s − φ_e)), không có F/(RT) | exp(−F(φ_s − φ_e)/(RT)) | [S18] pt. (5), bản thảo tr. 3: c_LiI(x=0) = c_LiI,0·exp(−FU/(RT)); [vK] pt. (18), (25), tr. 3904: j_SEI = −(c_Li,0·D·F/L_SEI)·e^{−η̃_SEI}, η̃_SEI = F/(RT)·(η_int + U_0 + μ_Li,0/F) | **ĐÃ GIẢI QUYẾT — bản in thiếu F/(RT); mã đúng.** Kiểm thứ nguyên: F·V/(RT) không thứ nguyên; ở 25 °C, RT/F = 25.69 mV. | **exp(−F·(φ_s − φ_e)/(R·T))**, T = nhiệt độ cell |
| S2 | Thế trong số mũ có trừ sụt áp màng η_SEI không | φ_s − φ_e (không trừ) | không trừ | [vK] pt. (10): η_int + U_0 = φ_S − μ_Li+,SEI với Li⁺ "at the electrode–SEI interface" → theo nguồn gốc là thế **sau** sụt áp màng; [S18]: mạch hở, không có sụt áp | **ĐÃ GIẢI QUYẾT theo quy tắc "làm như in":** bản in và mã thống nhất (không trừ). Khác biệt với [vK] cỡ F·ρ_SEI·L_SEI·j/(RT) ≈ 3×10⁻⁴ ở 1C (≈ 0.03 % tốc độ SEI; tính ở `SEI_…_tham_so.md` mục 3.2). | φ_s − φ_e (không trừ η_SEI) |
| S3 | Hệ số trước 1/L của tốc độ tăng độ dày mỗi lớp, (S6), (S7) | vế thứ hai: c_int/(2L)·D·V̄·e^{…} | c_int·D·V̄/(4·L_outer)·e^{…} | [S18] pt. (1): L = (V/s)·Q/(AF) + L0, s = 2 (SI Table SI-2) → một lớp nhận toàn bộ dòng: dL/dt = V·D·c·e^{…}/(2L). Li 2025 tự in: (S2) j = cDF/L·e^{…}; (S3)/(S4) mỗi lớp 0.5·j; vế thứ nhất (S6)/(S7): dL/dt = j_lớp/(2F)·V̄ | **ĐÃ GIẢI QUYẾT — 1/4.** Đại số: 0.5 × 1/(2F) × cDF/L = cD/(4L). Vế thứ hai của (S6)/(S7) mâu thuẫn hệ số 2 với (S2)+(S3)+vế thứ nhất; nó trùng công thức một lớp của [S18] (quên hệ số 0.5). Mã trùng 1/4. Nguồn gốc xác nhận thừa số V̄/(z_SEI·F), z = 2; việc chia đôi dòng dựa trên (S3)/(S4) và α = 0.5 (Table 8) của chính Li 2025. | **c_int·D_int·V̄_SEI/(4·L)·e^{…}** cho mỗi lớp |
| S4 | Độ dày ở mẫu số: L_inner hay L_outer | (S2): L_inner; (S7): L_outer | L_outer cho cả hai lớp | [S18]: độ dày toàn màng; [vK]: L_SEI − L_tun; không bài nào có hai lớp | **ĐÃ GIẢI QUYẾT — không ảnh hưởng số:** α = 0.5, V̄ bằng nhau, điều kiện đầu bằng nhau ⇒ L_inner ≡ L_outer. Lưu ý: Li 2025 dùng nửa độ dày màng làm quãng khuếch tán (định nghĩa mô hình, c·D là tham số khớp). | L_inner như (S2) (≡ L_outer) |
| S5 | L_SEI,0 và ε_n,0 (GD-02, GD-19) | 1.23625×10⁻⁸ m "unchanged" (Table 8); ε_n = 0.2224 | 9.2326×10⁻⁹ m (+2.5 nm mỗi lớp), ε_n = 0.234965 | Không có: đây là giá trị riêng của Li 2025; [S18] chỉ có L0 = 15 nm cho cell khác | **CHƯA GIẢI QUYẾT.** Không nguồn gốc nào phân xử; giữ như `gia_dinh.md` (báo cáo cả hai biến thể). | theo `gia_dinh.md` |

### 1.3 Tham số BOL kế thừa O'Regan 2022 (Li 2025 SI Note 8, 11; Table 2, 6, 7)

| # | Mục (mã GD) | Li 2025 in | Mã nguồn | Nguồn gốc | Phán quyết | Dùng trong MATLAB |
|---|---|---|---|---|---|---|
| B1 | Butler–Volmer, SI Table 2 (GD-21) | j_k = a_k·j_0,k·sinh(RT/(2F)·η_k) | j = 2·j_0·sinh(F·η/(2RT)) | [OR-SI] Table S2 in **y hệt** dạng sai: `J_k = a_k j_0,k sinh((1/2)(RT/F)η_k)` → Li 2025 chép lỗi từ đây. Dạng chuẩn in trong [vK] pt. (9) tr. 3903: j_int = 2·j_0·sinh(F·η_int/(2RT)); và [OK] Table S1 (theo `gia_dinh.md`) | **ĐÃ GIẢI QUYẾT — bản in sai thứ nguyên (lỗi có từ [OR-SI]); dạng đúng là 2·j_0·sinh(F·η/(2RT)).** | j = 2·j_0·sinh(F·η/(2RT)) |
| B2 | Dạng j_0 trong SI Table 2 | j_0 = k_k·√(c_e·c_k·(c_max − c_k)) | (S26), (S27) | [OR-SI] Table S2 in cùng dạng tổng quát đó; nhưng hàm thật sự dùng là [OR] pt. [14] tr. 24 với hệ số ở [OR-SI] Table S6: k_0 = 0.0005028 / 0.0002668 (bài chính Bảng 8: A cm⁻²), α = 0.43 / 0.792, E_a = 2.401×10⁴ / 4×10⁴ J/mol (dương / âm) | **ĐÃ GIẢI QUYẾT — (S26), (S27) của Li 2025 đúng với nguồn gốc:** 0.0005028 A/cm² = 5.028 A/m²; 0.0002668 A/cm² = 2.668 A/m²; số mũ 0.43/0.57 và 0.792/0.208; E_a trùng. Dạng căn bậc hai trong Table 2 chỉ là dạng chung, không dùng. | (S26), (S27) như in |
| B3 | ⟨c_e⟩ trong (S26), (S27) (GD-06) | không định nghĩa | 1000 mol/m³ | [OR] pt. [14]: (c_e/c_e0)^(1−α); [OR-SI] Table S2, dòng "Initial conditions": c_e,k = c_e0; [OR] tr. 29: điện giải giả thiết 1 mol dm⁻³ LiPF6 | **ĐÃ GIẢI QUYẾT:** ⟨c_e⟩ ≡ c_e0 = nồng độ ban đầu = 1000 mol/m³ (trùng mã). | 1000 mol/m³ |
| B4 | Hệ số D_s(x), SI Table 7 và (S17) | 28 hệ số a_i, b_i, c_i; R_cor = 2.7 / 3.0321; E_act dương = 12000 | – (không có tranh chấp được ghi) | [OR-SI] Table S5 | **Khớp hoàn toàn** từng hệ số a_0…c_4 của cả hai cực (bảng ở mục 3.1). Khác duy nhất: E_a dương [OR-SI] = 12047 J/mol, Li 2025 in 12000 (Li 2025 ghi "activation energy has been changed for this work"); E_a âm [OR-SI] = 17393 J/mol, Li 2025 thay bằng tham số khớp (Table 3). R_cor: [OR] tr. 21, 31 in 3.03 và 2.7. | như Li 2025 in |
| B5 | Hệ số ∂U_n/∂T, (S6) Note 8 (GD-08b) | −0.111, 0.02901, 0.3562, 0.08308, 0.004621 | −0.1112, 0.02914, 0.3561, 0.08309, 0.004616 | [OR-SI] Table S7 (cột âm): a_0 = −0.111, b_0 = 0.02901, a_1 = 0.3562, b_1 = 0.08308, c_1 = 0.004621 | **ĐÃ GIẢI QUYẾT — bản in đúng với nguồn gốc;** mã lệch ở chữ số thứ 3–4. | giá trị in |
| B6 | Hệ số ∂U_p/∂T, (S5) Note 8 | 0.04006, 0.2828, 0.0009855, −0.06656, 0.8032, 0.02179 | – | [OR-SI] Table S7 (cột dương): giống hết | Khớp. | như in |
| B7 | Đơn vị của ∂U/∂T (GD-08) | Table 6: "V/K" | chia 1000 | [OR] Bảng 8 cũng ghi "V K⁻¹"; [OR-SI] Table S7 **không in đơn vị**; [DL] header 4 file thô: "mV K-1", hàm in khớp số đo với RMSE 0.009 / 0.074 mV/K khi hiểu là mV/K | **ĐÃ GIẢI QUYẾT bằng số liệu đo gốc, không phải bằng bản in:** hàm cho mV/K; nhãn "V/K" ở cả hai bài là sai. | nhân 10⁻³ |
| B8 | "Density (porous)" cực âm / màng ngăn, SI Table 6 (GD-07) | màng ngăn 1740, cực âm 946 kg/m³ | cực âm 1740, màng ngăn 946 | [OR] Bảng 7 tr. 17: "Graphite-SiOy coating (dry porous)" 1740 (đo); "Separator (dry porous)" 946 (đo). Cùng bảng: wetted 2060 / 1548 — Li 2025 Table 6 in đúng hai số này theo thứ tự | **ĐÃ GIẢI QUYẾT — Li 2025 in đổi chỗ hai ô; mã đúng.** | cực âm 1740, màng ngăn 946 |
| B9 | C_p(T) của bột điện cực, màng ngăn, (S21)–(S23) | ba đa thức bậc 3 | – | [OR-SI] Table S4, Eq. S1–S3 | Khớp từng hệ số. | như in |
| B10 | σ_s,p | 0.8473·exp(−3500/R·(1/T − 1/298.15)) | – | [OR] tr. 25, Bảng 8: 0.847 S/m, 3.5 kJ/mol | Khớp (khác ở chữ số thứ 4). | như in |
| B11 | OCP | hàm mới có hysteresis, Note 8 (S1)–(S4) | trùng | [OR-SI] Eq. S7, S8 là OCP cũ (Chen 2020) | Không tranh chấp: Li 2025 chủ động thay OCP (đánh dấu *). Chép Eq. S7, S8 ở mục 3.4 để tham khảo. | Li 2025 Note 8 |
| B12 | λ_pos(T), λ_neg(T), (S24), (S25) | hai đa thức bậc 2 | – | [OR] Bảng 6 cho giá trị theo nhiệt độ và nói dùng nội suy; [OR-SI] **không** có đa thức này | **CHƯA GIẢI QUYẾT** (không ảnh hưởng mô hình nhiệt 0D): không tìm được nguồn in của hai đa thức; chưa kiểm chúng với Bảng 6. | chỉ cần nếu làm mô hình nhiệt có phân bố |

### 1.4 Các mục khác trong `gia_dinh.md` / danh sách "KHÔNG RÕ"

| # | Mục | Li 2025 in | Mã nguồn | Nguồn gốc | Phán quyết | Dùng trong MATLAB |
|---|---|---|---|---|---|---|
| P1 | Hệ số truyền của mạ lithium (KHÔNG RÕ #4) | Table 8: "α_a,Li = 0.65"; (S10): số hạng hoà tan mang α_a, số hạng mạ mang α_c | mạ 0.65, hoà tan 0.35 | [OK] bảng tham số (PDF tr. 34): α_a,Li "Anodic transfer coefficient for Li stripping" = 0.35; α_c,Li "Cathodic transfer coefficient for Li plating" = 0.65; Li 2025 SI Note 3: mô hình mạ "unchanged from O'Kane et al." | **ĐÃ GIẢI QUYẾT — nhãn ở Table 8 sai;** 0.65 là α_c,Li (mạ), α_a,Li = 0.35 (hoà tan). Trùng mã. | α_a = 0.35, α_c = 0.65 trong (S10) |
| P2 | Đơn vị β, giá trị t_0, đơn vị k_cr (KHÔNG RÕ #5) | – | β [1/s] dùng trực tiếp; t_0 = 3600 s | Không lấy thêm nguồn gốc (các bài gốc về nứt/LAM mà O'Kane trích chưa được đọc) | **CHƯA GIẢI QUYẾT** bằng nguồn gốc; hiện chỉ dựa vào mã. | theo `dac_ta_lao_hoa.md` |
| P3 | Khuếch tán do ứng suất trong hạt (GD-10) | không nhắc | bật | không có | **CHƯA GIẢI QUYẾT** | theo `gia_dinh.md` |
| P4 | R_0 = 11.5 mΩ: vị trí trong mô hình; nhiệt I²R_0 (GD-20, GD-05) | chỉ có giá trị | V − I·R_0; không tính nhiệt | không có ([OR], [OR-SI] không có R_0) | **CHƯA GIẢI QUYẾT** | theo `gia_dinh.md` |
| P5 | Dạng lumped của cân bằng nhiệt (GD-12), nhiệt phản ứng (GD-12b) | SI Table 3 (PDE + q_r = j(φ_s − φ_e − U)) | PyBaMM lumped | [OR-SI] Table S3 in **cùng** các phương trình như Li 2025 SI Table 3 (ρC_p∂T/∂t = ∇·(k∇T) + q_tot; q_tot = q_rev + q_j + q_r; q_r = ∫ j_Li(φ_s − φ_e − U)dx/l; biên −k∂T/∂n = h(T − T_amb)) → xác nhận Li 2025 chép đúng; nhưng nguồn gốc cũng **không in** dạng 0D | **CHƯA GIẢI QUYẾT** (dạng 0D vẫn theo mã). Riêng q_r: bản in của cả hai bài thống nhất. | theo `gia_dinh.md` |
| P6 | h = 20 W/m²/K (GD-11); E_act của D_s,n (GD-01) | – | – | [OR] tr. 32: h = 15 (chỉnh tay); [OR-SI] Table S5: E_a âm = 17393 J/mol (giá trị đo gốc; Li 2025 thay bằng 2×10⁴ / 6×10⁴ khớp lại) | Không phải lỗi in — là lựa chọn/khớp lại của Li 2025. Ghi nhận giá trị gốc 17393 J/mol để tham khảo. | theo `gia_dinh.md` |

---

## 2. Tóm tắt việc phải đổi trong mô hình

1. κ_e: hệ số **0.353** (không phải 0.8353). t₊: hệ số **−6.12** (không phải −0.612). Hai mục GD-03, GD-04 chuyển từ "theo bài báo (code khác)" sang "lỗi in đã xác nhận bằng nguồn gốc".
2. Dùng χ trong phương trình thế điện giải (GD-18): có căn cứ nguồn gốc ([LG] pt. [2]).
3. SEI: `exp(−F·(φ_s − φ_e)/(R·T))`, hệ số **1/4** cho mỗi lớp.
4. Butler–Volmer `2·j_0·sinh(F·η/(2RT))` (GD-21): có căn cứ; lỗi in bắt nguồn từ [OR-SI] Table S2.
5. ⟨c_e⟩ = 1000 mol/m³ (GD-06): có căn cứ.
6. ρ khô: cực âm 1740, màng ngăn 946 (GD-07): có căn cứ.
7. Hệ số ∂U_n/∂T: giữ giá trị **in** (GD-08b; nguồn gốc ủng hộ bản in, không ủng hộ mã). Đơn vị mV/K (GD-08).
8. α_a,Li = 0.35 (hoà tan), α_c,Li = 0.65 (mạ).

Còn mở (CHƯA GIẢI QUYẾT): S5 (L_SEI,0, ε_n,0), B12 (λ(T)), P2 (β, t_0, k_cr), P3 (khuếch tán do ứng suất), P4 (R_0), P5 (dạng nhiệt 0D).

---

## 3. Phụ lục — các bảng hệ số của [OR-SI], chép nguyên

Khoảng tin cậy 95 % in trong ngoặc.

### 3.1 Table S5 — D_s (hàm [OR] pt. [10], tr. 20: log10 D_s(x) = a_0·x + b_0 + Σ a_i·exp(−(x − b_i)²/c_i))

| Tham số | Cực dương | Cực âm |
|---|---|---|
| a_0 | – | 11.17 (8.645, 13.69) |
| a_1 | −0.9231 (−0.9958, −0.8504) | −1.553 (−1.633, −1.473) |
| a_2 | −0.4066 (−0.4475, −0.3656) | −6.136 (−7.511, −4.76) |
| a_3 | −0.993 (−1.124, −0.8623) | −9.725 (−11.53, −7.923) |
| a_4 | – | 1.85 (1.725, 1.976) |
| b_0 | −13.96 (−14.09, −13.83) | −15.11 (−15.2, −15.01) |
| b_1 | 0.3216 (0.3199, 0.3233) | 0.2031 (0.2021, 0.2041) |
| b_2 | 0.4532 (0.4506, 0.4559) | 0.5375 (0.5083, 0.5668) |
| b_3 | 0.8098 (0.798, 0.8216) | 0.9144 (0.8901, 0.9387) |
| b_4 | – | 0.5953 (0.5941, 0.5966) |
| c_1 | 0.002534 (0.002113, 0.002956) | 0.0006091 (0.00053, 0.0006882) |
| c_2 | 0.003926 (0.003287, 0.004565) | 0.06438 (0.04902, 0.07973) |
| c_3 | 0.09924 (0.07619, 0.1223) | 0.0578 (0.04712, 0.06848) |
| c_4 | – | 0.001356 (0.001144, 0.001567) |
| E_a | 12047 (11415, 12679) | 17393 (15647, 19139) |

Bảng không in đơn vị; b_0 ≈ −14 … −15 ứng với m²/s ([OR] tr. 20 nêu khoảng 10⁻¹⁰–10⁻¹¹ cm²/s cho NMC811). Số hạng "c_0" có trong [OR] pt. [10] nhưng không có trong Table S5 (và không có trong Li 2025 (S17)).

### 3.2 Table S6 — j_0 (hàm [OR] pt. [14], tr. 24)

| Tham số | Cực dương | Cực âm |
|---|---|---|
| k_0 | 0.0005028 (0.0004312, 0.0005744) | 0.0002668 (0.0002225, 0.0003111) |
| α | 0.43 (0.3136, 0.5464) | 0.792 (0.7252, 0.8589) |
| E_a | 2.401·10⁴ (1.676·10⁴, 3.126·10⁴) | in "4e·10⁴" (3.263·10⁴, 4.737·10⁴) |

Đơn vị k_0 không in trong Table S6; [OR] Bảng 8 ghi j_0 theo A cm⁻². Lưu ý: phần lời [OR] tr. 23–24 nêu E_a trung bình 31.1 / 54.8 kJ/mol, khác giá trị khớp 24.01 / 40 kJ/mol ở Table S6; Li 2025 và mã dùng giá trị khớp.

### 3.3 Table S7 — ∂U/∂T (hàm [OR] pt. [16], [17], tr. 27)

| Tham số | Cực dương | Cực âm |
|---|---|---|
| a_0 | – | −0.111 (−0.1535, −0.06846) |
| a_1 | 0.04006 (−2.578e+07, 2.578e+07) | 0.3562 (0.3231, 0.3892) |
| a_2 | −0.06656 (−0.08762, −0.04551) | – |
| b_0 | – | 0.02901 (−0.003796, 0.06182) |
| b_1 | 0.2828 (−2.466e+07, 2.466e+07) | 0.08308 (0.07159, 0.09456) |
| b_2 | 0.8032 (0.7687, 0.8376) | – |
| c_1 | 0.0009855 (−4.924e+05, 4.924e+05) | 0.004621 (0.001368, 0.007874) |
| c_2 | 0.02179 (0.003508, 0.04007) | – |

Khoảng tin cậy ±10⁷ của số hạng Gauss thứ nhất ở cực dương cho thấy số hạng đó không được xác định bởi dữ liệu (ghi nhận; không đổi giá trị).

### 3.4 Table S4 (Eq. S1–S6) và Eq. S7, S8

| Vật liệu | Đại lượng | Đa thức (T [K]) | R² | Pt. |
|---|---|---|---|---|
| NMC | C_p | −0.0008414·T³ + 0.7892·T² − 241.3·T + 2.508·10⁴ | 0.997 | S1 |
| Graphite-SiOy | C_p | 0.0004932·T³ − 0.491·T² + 169.4·T − 1.897·10⁴ | 1 | S2 |
| Separator | C_p | 0.001494·T³ − 1.444·T² + 475.5·T − 5.13·10⁴ | 1 | S3 |
| Aluminium | C_p | 4.503·10⁻⁶·T³ − 0.006256·T² + 3.281·T + 355.7 | 1 | S4 |
| Copper | C_p | 1.445·10⁻⁶·T³ − 0.001946·T² + 0.9633·T + 236 | 1 | S5 |
| Copper | λ [W m⁻¹ K⁻¹] | −5.409·10⁻⁷·T³ + 0.0007054·T² − 0.3727·T + 463.6 | 1 | S6 |

Đơn vị C_p không in trong bảng (theo [OR] Bảng 7: J kg⁻¹ K⁻¹).

- Eq. S7: `U_+(x) = −0.8090·x + 4.4875 − 0.0428·tanh(18.5138·(x − 0.5542)) − 17.7326·tanh(15.7890·(x − 0.3117)) + 17.5842·tanh(15.9308·(x − 0.3120))`
- Eq. S8: `U_−(x) = 1.9793·e^{−39.3631·x} + 0.2482 − 0.0909·tanh(29.8538·(x − 0.1234)) − 0.04478·tanh(14.9159·(x − 0.2769)) − 0.0205·tanh(30.4444·(x − 0.6103))`

### 3.5 Table S2 (DFN) và Table S3 (nhiệt) — những điểm liên quan

- Butler–Volmer in: `J_k = a_k·j_0,k·sinh((1/2)·(RT/F)·η_k)` (sai thứ nguyên; xem B1).
- Dòng điện giải in: `∂/∂x( ε_k^b·σ_e,k·( ∂φ_e,k/∂x − 2(1 − t⁺)·RT/F·∂log c_e,k/∂x ) ) = −J_k` (không có TDF; xem E6).
- Điện áp đầu cực in: `V = φ_e,p|x=L − φ_e,n|x=0` (in chỉ số "e" — hẳn phải là thế pha rắn; ghi nhận).
- Table S3: như liệt kê ở P5.
