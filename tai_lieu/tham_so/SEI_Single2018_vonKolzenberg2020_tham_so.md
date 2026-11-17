# Luật tăng trưởng SEI giới hạn bởi khuếch tán lithium interstitial — hai bài gốc mà Li 2025 SI Note 2 trích

Li 2025 SI Note 2 (SI tr. 33): "we follow the assumption made by Single et al.⁸ and von Kolzenberg et al.⁹ that the SEI reaction rate is limited by the diffusion of neutral lithium interstitials".

## 0. Tài liệu đã lấy và đã đọc

| Bài | Trích dẫn | Bản đã đọc | Giấy phép | File |
|---|---|---|---|---|
| **Single 2018** | F. Single, A. Latz, B. Horstmann, "Identifying the Mechanism of Continued Growth of the Solid–Electrolyte Interphase", *ChemSusChem* **11** (12) 1950–1955 (2018). DOI 10.1002/cssc.201800077 | **Bản thảo của tác giả** (4 trang) + Supporting Information (10 trang), lấy từ kho DLR elib.dlr.de/124806 (cùng nội dung với arXiv:1812.03841). **Không phải bản của nhà xuất bản**: bản Wiley bị chặn (HTTP 403), Unpaywall ghi bài là "green OA" với bản arXiv. Số trang dưới đây là số trang của bản thảo. | PDF không ghi giấy phép → KHÔNG RÕ | `tai_lieu/Single2018_DLR_manuscript.pdf`, `tai_lieu/Single2018_DLR_appendix.pdf`; text: `toan_van_trich_xuat/Single2018_DLR_manuscript.txt`, `…_appendix.txt` |
| **von Kolzenberg 2020** | L. von Kolzenberg, A. Latz, B. Horstmann, "Solid–Electrolyte Interphase During Battery Cycling: Theory of Growth Regimes", *ChemSusChem* **13** (15) 3901–3910 (2020). DOI 10.1002/cssc.202000867 | Bản của nhà xuất bản, 10 trang (tr. 3901–3910), lấy từ kho KIT (publikationen.bibliothek.kit.edu/1000128526) | CC BY (ghi ở tr. 3901) | `tai_lieu/vonKolzenberg2020_ChemSusChem.pdf`; text: `toan_van_trich_xuat/vonKolzenberg2020_ChemSusChem.txt` |

Đã đọc toàn bộ cả ba file. Supporting Information của von Kolzenberg 2020 (Table S1: tham số; Eq. SI-1…SI-7) **chưa tải, chưa đọc** → không dùng con số nào từ đó. Không đọc giá trị nào từ hình.

Lưu ý nếu người dùng muốn bản chính thức của Single 2018: https://doi.org/10.1002/cssc.201800077 (cần quyền truy cập Wiley). Nội dung phương trình dưới đây lấy từ bản thảo tác giả; chưa đối chiếu được từng ký tự với bản in.

---

## 1. Single 2018 — luật gốc (lưu trữ ở mạch hở, một lớp SEI đồng nhất)

Phần "Computational Methods", bản thảo tr. 3; SI mục 1, tr. 2–3.

| Pt. | Nội dung (chép nguyên) | Trang |
|---|---|---|
| (1) / (SI-1) | `L = (V/s) · Q_irr^SEI/(A·F) + L0` — L: độ dày SEI (một màng đồng nhất từ x = 0 tới x = L); V: "mean partial molar volume of the SEI"; **s: "mean stoichiometric coefficient of Li_I in the SEI formation reaction"**; A: diện tích bề mặt cực âm | bản thảo tr. 3; SI tr. 2 |
| (2) / (SI-4c) | `j_SEI^LiI = −F·D_LiI·∇c_LiI ≈ −F·D_LiI·(c_LiI|x=L − c_LiI|x=0)/L` [A/m²]; SI viết `= F·D_LiI·c_LiI/L` | bản thảo tr. 3; SI tr. 2 |
| – | `∂t Q_irr^SEI = A·j_SEI^LiI` | bản thảo tr. 3 |
| (4) | Cân bằng tại mặt điện cực/SEI: `μ_Li(LixC6) = μ_LiI,SEI = μ_LiI,SEI,0 + RT·ln(c_LiI|x=0 / c_LiI,max)`; "The electrochemical potential of Li in the electrode is equal to −F·U" | bản thảo tr. 3 |
| **(5)** | **`c_LiI|x=0 = c_LiI,0 · exp(−F·U/(R·T))`**; c_LiI,0: nồng độ interstitial tại U = 0 V; tại mặt SEI/điện giải `c_LiI|x=L = 0` ("assumption of transport limited growth") | bản thảo tr. 3 |
| (6d) | `Q_irr^SEI = A·Γ·sqrt(F·D_LiI·c_LiI,0·e^{−F·U(SoC)/(RT)}) · sqrt(t + τ) − Q_irr,0^SEI`, `Γ = sqrt(2sF/V)` | bản thảo tr. 3 |

Định nghĩa thế: **U = "Potential of the negative electrode vs. Li/Li+"** (SI Table SI-2, tr. 8), lấy từ đường OCV của cực âm theo SoC (bản thảo tr. 2); thí nghiệm là lưu trữ mạch hở nên không có quá thế.

Ghép (1), (2), (5): `j_SEI = F·D_LiI·c_LiI,0·exp(−F·U/(RT)) / L` và

```
dL/dt = V/(s·F) · j_SEI = V·D_LiI·c_LiI,0 · exp(−F·U/(R·T)) / (s·L)
```

(đây là phép thế đại số; nó cho lại đúng (6d) với Γ = sqrt(2sF/V), tức đã kiểm tra chéo với phương trình in).

Tham số in trong SI (Table SI-1, SI-2; SI tr. 8–9): s = 2 (phản ứng (SI-8): 2EC + 2Li⁺ + 2e⁻ → Li2EDC + R); D_LiI = 1.0×10⁻¹⁵ m²/s; c_LiI,0 = 15.00 "mmol m⁻³" (tham số khớp); L0 = 15.00 nm; V = 95.86 "µm³ mol⁻¹" (đơn vị in như vậy; 95.86 cm³/mol = 9.586×10⁻⁵ m³/mol mới hợp lý về thứ nguyên — **KHÔNG RÕ**, có lẽ lỗi đơn vị trong bản thảo); T = 323.15 K (50 °C); Φ0 = 800 mV. Ghi chú trong SI: "we cannot determine D_EC, κ and c_LiI,0 independently of A because they appear as products only".

So với Li 2025 SI Table 8: `c_int,Li = 15 mol/m³` (Single in 15 **mmol**/m³) và D_int ≈ 10⁻¹⁸ m²/s (Single: 10⁻¹⁵). Chỉ tích c·D có nghĩa và D_int của Li 2025 là tham số khớp riêng, nên đây không phải mâu thuẫn cần xử lý; chỉ ghi nhận.

## 2. von Kolzenberg 2020 — mở rộng cho pin đang chạy

| Pt. | Nội dung (chép nguyên; ký hiệu φ thay cho ký tự bị vỡ khi trích) | Trang |
|---|---|---|
| (3) | `j = j_int + j_SEI` | 3902 |
| (4) | `L_app = L_SEI − L_tun` (trừ đoạn electron xuyên hầm) | 3903 |
| (9) | Butler–Volmer cho xen cài: **`j_int = 2·j_0·sinh( F·η_int/(2RT) )`** | 3903 |
| (10) | `η_int = φ_S − U_0 − μ_Li+,SEI` — φ_S: thế điện cực; U_0: OCV; μ_Li+,SEI: "electrochemical potential of lithium ions **at the electrode–SEI interface**" | 3903 |
| (14), (15) | `η_SEI = φ_S − μ_Li+,SEI + μ_Li/F`; `μ_Li = μ_Li,0 + RT·ln(c_Li/c_Li,0)`, c_Li,0 = 1 mol/L | 3903–3904 |
| **(18)** | **`η̃_SEI = F/(RT) · (η_int + U_0 + μ_Li,0/F)`** — quá thế **không thứ nguyên** | 3904 |
| (19)–(21) | dạng đầy đủ với L_diff, L_mig (chuyển tiếp phản ứng → khuếch tán → điện di) | 3904 |
| (22) | `dL_SEI/dt = −(V_SEI/F)·j_SEI`, V_SEI: "mean molar volume of SEI components" (**không có hệ số 1/2**) | 3904 |
| **(25)** | Chế độ giới hạn bởi khuếch tán (L_diff ≪ L_app ≪ L_mig): **`j_SEI = −(c_Li,0·D·F / L_SEI) · e^{−η̃_SEI}`** | 3904 |
| (26) | `L_SEI = L_tun + sqrt( 2·V_SEI·c_Li,0·D·e^{−η̃_SEI}·t + (L_SEI,0 − L_tun)² )` | 3904 |
| – | "This form of SEI current and growth coincides with the form derived by Single et al. in the case of battery storage, that is, η_int = 0." | 3904 |

Từ (10): `η_int + U_0 = φ_S − μ_Li+,SEI`, tức thế của điện cực so với Li⁺ **tại mặt điện cực/SEI**. Số mũ của (25) là `−F·(φ_S − μ_Li+,SEI)/(RT)` cộng hằng số `μ_Li,0/(RT)` (hằng số này được gộp vào c_Li,0 theo cách Single định nghĩa c_LiI,0 tại U = 0 V). Bài giả thiết đẳng nhiệt (tr. 3903).

## 3. Trả lời các câu hỏi về Li 2025 SI (S2)–(S7)

### 3.1 Số mũ

- Cả hai bài gốc in số mũ **có F/(RT)**: `exp(−F·U/(RT))` (Single pt. (5)) và `e^{−η̃_SEI}` với `η̃_SEI = F/(RT)·(…)` (von Kolzenberg pt. (18), (25)).
- Li 2025 in `exp(−φ_s + φ_e)` (S2) và `e^{−(φ_s − φ_e)}` (S6), (S7): đối số có đơn vị vôn nên không dùng được nguyên văn. Dạng đúng thứ nguyên, theo nguồn gốc: **`exp(−F·(φ_s − φ_e)/(R·T))`**, T là nhiệt độ cell [K]. Trùng với mã nguồn (theo `dac_ta_lao_hoa.md` mục 3).
- Hệ số Arrhenius (S5) của Li 2025 là thừa số nhân thêm riêng của bài đó; hai bài gốc không có (Single: một nhiệt độ 50 °C; von Kolzenberg: đẳng nhiệt).

### 3.2 Thế nào đứng trong số mũ

- Single: U = thế cực âm so với Li/Li⁺ (mạch hở).
- von Kolzenberg: φ_S − μ_Li+,SEI, lấy Li⁺ tại mặt **điện cực/SEI**. Trong ngôn ngữ DFN có màng SEI điện trở, đó là `φ_s − φ_e − (sụt áp ôm qua màng)`; tức theo bài gốc sụt áp màng **có** được trừ.
- Li 2025 in `φ_s − φ_e` (không trừ η_SEI) và mã nguồn cũng không trừ (`dac_ta_lao_hoa.md` mục 3). Bản in và mã **thống nhất** với nhau; chỉ khác bài gốc ở số hạng sụt áp màng.
- Độ lớn của khác biệt (tính từ số in của Li 2025 SI Table 6 và Table 8): diện tích bề mặt hạt cực âm a_n·L_n·A = (3·0.75/5.86×10⁻⁶)·8.52×10⁻⁵·(1.58·0.065) ≈ 3.36×10³ m²; ở 5 A mật độ dòng trung bình ≈ 1.5×10⁻³ A/m²; ρ_SEI·L_SEI = 2×10⁵·2.47×10⁻⁸ = 4.9×10⁻³ Ω·m² → sụt áp ≈ 7×10⁻⁶ V → F·ΔV/(RT) ≈ 3×10⁻⁴, tức tốc độ SEI đổi cỡ 0.03 % (giá trị trung bình; dòng cục bộ có thể lớn hơn vài lần). Không đáng kể.

### 3.3 Độ dày nào ở mẫu số

- Single: L = độ dày **toàn bộ** màng SEI (một lớp đồng nhất). von Kolzenberg: L_app = L_SEI − L_tun, xấp xỉ L_SEI trong (25). Không bài nào có hai lớp trong/ngoài.
- Li 2025 (S2) in L_SEI^inner cho dòng SEI tổng; (S6) in L^inner, (S7) in L^outer. Mã nguồn dùng L_outer. Vì α = 0.5, V̄ hai lớp bằng nhau và điều kiện đầu bằng nhau nên L_inner ≡ L_outer ở mọi thời điểm → mọi cách viết cho cùng kết quả số.
- Hệ quả so với bài gốc: Li 2025 dùng **nửa** độ dày màng làm quãng khuếch tán. Với cùng c·D, tốc độ tăng độ dày tổng gấp đôi công thức của Single. Vì c·D là tham số khớp nên đây là định nghĩa mô hình của Li 2025, không phải lỗi.

### 3.4 Hệ số 1/2 hay 1/4

- Bài gốc Single: `dL/dt = V/(s·F)·j_SEI` với s = 2 → `dL/dt = c·D·V·e^{…}/(2·L)` cho **một** lớp nhận **toàn bộ** dòng. (von Kolzenberg (22) viết V_SEI/F không có 1/2 — khác định nghĩa thể tích mol, tính theo mỗi electron.)
- Li 2025 in ba mệnh đề: (i) (S2) `j_SEI = c·D·F/L_inner·e^{…}`; (ii) (S3), (S4): mỗi lớp nhận `0.5·j_SEI` (Table 8: α = 0.5); (iii) vế thứ nhất của (S6)/(S7): `dL_lớp/dt = j_lớp/(2F)·V̄` (Table 8: z_SEI = 2). Ghép (i)–(iii) bằng đại số: **`dL_lớp/dt = c·D·V̄·e^{…}/(4·L)`**.
- Vế thứ hai của (S6)/(S7) in `c_int/(2·L)·D·V̄·e^{…}`, mâu thuẫn hệ số 2 với chính (S2), (S3) và vế thứ nhất. Dạng `1/(2L)` này trùng công thức một lớp của Single (s = 2, không chia đôi dòng) — tức có vẻ được chép từ dạng một lớp mà quên hệ số 0.5 của (S3)/(S4).
- Mã nguồn: `1/(4·L_outer)` (`dac_ta_lao_hoa.md` mục 3, C3).
- **Kết luận:** giải quyết được. Hệ số đúng cho mô hình hai lớp của Li 2025 là **1/4** (z_SEI = 2 theo bài gốc và Table 8; chia đôi dòng theo (S3)/(S4)). Bài gốc xác nhận thừa số `V̄/(z·F)` với z = 2 nhưng không thể tự nó phân xử việc chia hai lớp (bài gốc không có hai lớp) — phần đó dựa vào chính các phương trình in của Li 2025 và mã nguồn.

### 3.5 Dạng để cài (MATLAB)

```
j_SEI        = − c_int·D_int·F / L_inner · exp( −F·(φ_s − φ_e)/(R·T) ) · exp( E_SEI/(R·T_ref) − E_SEI/(R·T) )     [A/m², < 0]
dL_inner/dt  = dL_outer/dt = c_int·D_int·V̄_SEI / (4·L_inner) · exp( −F·(φ_s − φ_e)/(R·T) ) · exp( E_SEI/(R·T_ref) − E_SEI/(R·T) )
```

(L_inner ≡ L_outer; dấu của j_SEI theo quy ước của `dac_ta_lao_hoa.md`.)

## 4. Thông tin phụ đọc được (liên quan đồ án)

- von Kolzenberg pt. (9), tr. 3903 in Butler–Volmer dạng chuẩn `j = 2·j_0·sinh(F·η/(2RT))` — dùng để đối chiếu lỗi in ở Li 2025 SI Table 2 (xem `doi_chieu_tham_so.md`, mục BV).
- von Kolzenberg tr. 3904, 3907: mô hình đầy đủ còn có chế độ giới hạn bởi phản ứng (SEI mỏng, L_app ≪ L_diff) và bởi điện di (SEI dày, L_app → L_mig, pt. (27)); Li 2025 chỉ lấy chế độ khuếch tán (25).
- Single SI Table SI-2 (tr. 8): thể tích mol SEI lấy theo "LiEDC" (95.86, đơn vị in "µm³ mol⁻¹"); trùng ví dụ V̄_SEI = 9.585×10⁻⁵ m³/mol trong Li 2025 SI Note 9.
