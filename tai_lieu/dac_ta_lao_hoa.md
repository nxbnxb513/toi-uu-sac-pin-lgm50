# Đặc tả mô hình lão hoá "5 coupled" (Li et al. 2025) cho LG M50T — theo bài báo trước, bài gốc khi bài in sai, code khi bài không ghi

> Tài liệu này là đặc tả của mô hình lão hoá **đã cài** trong DFN MATLAB (`src/dfn/`, bật bằng `dfn_params(struct('aging', true))`).
> Mô hình: Li, Kirkaldy, Oehler, Marinescu, Offer, O'Kane, *Nat. Commun.* 16:2776 (2025), kế thừa O'Kane et al. 2022 (PCCP 24:7909).
> **Viết lại ngày 17/11/2026 theo quy tắc 2 của người dùng** (bản trước viết theo mã nguồn của tác giả).
> Không cơ chế nào bị bỏ hay đơn giản hoá. Văn xuôi tiếng Việt, ký hiệu tiếng Anh.

## 0. Cách ghi nhãn

Mỗi phương trình và mỗi tham số có **đúng một** nhãn:

| Nhãn | Nghĩa | Ví dụ |
|---|---|---|
| **[BÀI]** — theo bài báo | Li 2025 (bài chính, SI) in, hoặc O'Kane 2022 / Kirkaldy 2024 in cho mục Li 2025 kế thừa / mô tả thí nghiệm | (S10) mạ lithium |
| **[GỐC]** — theo bài gốc (bài in sai) | Li 2025 in sai rõ ràng; bài gốc mà nó trích dẫn (hoặc đại số trên chính các phương trình của nó) phân xử — xem `doi_chieu_tham_so.md` | số mũ SEI có F/(RT) |
| **[CODE]** — theo code (bài không ghi) | không bài nào ghi; lấy từ mã nguồn của tác giả (Zenodo 14995785 + PyBaMM fork `GEM-2_NC`, định nghĩa ở `gia_dinh.md`) | t₀ = 3600 s trong luật Paris |
| **[GĐ]** — giả định | không có trong bài lẫn mã, hoặc phải chọn giữa hai chỗ bài in mâu thuẫn; ghi mã GD ở `gia_dinh.md` | nồng độ khi cạn khô, trường hợp 3–5 |

Mã GD tương ứng ở `tai_lieu/gia_dinh.md` (GD-50 … GD-62 cho phần lão hoá). Ký hiệu nguồn: [P] Li 2025 bài chính (tr. = trang PDF); [SI] Li 2025 SI; [OK] O'Kane 2022; [K24] Kirkaldy 2024; [S18] Single 2018; [vK] von Kolzenberg 2020; [Z] script Zenodo 14995785 (`Fun_NC.py`, `Get_Input_files.ipynb`, `Reload_Exp*.ipynb`); [ZD] file nhỏ trong zip dữ liệu 835 MB của cùng bản ghi (file đầu vào CSV, log, xlsx tóm tắt); [SD] `Source_Data.zip` (bảng số dưới các hình); [PB] PyBaMM fork `RuiheLi/PyBaMM` nhánh `GEM-2_NC` (v23.4.1). Mã nguồn chỉ đọc, không chạy.

**Thứ tự ưu tiên khi bài và code khác nhau:** bài in → (nếu in sai) bài gốc → (nếu bài không ghi) code. Những chỗ code khác bài được liệt kê ở mục 12 để người đọc thấy mô hình MATLAB **khác** lần chạy của tác giả ở đâu.

---

## 1. Mô hình "5 coupled" — các cơ chế và tuỳ chọn

| Cơ chế | Có trong "5 coupled" | Nhãn | Ghi chú |
|---|---|---|---|
| SEI hai lớp, giới hạn bởi khuếch tán interstitial (cực âm) | có | [BÀI] [SI] Note 2 | dạng số mũ [GỐC], mục 3 |
| SEI trên vết nứt (cực âm) | có | [BÀI] [SI] Note 4 (S20) | hệ số [GỐC], mục 6.2 |
| Mạ lithium bán thuận nghịch + lithium chết (cực âm) | có | [BÀI] [SI] Note 3 | α [GỐC], mục 4 |
| Ứng suất trong hạt (cả hai cực) | có | [BÀI] [SI] Note 4 (S14)–(S17) | đánh giá tại bề mặt [CODE], mục 5 |
| Nứt hạt (luật Paris) | **chỉ cực âm** | [CODE] GD-52 | bài không cho k_cr cực dương; code: dương "swelling only" |
| LAM do ứng suất | cả hai cực | [BÀI] [SI] Note 5 ("in either electrode") | dấu [GỐC], β/t₀ [CODE], mục 7 |
| Đổi độ xốp do SEI + SEI vết nứt + Li mạ + Li chết | có | [BÀI] [SI] (S24)–(S25) | mục 8 |
| Tiêu thụ dung môi + cạn khô (dry-out) có reservoir | có | [BÀI] [SI] Note 6, Table 4 | khoảng Δt [CODE], nồng độ [GĐ], mục 10 |
| Điện trở màng SEI (phân bố theo x) | có | [BÀI] (S9) | |
| Khuếch tán do ứng suất trong hạt | có | [CODE] GD-10 | bài không nhắc; đã có trong DFN |
| Hysteresis OCP | cực dương | [BÀI] (S46)–(S47) | cực âm: một nhánh delithiation — quyết định người dùng GD-40 |
| Nhiệt lumped | có | dạng 0D [CODE] GD-12 | đã có trong DFN |

Mỗi biến lão hoá định nghĩa **tại từng nút x** của điện cực (không lấy trung bình theo x) — [CODE] (PyBaMM `x-average side reactions = false`); bài không nói.

---

## 2. Ghép vào DFN

### 2.1 Quy ước

- `j` [A/m²] mật độ dòng trên một đơn vị diện tích bề mặt hạt, **dương khi Li rời hạt** (anod). SEI và mạ là phản ứng khử ⇒ `j_SEI < 0`, `j_SEI,cr < 0`; `j_Li < 0` khi mạ, `> 0` khi hoà tan. (Quy ước dấu của DFN dự án; [SI] viết độ lớn.)
- `δφ = φ_s − φ_e` tại nút x cực âm. `T` = nhiệt độ cell (lumped). `I > 0` khi xả, 1C = 5 A ([SI] Note 9) [BÀI].

### 2.2 Cân bằng dòng giao diện tại mỗi nút x cực âm

```
a_n          = 3 eps_s,n / R_n                                         [BÀI] [SI] Note 2, (S9) Note 9
S            = 1 + 2 l_cr w_cr rho_cr                                  [BÀI] (S8) Note 9
j_tot        = j_int + j_SEI + (S − 1) j_SEI,cr + j_Li                 SEI, mạ: [BÀI] (S9) "total interfacial current";
                                                                       cách ghép SEI vết nứt với diện tích (S − 1) a_n: [CODE] (GD-51)
d i_e/dx     = a_n j_tot ;   d i_s/dx = −a_n j_tot                    [BÀI] SI Table 2
−D_s ∂c_s/∂r |_R = j_int / F                                           chỉ dòng xen cài vào hạt: [CODE] (GD-51)
eta_n        = φ_s − φ_e − U_n − ρ_SEI L_SEI j_tot                     [BÀI] (S9)
j_int        = 2 j_0 sinh(F eta/(2RT))                                 [GỐC] GD-21
```
Cực dương: không có phản ứng phụ ([BÀI]: các Note 2–3 chỉ cho cực âm), `a_p = 3 eps_s,p/R_p`.

### 2.3 Điện giải khi độ xốp thay đổi

`∂(ε c_e)/∂t = −∂N_e/∂x + a j_tot/F` — dạng bảo toàn **[CODE]** (PyBaMM `full_diffusion.py`; SI Table 2 in dạng ε không đổi). Cài bằng `ε ∂c_e/∂t = −∂N_e/∂x + a j_tot/F − c_e ∂ε/∂t`, với `∂ε/∂t` tính giải tích từ vế phải lão hoá (mục 8). Dạng này giữ lithium điện giải bảo toàn chính xác (GD-62).

### 2.4 Nhiệt

Phản ứng phụ không sinh nhiệt: SI Table 3 chỉ có `q_r` của phản ứng chính — **[BÀI]**. Khi cạn khô làm giảm diện tích, nhiệt sinh trên thể tích điện cực còn lại vẫn chia cho `L_tot` như cũ, `V_cell`, `A_cool` không đổi — [CODE].

---

## 3. Cơ chế 1 — SEI hai lớp (Li 2025 SI Note 2)

Biến trạng thái tại mỗi nút x cực âm: `L_inner`, `L_outer` [m].

```
j_SEI          = −(c_int D_int F / L_inner) · exp(−F (φ_s − φ_e)/(R T)) · Arr      (S2)
Arr            = exp(E_SEI/(R T_ref) − E_SEI/(R T)),  T_ref = 298.15 K              (S5)
j_SEI,inner    = α j_SEI ;  j_SEI,outer = (1 − α) j_SEI ,  α = 0.5                  (S3)-(S4)
dL_inner/dt    = −j_SEI,inner V̄_SEI^inner/(z_SEI F)                                 (S6) vế 1
dL_outer/dt    = −j_SEI,outer V̄_SEI^outer/(z_SEI F)                                 (S7) vế 1
L_SEI          = L_inner + L_outer                                                  (S8)
η_SEI          = ρ_SEI j_tot L_SEI                                                  (S9)
```

| Mục | Nhãn | Căn cứ |
|---|---|---|
| Dạng (S2), (S3)–(S5), (S8), (S9); L_inner ở mẫu số | [BÀI] | [SI] tr. 33–34. (Code dùng L_outer; vì α = 0.5, V̄ bằng nhau, điều kiện đầu bằng nhau nên L_inner ≡ L_outer — doi_chieu S4.) |
| Số mũ `−F(φ_s − φ_e)/(RT)` (bài in `−(φ_s − φ_e)`, sai thứ nguyên) | [GỐC] | [S18] pt. (5); [vK] pt. (18), (25) — doi_chieu S1 |
| `φ_s − φ_e` **không** trừ η_SEI | [BÀI] | (S2) như in (doi_chieu S2) |
| Hệ số mỗi lớp: gộp lại `dL/dt = c_int D_int V̄/(4 L) · e^{…}` (bài in vế 2 của (S6)/(S7) là `c_int/(2L)`) | [GỐC] | đại số trên (S2)+(S3)+vế 1 của (S6), z = 2 ([S18] pt. (1), SI Table SI-2) — doi_chieu S3 |
| z_SEI = 2 | [BÀI] | [SI] Table 8 ([S18] cũng 2) |
| T trong Arrhenius và số mũ = nhiệt độ cell | [CODE] | bài không nói T nào; DFN có một nhiệt độ |

Cài đặt: `src/dfn/dfn_side_reactions.m` (dòng), `src/dfn/dfn_aging_rhs.m` (độ dày).

---

## 4. Cơ chế 2 — Mạ lithium bán thuận nghịch + lithium chết (Li 2025 SI Note 3)

Biến trạng thái tại mỗi nút x cực âm: `c_Li`, `c_dl` [mol/m³ điện cực].

```
η_pl     = φ_s − φ_e − η_SEI                                                          (S10)
j_Li     = F k_Li [ c_Li exp(α_a,Li F η_pl/(RT)) − c_e exp(−α_c,Li F η_pl/(RT)) ]       (S10)
∂c_Li/∂t = −a_n j_Li/F − ∂c_dl/∂t                                                      (S11)
∂c_dl/∂t = γ c_Li                                                                      (S12)
γ        = γ_0 L_SEI,0 / L_SEI                                                         (S13)
```

| Mục | Nhãn | Căn cứ |
|---|---|---|
| (S10)–(S13), c_e cục bộ, a_n hiện thời | [BÀI] | [SI] tr. 35 |
| α_a,Li = 0.35 (hoà tan), α_c,Li = 0.65 (mạ); bài ghi "α_a,Li = 0.65" ở Table 8 | [GỐC] | [OK] bảng tham số: α_a = 0.35, α_c = 0.65 — doi_chieu P1 |
| Không Arrhenius cho k_Li, γ_0 | [BÀI] | (S10)–(S13) không có |
| L_SEI,0 trong γ = tổng độ dày ban đầu thực dùng (mục 11.2) | [CODE] | giá trị L_SEI,0 theo GD-02 |
| c_Li(0) = 0 | [BÀI] | [SI] Table 8 |

---

## 5. Cơ chế 3a — Ứng suất trong hạt (Li 2025 SI Note 4, (S14)–(S17))

```
σ_r = 2ΩE/(1 − ν) · [c_avg(R) − c_avg(r)]                         (S14)
σ_t = ΩE/(1 − ν) · [2 c_avg(R) + c_avg(r) − c̄/3]                  (S15)
c_avg(r) = 1/(3 r³) ∫_0^r c̄ r² dr ,   c̄ = c − c_ref                (S17)
σ_h = (σ_r + 2σ_t)/3                                               (S22)
```
Tại bề mặt hạt (r = R): `σ_r = 0`, `σ_t = ΩE/(3(1 − ν)) · (c_rav − c_surf)` với `c_rav = (3/R³)∫_0^R c r² dr` là trung bình thể tích; `σ_h = (2/3)σ_t`.

| Mục | Nhãn | Căn cứ |
|---|---|---|
| (S14), (S15), (S17), (S22) và hệ số Ω, E, ν, c_ref = 0 | [BÀI] | [SI] tr. 36, Table 6. Thay r = R vào (S15) với c_avg của (S17) cho đúng biểu thức bề mặt ở trên (tự kiểm đại số) |
| Đánh giá ứng suất **tại bề mặt hạt** cho luật nứt và LAM | [CODE] | bài không ghi vị trí; code dùng giá trị bề mặt (GD-63) |
| c_rav tính qua trạng thái `x_av` (trung bình thể tích của hạt rời rạc, dx_av/dt = −3 j_int/(R F c_max), bất biến tuyến tính của rời rạc thể tích hữu hạn) | [GĐ] (lựa chọn số học) | giống hệt Σθ·V_shell/ΣV_shell; selftest kiểm lệch < 10⁻⁶; tránh hàng Jacobian dày (GD-63) |

---

## 6. Cơ chế 3b — Nứt hạt và SEI trên vết nứt

### 6.1 Nứt (luật Paris) — chỉ cực âm

Biến trạng thái: `l_cr` [m] tại mỗi nút x cực âm.

```
dl_cr/dt = (k_cr/t_0) · (σ_t b_cr √(π l_cr))^{m_cr}   khi σ_t > 0 ; = 0 khi σ_t ≤ 0          (S18)
a_cr     = 2 l_cr w_cr ρ_cr a_n = (S − 1) a_n                                               (S8), (S25)
```

| Mục | Nhãn | Căn cứ |
|---|---|---|
| (S18), σ_t > 0 | [BÀI] | [SI] tr. 36 |
| t_0 = 3600 s (bài: "time for one cycle", không cho giá trị) | [CODE] | `crack_propagation.py` "/ 3600" (GD-53) |
| k_cr = 5.29×10⁻²⁵, hằng số, không Arrhenius (bài không in đơn vị) | [BÀI] giá trị (Table 3); đơn vị [CODE] `m/(Pa·m^0.5)^m_cr` | GD-53 |
| Diện tích vết nứt theo (S8)/(S25) `2 l w ρ a_n`; **không** dùng (S19) `da_cr/dt = a ρ w/t_0 · dl/dt` | [BÀI] | (S19) sai thứ nguyên (thừa 1/t_0, thiếu hệ số 2 so với (S8), (S25), (S27) của chính bài) |
| Cực dương không nứt | [CODE] | Table 9 có tham số nứt cực dương nhưng Table 3 chỉ fit k_cr cực âm; code "swelling only" (GD-52) |
| Sự kiện dừng `l_cr ≥ R_n` | [CODE] | |
| l_cr(0) = 2×10⁻⁸ m, w_cr = 1.5×10⁻⁸ m, ρ_cr = 3.18×10¹⁵ m⁻², b_cr = 1.12, m_cr = 2.2 | [BÀI] | [SI] Table 9 |

### 6.2 SEI trên vết nứt

Biến trạng thái: `L_inner,cr`, `L_outer,cr` [m] tại mỗi nút x cực âm.

```
j_SEI,cr        = −(c_int D_int F / L_inner,cr) · exp(−F(φ_s − φ_e)/(RT)) · Arr
dL_inner,cr/dt  = −α j_SEI,cr V̄/(z F) − (dl_cr/dt) L_inner,cr / l_cr
dL_outer,cr/dt  = −(1 − α) j_SEI,cr V̄/(z F) − (dl_cr/dt) L_outer,cr / l_cr                  (S20)
```

| Mục | Nhãn | Căn cứ |
|---|---|---|
| Cùng mô hình SEI trên vết nứt ("apply the same SEI growth model on the cracks"); số hạng "lan rộng" `−(∂l_cr/∂t)L/l_cr` | [BÀI] | [SI] tr. 37 |
| Số mũ F/(RT), hệ số 1/4 mỗi lớp (bài in `c_int/(2 L_SEI,cr)`) | [GỐC] | như mục 3 (doi_chieu S1, S3) |
| Tách hai lớp trên vết nứt | [CODE] | (S20) viết một độ dày; code giữ hai lớp như bề mặt — không đổi kết quả vì α = 0.5 |
| Điều kiện đầu `L_inner,cr(0) = L_outer,cr(0) = L_SEI,0` mỗi lớp | [BÀI] | (S7) Note 9 |
| Ghép dòng `a_n (S − 1) j_SEI,cr` vào j_tot; LLI | [CODE] | GD-51 |
| Số hạng "lan rộng" giữ thể tích SEI trên vết nứt: d[(S − 1)L_cr]/dt chỉ còn phần tăng trưởng | (hệ quả đại số) | |

---

## 7. Cơ chế 4 — LAM do ứng suất (cả hai cực) (Li 2025 SI Note 5)

Biến trạng thái: `eps_s,n` (mỗi nút cực âm), `eps_s,p` (mỗi nút cực dương).

```
∂eps_s/∂t = −(β/t_0) (σ_h/σ_c)^{m_2}   khi σ_h > 0 ; = 0 khi σ_h ≤ 0          (S21), (S22)
a_k = 3 eps_s,k / R_k
```

| Mục | Nhãn | Căn cứ |
|---|---|---|
| (S21) dạng luỹ thừa, σ_h > 0, cả hai cực | [BÀI] | [SI] tr. 38 |
| **Dấu giảm** (bài in `∂ε_a/∂t = +β/t_0(…)`) | [GỐC] | [OK] tr. 10–11: (22) ước lượng "the decrease in the accessible volume fraction" |
| β [1/s] dùng trực tiếp (t_0 ≡ 1 s): bài in β/t_0 nhưng không cho t_0, và Table 3 ghi β đơn vị 1/s | [CODE] | `loss_active_material.py` (GD-53) |
| σ_h tại bề mặt (mục 5) | [CODE] | GD-63 |
| β_n = 2.84×10⁻⁹, β_p = 2.98×10⁻¹⁸ 1/s; m_2 = 2; σ_c = 60 / 375 MPa | [BÀI] | Table 3; SI Table 9 |
| LAM → a = 3ε_s/R | [BÀI] | định nghĩa a ở Note 2, Note 9 |
| Nồng độ Li trong hạt còn lại không đổi ⇒ Li trong phần vật liệu mất thành LLI; độ xốp **không** tăng khi ε_s giảm; σ_s hiệu dụng không đổi (Bruggeman pha rắn 0) | [CODE] | `base_active_material.py`; (S24) chỉ có lớp lắng đọng |

---

## 8. Độ xốp cực âm (Li 2025 SI Note 6, (S24)–(S25))

```
∂ε_n/∂t   = −∂(L_total a_n)/∂t                                                        (S24)
L_total   = L_SEI + 2 l_cr w_cr ρ_cr L_SEI,cr + c_Li V̄_Li/a_n + c_dl V̄_Li/a_n             (S25)
⇒ ε_n(t)  = ε_n,0 − [ (L_SEI + (S − 1) L_SEI,cr) a_n + (c_Li + c_dl) V̄_Li ]_0^t
```
`L_SEI,cr = L_inner,cr + L_outer,cr`; `a_n` hiện thời. Màng ngăn, cực dương: độ xốp không đổi ("pore volume change can only occur in the negative electrode").

| Mục | Nhãn | Căn cứ |
|---|---|---|
| (S24)–(S25) với a_n hiện thời | [BÀI] | [SI] tr. 40. **Code khác:** dùng `a_typ = 3ε_s,n,0/R_n` hằng (mục 12, D2). Khác nhau chỉ khi LAM_NE do ứng suất ≠ 0 (cỡ 1–3 % của a_n) |
| ε_n,0 (BOL) | [CODE] | GD-02 (mục 11.2) |
| V̄_Li = 1.3×10⁻⁵ m³/mol (Li chết cùng V̄) | [BÀI] | Table 8; (S25) "same as that of active lithium" |
| Sự kiện dừng ε_n ≤ 0 | [CODE] | |

---

## 9. Sổ sách lithium và chỉ số

Mô hình MATLAB có thêm các **biến sổ sách** (không hồi tiếp): `n_SEI`, `n_SEI,cr` [mol/m³] (tích phân `−a_n j_SEI/F`, `−(S−1) a_n j_SEI,cr/F`), `n_LAM,n`, `n_LAM,p` [mol/m²] (tích phân `−Σ_x (∂ε_s/∂t) c_rav dx`), `Q_thr` = ∫|I|dt [Ah]. Hàm `dfn_li_inventory.m` cộng:

```
Li_tổng = A Σ_x [ε_s,n c̄_n dx] + A Σ_x [ε_s,p c̄_p dx] + A Σ_x [ε_e c_e dx]
        + A Σ_x [(n_SEI + n_SEI,cr + c_Li + c_dl) dx] + A (n_LAM,n + n_LAM,p)
        (+ Li⁺ trong reservoir + Li trong phần điện cực đã khô, mục 10)
```
Tổng này **bất biến chính xác** của hệ bán rời rạc (mỗi số hạng thay đổi đúng bằng dòng chảy vào số hạng khác); selftest kiểm ≤ 10⁻⁶ tương đối qua cả chu kỳ, kể cả khi ép mạ (k_Li × 1000).

Chỉ số tại RPT (lấy ở **cuối bước xả 0.1C**) — [CODE] (`Get_SOH_LLI_LAM`), trừ ghi chú:
- `LLI = 1 − n_Li,hạt / n_Li,hạt(RPT0)`; `LAM_k = 1 − C_k/C_k(RPT0)`, `C_k = A Σ ε_s dx c_max F/3600`.
- `SOH = Q_xả,0.1C / 4.865 Ah` — số cố định in trong bài (code: 4.86491 Ah); người dùng chốt 17/11/2026 (GD-60) dùng cho mọi mô phỏng. Cột phụ `SOH_rpt0_pct` = chuẩn hoá theo RPT0 của chính mô hình.
- `R_0.1s = (V_1 − V_2)/(I_2 − I_1)`, xung GITT thứ 12, V_2 tại 0.1 s sau khi đặt dòng — [BÀI] [SI] (S1) Note 1. (Code lấy mẫu đầu tiên của bước xả, tức bước nhảy tức thời.)
- Phân rã LLI: SEI, SEI vết nứt, mạ còn lại, chết, LAM, cạn khô, điện giải — từ sổ sách (không suy ra bằng hiệu số như code).

---

## 10. Cơ chế 5 — Tiêu thụ dung môi / cạn khô (Li 2025 SI Note 6, (S26)–(S43), Table 4)

Lớp bọc ngoài bộ giải (bài: "coding wrapper … over a time interval Δt"). Biến: `V_res`, `c_e,res`, `c_EC,res` (reservoir), `A_cell` (diện tích điện cực), `c_EC` (jelly roll), và `c_e(x)` của DFN. Cài: `src/dfn/dfn_dryout_update.m`.

Sau mỗi khoảng (đầu khoảng: trạng thái y₀, cuối: y₁, cùng A):
```
V_e        = V_pore(y₀)                                                   (S34)
dV_pore    = V_pore(y₁) − V_pore(y₀) = d ∫ ε_n A dx                         (S26)
dV_EC      = −2 V̄_EC · d ∫ (L_SEI + 2 l w ρ L_SEI,cr)/V̄_SEI · a_n A dx      (S27)-(S30)
dV_need    = dV_pore − dV_EC                                               (S31)
Trường hợp (Table 4):
 1  dV_need > 0, V_res ≥ dV_need:      dV_add = dV_need, dV_sq = 0, R_dry = 1
 2  dV_need > 0, V_res < dV_need:      dV_add = V_res,   dV_sq = 0, R_dry < 1 (cạn khô)
 3  dV_need = 0:                        không trao đổi
 4  dV_need < 0, đã khô (A < A_max):    thấm ướt lại, R_dry > 1
 5  dV_need < 0, A = A_max:             dV_sq = −dV_need (ép ra reservoir), R_dry = 1
dV_e       = dV_EC + dV_add − dV_sq ;  V_e(t+dt) = V_e + dV_e ;  dV_res = −dV_add + dV_sq    (S32)-(S36)
R_dry      = V_e(t+dt) / V_pore(t+dt) ;  A_cell ← R_dry A_cell                               (S37)-(S38)
c_e,res, c_EC,res, c_e^avg, c_EC theo (S39)-(S42);  c_e(x) ← c_e(x) · c_e^avg(t+dt)/c_e^avg(t)   (S43)
```

| Mục | Nhãn | Căn cứ |
|---|---|---|
| (S24)–(S38), (S39)–(S40), (S42)–(S43), 5 trường hợp | [BÀI] | [SI] tr. 39–43, Table 4 tr. 21 |
| dV_EC gồm cả SEI trên vết nứt, a_n hiện thời | [BÀI] | (S27)–(S30). **Code khác:** chỉ trừ SEI bề mặt khỏi c_EC (mục 12, D3) |
| EC: 1 mol EC / 1 mol Li (2 EC / 1 phân tử SEI, z_SEI = 2); mạ/Li chết không tiêu thụ EC | [BÀI] | (S23), (S27) |
| Nồng độ Li⁺ ở trường hợp 3–5: dùng **(S41)** (Li⁺ cô đặc khi thể tích EC mất), không dùng các ô "c_e không đổi" của Table 4 | [GĐ] GD-55 | Table 4 mâu thuẫn với (S41) ở trường hợp 3–5; chỉ (S41) bảo toàn Li⁺. Đọc `c_e^avg(t)·V_e(t)` = lượng Li⁺ trong jelly roll lúc cập nhật, `c_e^avg(t)` = trung bình theo thể tích lỗ ⇒ (S43) bảo toàn Li chính xác |
| Trường hợp 4: A không vượt A_max; phần thể tích dư ép ra reservoir | [GĐ] GD-56 | bài không nói |
| Khoảng Δt: một lần trước mỗi ageing set và một lần trước mỗi RPT | [CODE] GD-54 | bài không cho Δt; code `Update cycles for ageing = Ageing cycles between RPT` |
| R_exc = 1.0 ⇒ V_res(0) = (R_exc − 1)·V_pore(0) = 0 (không có reservoir) | giá trị [BÀI] Table 8; định nghĩa [CODE] GD-54 | bài in "Initial excessive electrolyte amount 1.0" không định nghĩa |
| c_EC chỉ theo dõi, không hồi tiếp | [BÀI] | SEI interstitial không có c_EC; tính chất điện giải không phụ thuộc EC |
| Li trong phần điện cực bị khô (cả hai cực, hạt + SEI + mạ + LAM) chuyển vào sổ "cạn khô" | (sổ sách) | LAM_NE = LAM_PE do cạn khô ([P] tr. 6) |
| c_EC,0 = 4541, c_e,res,0 = 1000, c_EC,res,0 = 4541 mol/m³, V̄_EC = 6.667×10⁻⁵ | [BÀI] | SI Table 6, 8 |

Khác code (mục 12, D3–D5): nhánh "ép ra" của code không trừ Li⁺ khỏi jelly roll (ở đây trừ, theo (S39), (S41)); code không có thấm ướt lại (trường hợp 4).

---

## 11. Tham số ("5 coupled", nhất quán với Li 2025 Table 3)

### 11.1 Tham số fit — Li 2025 Table 3, cột "5 coupled" — [BÀI]

| Tham số | Giá trị | Đơn vị | Trong code `par.ag` / `par` |
|---|---|---|---|
| D_int | 9.81×10⁻¹⁹ | m²/s | `ag.D_int` |
| V̄_SEI (inner = outer) | 5.22×10⁻⁵ | m³/mol | `sei.V` |
| E_SEI | 5×10³ | J/mol | `ag.E_SEI` |
| γ_0 | 1×10⁻⁷ | 1/s | `ag.gamma0` |
| k_Li | 1×10⁻¹⁰ | m/s | `ag.k_Li` |
| β_pos | 2.98×10⁻¹⁸ | 1/s | `ag.beta_p` |
| β_neg | 2.84×10⁻⁹ | 1/s | `ag.beta_n` |
| k_cr (cực âm) | 5.29×10⁻²⁵ | (không in; [CODE] m/(Pa·m^0.5)^m_cr mỗi t_0) | `ag.k_cr` |
| E_act D_s,n | 2×10⁴ | J/mol | `neg.Ds.E` (GD-01) |

Cả chín giá trị dùng **cùng một cột** ("5 coupled"); không trộn cột khác.

### 11.2 Độ dày SEI ban đầu và ε_n,0 — [CODE] (GD-02)

Bài tự mâu thuẫn ((S7) phụ thuộc V̄_SEI, Table 8 ghi 1.23625×10⁻⁸ m "unchanged"; doi_chieu S5, chưa nguồn gốc nào phân xử). Dùng cách của code: (S7) với V̄_SEI = 5.22×10⁻⁵, ΔQ = 0.135 Ah ([BÀI] Note 9, GD-19), cộng 2.5 nm mỗi lớp: `L_SEI,0 = 9.228×10⁻⁹ m` mỗi lớp (bề mặt và vết nứt), `ε_n,0 = 0.23498` (ε không tính phần 2.5 nm). Tuỳ chọn `sei_init = 'paper'` cho biến thể như in.

### 11.3 Tham số giữ nguyên — [BÀI] SI Table 6, 8, 9 (trừ ghi chú)

| Ký hiệu | Giá trị | Đơn vị | Nhãn |
|---|---|---|---|
| z_SEI | 2 | – | [BÀI] Table 8 |
| c_int | 15 | mol/m³ | [BÀI] Table 8 |
| ρ_SEI | 2×10⁵ | Ω·m | [BÀI] Table 8 |
| α (inner) | 0.5 | – | [BÀI] Table 8 |
| α_a,Li / α_c,Li | 0.35 / 0.65 | – | [GỐC] O'Kane 2022 (Table 8 nhãn sai) |
| c_Li,0 | 0 | mol/m³ | [BÀI] Table 8 |
| V̄_Li | 1.3×10⁻⁵ | m³/mol | [BÀI] Table 8 |
| V̄_EC | 6.667×10⁻⁵ | m³/mol | [BÀI] Table 8 |
| c_e,res,0; c_EC,res,0; c_EC,0 | 1000; 4541; 4541 | mol/m³ | [BÀI] Table 6, 8 |
| R_exc | 1.0 | – | [BÀI] giá trị, [CODE] định nghĩa |
| m_2 (n, p) | 2, 2 | – | [BÀI] Table 9 |
| σ_c (n, p) | 60, 375 | MPa | [BÀI] Table 9 |
| b_cr, m_cr, ρ_cr, l_cr,0, w_cr (n) | 1.12, 2.2, 3.18×10¹⁵ m⁻², 2×10⁻⁸ m, 1.5×10⁻⁸ m | | [BÀI] Table 9 |
| t_0 (Paris) | 3600 | s | [CODE] GD-53 |
| t_0 (LAM) | (β dùng trực tiếp) | | [CODE] GD-53 |
| Ω, E, ν, c_ref (n; p) | 3.1×10⁻⁶, 15 GPa, 0.3, 0; 1.25×10⁻⁵, 375 GPa, 0.2, 0 | | [BÀI] Table 6 |
| T_ref | 298.15 | K | [BÀI] (S5) |

Các tham số BOL của DFN (Table 6, 7, Note 8–11): như `gia_dinh.md` và `dfn_params.m` (không đổi ở bước C).

---

## 12. Chỗ mô hình MATLAB khác lần chạy của tác giả (code) — phải nêu trong báo cáo

| # | Mục | MATLAB (nhãn) | Code của tác giả |
|---|---|---|---|
| D1 | Hệ số tăng SEI, số mũ | như code ([GỐC] trùng code) | như nhau |
| D2 | Độ xốp | a_n hiện thời ([BÀI] (S24)) | a_typ hằng |
| D3 | dV_EC, c_EC | gồm SEI vết nứt ([BÀI]) | c_EC chỉ trừ SEI bề mặt |
| D4 | Nồng độ khi ép ra / cân bằng | (S39)–(S43), bảo toàn Li⁺ ([BÀI] + GD-55) | Ratio_CeLi = 1 khi ép ra (Li⁺ theo phần ép ra không bị trừ) |
| D5 | Thấm ướt lại (trường hợp 4) | có ([BÀI]) | không có |
| D6 | R_0.1s | V tại 0.1 s ([BÀI] (S1)) | mẫu đầu tiên của bước xả |
| D7 | Số chu kỳ mỗi set | 515 ([BÀI] SI Table 5, [K24]) | 516 (`Get_tot_cyc`, Expt 2) / 514 |
| D8 | GITT trong RPT | 25 xung ([BÀI] Note 1) | 24 xung |
| D9 | Ngưỡng sạc / CV | V_cv = 4.116 V (GD-43, người dùng quyết định; biến thể `vcv42` = 4.2 V) | 4.2 V |
| D10 | OCP cực âm | một nhánh delithiation (GD-40) | hysteresis (S46)–(S47) |
| D11 | SOH | chia 4.865 Ah (số in trong bài; người dùng chốt, GD-60) | chia 4.86491 Ah |
| D12 | Chuẩn bị trước chu kỳ (sau RPT) | theo [K24] (Expt 2: nghỉ 1 h, xả 1C 730 mAh, nghỉ 3 h; Expt 3: nghỉ 4 h) | Expt 2: xả 8.756838 phút, nghỉ 3 h; Expt 3: nghỉ 1 h |
| D13 | Điện giải, j₀, D_e, χ… | bộ "approved" (GD-03, 04, 18, 21, 22) | trùng (trừ chữ số dU_n/dT, GD-08b) |
| D14 | Bộ giải | ode15s, lưới như code (GD-57), nhảy chu kỳ (GD-58) | CasadiSolver, từng chu kỳ |

---

## 13. Giao thức

### 13.1 Thí nghiệm — [BÀI] [K24] Table 1–6; [SI] Table 5, Note 1

Như bản trước (giữ nguyên): Expt 2 (70–85 %): [xả 1C 730 mAh → sạc CC 0.3C 730 mAh] × 515 mỗi set; Expt 3 (85–100 %): [xả 1C 730 mAh → sạc CC 0.3C tới 4.2 V → CV tới C/100] × 515; 10/25/40 °C; RPT ở 25 °C; 2.5–4.2 V; 1C = 5 A.

### 13.2 Giao thức mô phỏng đã cài (`src/dfn/aging/ag_run.m`, `ag_rpt.m`, `ag_cycle.m`)

| Bước | Nội dung | Nhãn |
|---|---|---|
| Trạng thái đầu | 100 % SOC (c_s = 28543 / 12727 mol/m³), 25 °C, mọi biến lão hoá BOL | [BÀI] Table 6, 8, 9; L_SEI,0 [CODE] |
| Break-in | xả 0.5C tới 4.0 V → CCCV 0.3C → nghỉ 1 h | [CODE] (bài chỉ mô tả break-in thí nghiệm 5 chu kỳ 0.2C, không nói mô phỏng) |
| RPT (25 °C) | 0.1C xả–sạc; 0.5C xả–sạc × 2; GITT 0.5C 25 xung × 200 mAh, nghỉ 1 h | [BÀI] Note 1 |
| — trong RPT | nghỉ 3 h sau mỗi lần xả, 1 h sau sạc 0.1C, 3 h trước GITT; nạp lại CCCV 0.3C | [CODE] GD-59 |
| — đầu RPT | Expt 2: CCCV 0.3C + nghỉ 1 h; Expt 3: nghỉ 1 h | [CODE] |
| Chuẩn bị trước set | Expt 2: nghỉ 1 h, xả 1C 730 mAh, nghỉ 3 h; Expt 3: nghỉ 4 h | [BÀI] [K24] |
| Ageing set | 515 chu ky như 13.1 ở T_amb = 10/25/40 °C; CV/ngưỡng ở V_cv | số chu kỳ [BÀI]; V_cv GD-43 |
| Số set / RPT | 12 set, 13 RPT | [CODE] (thí nghiệm có 10–12 set tuỳ cell) |
| CCCV | CC tới V_cv rồi CV tới C/100 = 0.05 A | [BÀI] (C/100); V_cv GD-43 |
| Cạn khô | cập nhật trước mỗi set và mỗi RPT | [CODE] GD-54 |

### 13.3 So sánh

MPE = mean(|exp − mô hình|/|exp|) trên các RPT thực nghiệm (nội suy tuyến tính mô hình theo charge throughput, bỏ điểm exp = 0); `MPE_tot = MPE_SOH/2 + (MPE_Res + MPE_LLI + MPE_LAMNE + MPE_LAMPE)/8` — [BÀI] [P] pt. (1); cách nội suy [CODE] (`Calculate_MPE_re`). Thực nghiệm = trung bình các cell theo chỉ số RPT của `data/derived/D_kirkaldy_per_cell_rpt.csv` (Kirkaldy 2024). Đường mô hình của tác giả chỉ dùng cho Expt 2 (Source Data Fig. 3–4); Fig. 6 gắn nhãn sai nên không dùng.

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

> **Lưu ý (17/11/2026):** dữ liệu nguồn Fig. 6 ([SD] `Fig.6.xlsx`, Expt 3) bị gắn nhãn sai; các bảng Expt 3 dưới đây chỉ để tham khảo. Kiểm chứng ở bước C dùng số liệu từng cell của Kirkaldy 2024 (`data/derived/D_kirkaldy_per_cell_rpt.csv`) cho cả Expt 2 và 3, và chỉ dùng đường mô hình của tác giả cho Expt 2 (Fig. 3–4).

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

## 15. Biến trạng thái, file cài đặt, phương pháp số

### 15.1 Biến trạng thái thêm vào DFN (sau Q; chỉ khi `aging = true`; `src/dfn/dfn_mesh.m`)

| Biến | Miền | Đơn vị | Phương trình | BOL |
|---|---|---|---|---|
| `Lin`, `Lout` | nút x cực âm | m | mục 3 | 9.228×10⁻⁹ (GD-02) |
| `Lcin`, `Lcout` | nút x cực âm | m | mục 6.2 | 9.228×10⁻⁹ |
| `cLi`, `cdl` | nút x cực âm | mol/m³ | mục 4 | 0, 0 |
| `lcr` | nút x cực âm | m | mục 6.1 | 2×10⁻⁸ |
| `epsn`, `epsp` | nút x mỗi cực | – | mục 7 | 0.75, 0.665 |
| `xavn`, `xavp` | nút x mỗi cực | – | mục 5 (bất biến số học) | trung bình θ của hạt |
| `nSEI`, `nSEIcr` | nút x cực âm | mol/m³ | mục 9 (sổ sách) | 0 |
| `nLAMn`, `nLAMp`, `Qthr` | toàn cell | mol/m², Ah | mục 9 (sổ sách) | 0 |
| lớp bọc cạn khô: `V_res, c_e,res, c_EC,res, A, c_EC` | toàn cell, rời rạc | | mục 10 | V_res = 0, A = 0.1027 m² |

Mặc định `aging = false`: vector trạng thái, vế phải và mọi kết quả **không đổi** so với trước bước C (selftest mục 1 kiểm: bật lão hoá với mọi tốc độ = 0 cho đúng vế phải DFN, lệch < 10⁻⁹). Ứng dụng khác (`src/nmpc`, `src/ekf`) không bị ảnh hưởng (GD-50).

### 15.2 File

| File | Vai trò |
|---|---|
| `src/dfn/dfn_params.m` | `par.aging.on`, `par.ag` (mọi tham số mục 11, có nhãn) |
| `src/dfn/dfn_mesh.m` | chỉ số, sai số tuyệt đối, JPattern của trạng thái lão hoá |
| `src/dfn/dfn_aging_state.m` | a_n, a_p, S, ε_n, R_film từ trạng thái |
| `src/dfn/dfn_side_reactions.m` | j_SEI, j_SEI,cr, j_Li |
| `src/dfn/dfn_aging_rhs.m` | vế phải lão hoá, ∂ε_n/∂t |
| `src/dfn/dfn_rhs.m` | ghép (j_int = j_tot − j_side; ε c_e bảo toàn) |
| `src/dfn/dfn_dryout_init.m`, `dfn_dryout_update.m`, `dfn_set_area.m` | cạn khô (mục 10) |
| `src/dfn/dfn_li_inventory.m` | sổ sách Li, dung lượng điện cực |
| `src/dfn/dfn_aging_init.m`, `dfn_aging_extend.m`, `dfn_aging_sync_xav.m` | trạng thái BOL; chuyển trạng thái không lão hoá sang có lão hoá |
| `src/dfn/dfn_perm_loss.m` | **mất Li vĩnh viễn của một lần sạc + xả về** (SEI + SEI vết nứt + Li chết + Li trong vật liệu mất do LAM; Li mạ thuận nghịch còn lại báo riêng) cho lưới so sánh |
| `src/dfn/aging/ag_*.m` | giao thức Expt 2/3, RPT, nhảy chu kỳ, checkpoint, báo cáo, tự kiểm tra |
| `.github/workflows/aging.yml` | CI: selftest, 12 job (2 thí nghiệm × 3 nhiệt độ × 2 biến thể V_cv) × tối đa 3 chặng 5 h, kiểm chứng nhảy chu kỳ, báo cáo |

### 15.3 Phương pháp số (không phải đơn giản hoá mô hình)

- **Nhảy chu kỳ (cycle jumping), GD-58.** Trong một ageing set mọi chu kỳ giống nhau và trạng thái lão hoá đổi chậm. Sau 3 chu kỳ đầu, lặp: mô phỏng đủ 2 chu kỳ (a, b), Δ = y_b − y_a (mọi trạng thái vi phân, cùng pha chu kỳ), ngoại suy y ← y_b + J·Δ với J ≤ J_max (mặc định 20); trạng thái đại số khởi tạo nhất quán lại. Hai chu kỳ cuối của set luôn mô phỏng đủ. Bất biến tuyến tính (Li trong điện giải, SEI, mạ, Li chết, x_av, Q_thr) được ngoại suy chính xác; tích ε_s·c̄ (Li trong hạt khi có LAM) sai bậc hai — sai lệch bảo toàn Li của mỗi bước nhảy được ghi lại. Kiểm chứng: set 1 ở 25 °C với J_max = 0 (từng chu kỳ), 20 và 50, so RPT 1 (workflow `aging.yml`, job `jumpcheck`).
- **c_rav qua bất biến** `x_av` (mục 5) và **JPattern bỏ các hàng sổ sách và T × độ xốp** (GD-63): tránh các hàng Jacobian dày làm số màu của Jacobian sai phân tăng vọt; nghiệm không đổi (chỉ Newton của ode15s xấp xỉ hơn).
- **Chặn số học**: số mũ ≤ 60 trong exp, độ dày trong mẫu số ≥ 10⁻¹⁴ m — chỉ để tránh tràn số khi Newton thử điểm xa; không hoạt động trong vùng vật lý.
- **Checkpoint**: `ag_run` lưu trạng thái mỗi 15 phút và sau mỗi RPT; CI nối tối đa 3 chặng × 5.1 h cho mỗi trường hợp.

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
