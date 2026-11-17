# Landesfeind & Gasteiger 2019 — tính chất điện giải LiPF6 (nguồn gốc của Li 2025 SI pt. (S13)–(S16))

**Trích dẫn:** J. Landesfeind, H. A. Gasteiger, "Temperature and Concentration Dependence of the Ionic Transport Properties of Lithium-Ion Battery Electrolytes", *Journal of The Electrochemical Society* **166** (14) A3079–A3097 (2019). DOI: 10.1149/2.0571912jes.

**Giấy phép:** open access, CC BY-NC-ND 4.0 (ghi ở tr. A3079).

**File:** `tai_lieu/Landesfeind2019_JES.pdf` (bản của nhà xuất bản, tải từ iopscience.iop.org; 20 trang PDF = 1 trang bìa + A3079–A3097). Text trích: `tai_lieu/toan_van_trich_xuat/Landesfeind2019_JES.txt`.

**Cách đọc:** đã đọc toàn bộ 19 trang bài (A3079–A3097). Phương trình [15] và Bảng II bị vỡ khi trích text nên đã render trang A3088 và A3090 thành ảnh để đọc **chữ và số in**. Không đọc giá trị nào từ đường cong. Supporting Information của bài (Figure S1–S3, Table S1: mật độ điện giải; phần "4. Error calculation") **chưa tải, chưa đọc** — không cần cho các hệ số dưới đây.

Số trang ghi dưới đây là số trang tạp chí (trang PDF = số trang − 3077).

---

## 1. Phạm vi đo và hiệu lực

| Mục | Nội dung | Trang |
|---|---|---|
| Điện giải | LiPF6 trong EC:DMC (1:1 w:w), **EC:EMC (3:7 w:w)**, EMC:FEC (19:1 w:w) | A3079 (tóm tắt) |
| Nồng độ | 0.1, 0.5, 1.0, 1.5, 2.0, 3.0 M ("base concentrations"); **khoảng hiệu lực 0.1–3.0 M** | A3080; Bảng II tr. A3090 |
| Nhiệt độ | −10 °C đến +50 °C, bước 10 °C. Riêng phép đo xung (D±, hệ số b): nhiệt độ thực là −7.5, +2.5, +12, +20, +30, +40, +50 °C (±1 °C) | A3079, A3081 |
| Đơn vị trong mọi hàm khớp | **c tính bằng mol/L (M), T tính bằng Kelvin** | A3088 (sau pt. [15]); A3092 |
| Định nghĩa TDF | TDF ≡ 1 + d ln f± / d ln c | A3079; pt. [5] tr. A3082 |
| Phương trình vận chuyển mà các tham số này thuộc về | pt. [1], [2] (mô hình Newman) — xem mục 4 | A3082 |
| Dữ liệu bị loại | Với **EC:EMC**, điểm 0.1 M bị loại khỏi phép khớp TDF và t+ (điện giải không bền với Li kim loại) | A3091, A3092 |
| Chất lượng khớp EC:EMC | R² = 0.997 (κ), 0.978 (D±), 0.943 (TDF), **0.823 (t+)** | Bảng II tr. A3090 |
| Cảnh báo của tác giả | Hàm (c, T) cho TDF và t+ "only serve as an approximation"; khi chỉ mô phỏng ở một nhiệt độ thì hàm khớp riêng từng nhiệt độ (Bảng III) "likely more reliable" | A3092 |

## 2. Dạng hàm (chép nguyên)

**Pt. [15], tr. A3088 — độ dẫn ion** (đọc từ ảnh trang):

```
κ(c,T) = p1·(1 + (T − p2)) · c · [ 1 + p3·√c + p4·(1 + p5·exp(1000/T))·c ] / [ 1 + c⁴·(p6·exp(1000/T)) ]   [mS/cm]
```

Thừa số `(1 + (T − p2))` in đúng như vậy trong bài gốc (không thiếu hệ số nào).

**Pt. [18], tr. A3090 — hệ số khuếch tán nhị phân:**

```
D±(c,T) = p1 · exp(p2·c) · exp(p3/T) · exp(p4/T · c) · 10⁻⁶   [cm²/s]
```

**Pt. [19], tr. A3092 — thermodynamic factor; pt. [20], tr. A3092 — transference number** (cùng một dạng đa thức):

```
TDF(c,T) = p1 + p2·c + p3·T + p4·c² + p5·c·T + p6·T² + p7·c³ + p8·c²·T + p9·c·T²
t+(c,T)  = p1 + p2·c + p3·T + p4·c² + p5·c·T + p6·T² + p7·c³ + p8·c²·T + p9·c·T²
```

**Pt. [21], [22], tr. A3096 — khớp riêng từng nhiệt độ:** `TDF(c) = p1·c² + p2·c + p3`; `t+(c) = p1·c² + p2·c + p3`.

## 3. Bảng II (tr. A3090) — hệ số cho EC:EMC (3:7 w:w), chép nguyên

Số trong ngoặc là khoảng tin cậy tương đối in trong bảng (chú thích bảng ghi 90 %; phần lời tr. A3089 ghi 95 %).

| Hàm | p1 | p2 | p3 | p4 | p5 | p6 | p7 | p8 | p9 | R² |
|---|---|---|---|---|---|---|---|---|---|---|
| κ, pt. [15] | 5.21E−01 (5 %) | 2.28E+02 (1 %) | −1.06E+00 (2 %) | **3.53E−01** (8 %) | −3.59E−03 (19 %) | 1.48E−03 (42 %) | – | – | – | 0.997 |
| D±, pt. [18] | 1.01E+03 (87 %) | 1.01E+00 (79 %) | −1.56E+03 (17 %) | −4.87E+02 (50 %) | – | – | – | – | – | 0.978 |
| TDF, pt. [19] | 2.57E+01 (123 %) | −4.51E+01 (57 %) | −1.77E−01 (122 %) | 1.94E+00 (99 %) | 2.95E−01 (60 %) | 3.08E−04 (120 %) | 2.59E−01 (71 %) | −9.46E−03 (67 %) | −4.54E−04 (67 %) | 0.943 |
| t+, pt. [20] | −1.28E+01 (94 %) | **−6.12E+00** (128 %) | 8.21E−02 (99 %) | 9.04E−01 (70 %) | 3.18E−02 (164 %) | −1.27E−04 (108 %) | 1.75E−02 (303 %) | −3.12E−03 (61 %) | −3.96E−05 (222 %) | 0.823 |

Ghi chú về bản in: chú thích Bảng II ghi nhầm "transference number (Eq. 19)"; cột trái của bảng ghi đúng "Eq. 20".

Hai cột còn lại của Bảng II (EC:DMC, EMC:FEC) không chép ở đây vì đồ án không dùng; có trong text trích.

### Bảng III (tr. A3095) — EC:EMC, khớp riêng từng nhiệt độ (p1·c² + p2·c + p3)

| T | TDF: p1 | p2 | p3 | R² | t+: p1 | p2 | p3 | R² |
|---|---|---|---|---|---|---|---|---|
| −10 °C | 2.45E−01 | 4.49E−01 | 3.41E−01 | 0.910 | 4.10E−02 | −3.63E−01 | −9.17E−02 | 0.477 |
| 0 °C | 7.23E−01 | 9.80E−02 | 5.00E−01 | 0.951 | 1.04E−01 | −3.38E−01 | 2.13E−01 | 0.293 |
| 10 °C | 7.36E−01 | −1.55E−01 | 8.63E−01 | 0.970 | 1.09E−01 | −4.12E−01 | 3.98E−01 | 0.632 |
| 20 °C | 6.65E−01 | −2.57E−01 | 1.03E+00 | 0.952 | 1.40E−01 | −5.74E−01 | 5.57E−01 | 0.768 |
| 30 °C | 3.70E−01 | 7.60E−01 | 7.17E−01 | 0.963 | 2.97E−02 | −2.10E−01 | 4.92E−01 | 0.802 |
| 40 °C | 1.85E−02 | 1.75E+00 | 4.80E−01 | 0.963 | −1.39E−02 | −9.01E−02 | 5.26E−01 | 0.864 |
| 50 °C | −3.29E−02 | 1.76E+00 | 6.75E−01 | 0.955 | −5.87E−03 | −1.30E−01 | 6.12E−01 | 0.906 |

(Li 2025 **không** dùng Bảng III; chép để đối chiếu.)

## 4. Vị trí của TDF trong phương trình điện giải (pt. [1], [2], tr. A3082)

```
ε·∂c/∂t − ∇·( (ε/τ)·D±(c)·∇c ) + ∇·( t+(c)/(z+ ν+ F) · i ) = 0                                        [1]
i = −(ε/τ)·κ(c)·∇Φ + (ν+ + ν−)/(z+ ν+) · (RT/F) · (ε/τ)·κ(c) · [1 + d ln f±(c)/d ln c] · (1 − t+(c)) · (1/c)·∇c   [2]
```

Với muối 1:1 (LiPF6): (ν+ + ν−)/(z+ν+) = 2, nên số hạng khuếch tán của dòng là `2·(RT/F)·κ_eff·TDF·(1 − t+)·∇ln c`. Các giá trị t+ và TDF trong bài được **tách ra từ hai tích** a ≡ TDF·(1 − t+) (pt. [9], tr. A3083) và b ≡ TDF·(1 − t+)² (pt. [11], tr. A3083), qua t+ = 1 − b/a (pt. [13]) và TDF = a²/b (pt. [14], tr. A3087). Vì vậy t+ của bài này chỉ có nghĩa khi dùng **kèm TDF** ở đúng vị trí trên.

## 5. Giá trị tại c = 1 M (tính bằng Python từ Bảng II, không đọc từ hình)

| Đại lượng | 20 °C (293.15 K) | 25 °C (298.15 K) | 30 °C (303.15 K) |
|---|---|---|---|
| κ [mS/cm] | 8.398 | **9.130** (= 0.9130 S/m) | 9.868 |
| D± [10⁻⁶ cm²/s] | 2.573 | **2.892** (= 2.892×10⁻¹⁰ m²/s) | 3.239 |
| TDF [–] | 2.071 | **2.182** | 2.286 |
| t+ [–] | 0.160 | **0.221** | 0.274 |

Kiểm tra việc chép dạng hàm bằng các con số **in trong phần lời** của bài (cho cột EC:DMC, cùng dạng hàm):

- κ(1 M, EC:DMC) tính từ Bảng II = 10.76 / 12.89 / 17.28 mS/cm ở 20 / 30 / 50 °C; bài in "10.8–12.9 mS/cm at 20–30 °C" (tr. A3090) và "∼17 mS/cm (1.0 M … EC:DMC … at +50 °C)" (tr. A3088). Khớp.
- t+(1 M, 20 °C, EC:DMC) từ Bảng II = 0.278; bài in "the fit suggests 0.28" (tr. A3092). Khớp.
- D±(EC:EMC) từ Bảng II: 0.1 M → 2.62 (−7.5 °C) … 7.69 (50 °C); 3 M → 0.24 … 1.82 ×10⁻⁶ cm²/s; bài in "≈2.3–7.4" và "≈0.2–1.6" (tr. A3090) cho số đo. Cùng cỡ (hàm khớp so với điểm đo).
- t+(1 M, EC:EMC): bài in số đo 0.16 ở 20 °C và "the fit suggests 0.22" (tr. A3092). Hàm Bảng II cho 0.160 ở 20 °C và 0.221 ở 25 °C. Con số 0.22 trùng với giá trị hàm ở 25 °C chứ không phải 20 °C; **KHÔNG RÕ** câu trong bài nhầm nhiệt độ hay nhầm số — không ảnh hưởng tới hệ số.
- Hàm khớp riêng từng nhiệt độ (Bảng III) tại 1 M: t+ = 0.123 (20 °C), 0.312 (30 °C); TDF = 1.438 (20 °C), 1.847 (30 °C). Lệch đáng kể so với hàm (c, T) — đúng như cảnh báo của tác giả về độ tin cậy.

Tính chất của hàm t+(c, T) Bảng II ngoài điểm 1 M (tính từ hệ số): âm ở nhiệt độ thấp (ví dụ −0.38 tại 1 M, −10 °C; −0.07 tại 1.5 M, 10 °C). Bài có bàn về t+ âm ở nhiệt độ thấp (tr. A3092–A3093). Ở 4 M (ngoài khoảng đo 0.1–3 M; Li 2025 (S12) cho phép tới 4 M) hàm là ngoại suy: TDF = 12.8, t+ = 0.45 tại 25 °C.

## 6. Đối chiếu với Li 2025 SI Note 10 (SI tr. 50) và O'Regan 2022

| Hệ số | Landesfeind Bảng II | Li 2025 SI in | O'Regan 2022 in | Mã nguồn tác giả Li 2025 (theo `gia_dinh.md`, `dac_ta_lao_hoa.md`) |
|---|---|---|---|---|
| κ: p1, p2, p3, p5, p6 | 0.521, 228, −1.06, −3.59×10⁻³, 1.48×10⁻³ | giống (kèm 0.1 để đổi mS/cm → S/m) | không in hệ số | giống |
| **κ: p4** | **0.353** | **0.8353** — lỗi in | không in | 0.353 |
| D±: p1…p4 | 1010, 1.01, −1560, −487 (×10⁻⁶ cm²/s = ×10⁻¹⁰ m²/s) | "10⁻¹⁰ · 1010 · e^{1.01c} · e^{−1560/T} · e^{c(−487)/T}" — đúng | không in | 1.01e3 × 1e-10 |
| TDF: p1…p9 | xem Bảng II | cả 9 hệ số giống | không in | – |
| **t+: p2** | **−6.12** | **−0.612** — lỗi in | không in | −6.12 |
| t+: 8 hệ số còn lại | xem Bảng II | giống | không in | – |

- Li 2025 như in, tại 1 M, 25 °C: κ = 2.452 S/m (đúng: 0.913 S/m); t+ = 5.729 (đúng: 0.221). t+ > 1 là phi vật lý.
- O'Regan 2022 (tr. 29, pt. [18]–[21]) **không in hệ số nào** ("The fitting parameters values p_i have been outlined elsewhere") nên không có "giá trị O'Regan" để so. Riêng **dạng hàm** O'Regan in lại có lỗi so với bài gốc: pt. [18] thiếu thừa số `·c` ở ngoài và in `p3·√c·p4·(…)` thay cho `p3·√c + p4·(…)·c`; pt. [20] in `p5·T` (thiếu c) và `p8·c²` (thiếu T); pt. [21] in `p8·c²` (thiếu T); Bảng 8 của O'Regan gán nhãn chéo (t+ → "Eq. [20]", TDF → "Eq. [21]"). Không dùng dạng in của O'Regan.

**Kết luận:** hai hệ số 0.8353 và −0.612 trong Li 2025 SI là lỗi in; giá trị đúng theo nguồn gốc là **0.353** và **−6.12** (trùng mã nguồn). Mọi hệ số khác của (S13)–(S16) đúng với Bảng II.
