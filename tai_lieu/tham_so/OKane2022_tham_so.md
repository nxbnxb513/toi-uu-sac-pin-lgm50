# O'Kane et al. 2022 — "Lithium-ion battery degradation: how to model it" — Phương trình & tham số

**Nguồn:** S. E. J. O'Kane, W. Ai, G. Madabattula, D. Alonso Alvarez, R. Timms, V. Sulzer, J. S. Edge, B. Wu, G. J. Offer, M. Marinescu, *Phys. Chem. Chem. Phys.* 24, 7909 (2022); bản dùng ở đây: arXiv:2112.02037v2 (4 Feb 2022), file `tai_lieu/OKane2022_arXiv.pdf` (37 trang PDF).

**Quy ước số trang:** "tr. N" = số trang PDF (1–37). Bài chính = tr. 1–28 (trùng số in trên trang). Phần Supplementary Information (SI) = tr. 29–37, số in ở chân trang SI là 1–9, nên ghi "tr. 30 (SI-2)" v.v.

**Cách đọc:** Toàn văn đã được đọc từ file text trích xuất; các trang có phương trình/bảng (tr. 7, 8, 9, 10, 30, 31, 33, 34) đã được render lại để kiểm tra ký hiệu. Không lấy bất kỳ giá trị nào từ đường cong trên hình. Một số giá trị chỉ xuất hiện dưới dạng **chữ trong chú giải (legend) của hình** được ghi riêng và đánh dấu "[legend]".

**Tế bào:** LG M50**T** (21700), âm cực graphite + 10% SiOx theo khối lượng, dương cực NMC 811 (tr. 11, §4.1). Bộ tham số BOL lấy từ Chen et al. 2020 [48].

---

## 0. Tóm tắt nhanh những gì bài báo KHÔNG có

| Mục người dùng hỏi | Tình trạng trong bài | Trang |
|---|---|---|
| Danh sách nhiều lựa chọn SEI growth (reaction-limited, EC-diffusion, interstitial, ...) | **Không có danh sách.** Chỉ có: (a) mô hình solvent-diffusion-limited 1 lớp (dùng trong bài), (b) bản 2 lớp (PyBaMM default lúc đó) ở SI. Safari et al. được nhắc là có cả giới hạn khuếch tán và giới hạn electron (reaction), nhưng không viết phương trình. | tr. 3–4, 7, 13, 32–33 |
| Phương trình thay đổi porosity (pore clogging) | **KHÔNG RÕ — không có phương trình.** Chỉ có kết quả định tính (porosity tại biên âm cực–separator về 0 → sudden failure). | tr. 15, 16, 20 |
| Phương trình LLI → lượng Li cyclable n_Li | **KHÔNG RÕ — không có phương trình.** Chỉ nói SEI/dead Li "trap" Li. | tr. 3, 6, 17 |
| Phương trình LAM → a (diện tích riêng) | **KHÔNG RÕ — không có phương trình.** Chỉ nói định tính LAM làm giảm diện tích tiếp xúc, tăng mật độ dòng giao diện (Fig. S3). | tr. 6, 16 |
| Mô hình nhiệt | **Không có.** Nhiệt độ giữ hằng số vì thiếu dữ liệu nhiệt cho LG M50. | tr. 11 |
| Số % suy giảm dung lượng sau 1000 chu kỳ ở 5/25/45 °C | **KHÔNG RÕ — không có số trong văn bản**, chỉ có xếp hạng định tính. | tr. 17 |
| Tỷ lệ LLI vs LAM (số) | **KHÔNG RÕ — không có số**, chỉ có định tính. | tr. 17, 18, 20 |

---

## 1. Các phương trình mô hình lão hoá (degradation)

### 1.1 SEI growth — solvent-diffusion-limited, 1 lớp (mặc định của bài) — tr. 7, §3.1

Mô hình của Single et al. [14], giả thiết trạng thái dừng, dòng dung môi theo định luật Fick:

- (1) $N_\mathrm{sol} = -D_\mathrm{sol}(T)\,\dfrac{\partial c_\mathrm{sol}}{\partial l}$
- (2) $c_\mathrm{sol} = 0$ tại $l = 0$
- (3) $c_\mathrm{sol} = c_\mathrm{sol,0}$ tại $l = L_\mathrm{SEI}$
- (4) $c_\mathrm{sol} = \dfrac{l\,c_\mathrm{sol,0}}{L_\mathrm{SEI}}$ và $N_\mathrm{sol} = -\dfrac{c_\mathrm{sol,0}D_\mathrm{sol}(T)}{L_\mathrm{SEI}}$
- (5) $N_\mathrm{SEI} = -N_\mathrm{sol} = \dfrac{c_\mathrm{sol,0}D_\mathrm{sol}(T)}{L_\mathrm{SEI}}$
- (6) $\dfrac{\partial L_\mathrm{SEI}}{\partial t} = -\tfrac12 N_\mathrm{sol}\bar V_\mathrm{SEI} = \dfrac{c_\mathrm{sol,0}D_\mathrm{sol}(T)\bar V_\mathrm{SEI}}{2L_\mathrm{SEI}}$  → $L_\mathrm{SEI}\propto\sqrt t$
- (7) Arrhenius: $D_\mathrm{sol}(T) = D_\mathrm{sol}(T_\mathrm{ref})\exp\!\left(-\dfrac{E_\mathrm{sol}}{RT} + \dfrac{E_\mathrm{sol}}{RT_\mathrm{ref}}\right)$, $T_\mathrm{ref} = 298.15$ K (25 °C) "throughout".
- (8) Điện trở màng: $\eta_\mathrm{SEI} = \rho_\mathrm{SEI}\,L_\mathrm{SEI}\,\dfrac{j_\mathrm{tot}}{a_-}$ ($j_\mathrm{tot}$ định nghĩa ở Table S1).

Ghi chú (tr. 7, 13): đây là bản đơn giản hoá của mô hình PyBaMM (2 lớp). Ở §5.1 (tr. 13) bài chọn SEI 1 lớp "for the sake of simplicity"; PyBaMM mặc định 2 lớp với $D_\mathrm{sol} = 2.5\times10^{-22}$ m² s⁻¹; "The effect of having two SEI layers instead of one is small compared to that of changing the solvent diffusivity by an order of magnitude."

Lý do chọn diffusion-limited (tr. 3–4, §2.1): Safari et al. [16] mô hình cả giới hạn khuếch tán dung môi và giới hạn cấp electron, nhưng thấy chế độ diffusion-limited khớp dữ liệu thực nghiệm tốt nhất.

### 1.2 SEI growth — 2 lớp (two-layer, PyBaMM default) — tr. 32–33 (SI-4, SI-5)

$L_\mathrm{SEI}$ thay bằng $L_\mathrm{inner}$, $L_\mathrm{outer}$; dung môi chỉ khuếch tán qua lớp ngoài:

- (S8) $N_\mathrm{sol} = -D_\mathrm{sol}(T)\,\partial c_\mathrm{sol}/\partial l$
- (S9) $c_\mathrm{sol} = 0$ tại $l = L_\mathrm{inner}$
- (S10) $c_\mathrm{sol} = c_\mathrm{sol,0}$ tại $l = L_\mathrm{outer}$
- (S11) $c_\mathrm{sol} = l\,c_\mathrm{sol,0}/L_\mathrm{outer}$
- (S12) $N_\mathrm{sol} = -c_\mathrm{sol,0}D_\mathrm{sol}(T)/L_\mathrm{outer}$
- (S13) $N_\mathrm{inner} = -\tfrac12 N_\mathrm{sol} = c_\mathrm{sol,0}D_\mathrm{sol}(T)/L_\mathrm{outer}$ **(như in; vế phải thiếu hệ số ½ so với vế giữa — nhiều khả năng lỗi in, KHÔNG RÕ)**
- (S14) $N_\mathrm{outer} = -\tfrac12 N_\mathrm{sol} = c_\mathrm{sol,0}D_\mathrm{sol}(T)/L_\mathrm{outer}$ (cùng lưu ý)
- (S15) — số phương trình trống trong bản in.
- giả thiết hai lớp tăng cùng tốc độ:
- (S16) $\partial L_\mathrm{inner}/\partial t = -\tfrac14 N_\mathrm{sol}\bar V_\mathrm{SEI} = c_\mathrm{sol,0}D_\mathrm{sol}(T)\bar V_\mathrm{SEI}/(4L_\mathrm{outer})$
- (S17) $\partial L_\mathrm{outer}/\partial t = -\tfrac14 N_\mathrm{sol}\bar V_\mathrm{SEI} = c_\mathrm{sol,0}D_\mathrm{sol}(T)\bar V_\mathrm{SEI}/(4L_\mathrm{outer})$
- Mọi chỗ khác thay $L_\mathrm{SEI}\to L_\mathrm{inner}+L_\mathrm{outer}$, ví dụ (S18) $\eta_\mathrm{SEI} = \rho_\mathrm{SEI}(L_\mathrm{inner}+L_\mathrm{outer})\,j_\mathrm{tot}/a_-$.

**Mặc định trong bài:** 1 lớp (tr. 13). Bản 2 lớp chỉ dùng để so sánh trong Fig. 1.

### 1.3 SEI on cracks — tr. 10, §3.3

- SEI trên bề mặt nứt dùng cùng mô hình diffusion-limited; độ dày ban đầu rất mỏng, ví dụ $L_\mathrm{SEI,cr0} = L_\mathrm{SEI,0}/10000$ (văn bản ghi "e.g."), để mô phỏng giai đoạn hình thành SEI.
- Dùng độ dày trung bình $L_\mathrm{SEI,cr}$:
- (21) $\dfrac{\partial L_\mathrm{SEI,cr}}{\partial t} = \dfrac{c_\mathrm{sol,0}D_\mathrm{sol}(T)\bar V_\mathrm{SEI}}{2L_\mathrm{SEI,cr}} + \dfrac{\partial l_\mathrm{cr}}{\partial t}\,\dfrac{L_\mathrm{SEI,cr0}-L_\mathrm{SEI,cr}}{l_\mathrm{cr}}$
  - Số hạng 1 (luôn dương): tăng trưởng khuếch tán trên vết nứt hiện có.
  - Số hạng 2 (luôn âm): vết nứt lan rộng tăng diện tích → giảm độ dày trung bình.
- Cách diện tích vết nứt $a_\mathrm{cr}$ cộng vào thông lượng SEI tổng/LLI: **KHÔNG RÕ — không viết phương trình** (chỉ nói "cracks reveal additional surface area for SEI growth", tr. 5).

### 1.4 Li plating / stripping và dead Li — tr. 8–9, §3.2

Các dạng được liệt kê (lịch sử):
- (9) Yang et al. [24]: $N_\mathrm{Li} = k_\mathrm{Li}(c^*_\mathrm{Li})^{\alpha_{c,Li}}(c^*_e)^{\alpha_{a,Li}}\left(\dfrac{c_\mathrm{Li}}{c^*_\mathrm{Li}}\exp\!\left(\dfrac{\alpha_\mathrm{a,Li}F}{RT}(\phi_s-\phi_e)\right) - \dfrac{c_e}{c^*_e}\exp\!\left(-\dfrac{\alpha_\mathrm{c,Li}F}{RT}(\phi_s-\phi_e)\right)\right)$, với $c^*_e = c_\mathrm{eq}$; $k_\mathrm{Li}$, $c^*_\mathrm{Li}$ là tham số fit; Yang dùng $\alpha_\mathrm{a,Li}=0.3$, $\alpha_\mathrm{c,Li}=0.7$ (theo Arora, Doyle, White) (tr. 8).
- (10) O'Kane et al. [43] (theo Wood et al.): $N_\mathrm{Li} = k_\mathrm{Li}\left(c_\mathrm{Li}\exp\!\left(\dfrac{F(\phi_s-\phi_e)}{2RT}\right) - c_e\exp\!\left(-\dfrac{F(\phi_s-\phi_e)}{2RT}\right)\right)$
- (11) $\partial c_\mathrm{Li}/\partial t = -a_- N_\mathrm{Li}$

**Mô hình dùng trong bài (12)–(16):**
- (12) $\dfrac{\partial c_\mathrm{Li}}{\partial t} = -a_- N_\mathrm{Li} - \gamma\,c_\mathrm{Li}$
- (13) $\dfrac{\partial c_\mathrm{dl}}{\partial t} = \gamma\,c_\mathrm{Li}$ ($c_\mathrm{dl}$: nồng độ dead Li; $\gamma$ đơn vị s⁻¹)
- (14) $\gamma(L_\mathrm{SEI}) = \gamma_0\,\dfrac{L_\mathrm{SEI,0}}{L_\mathrm{SEI}}$ — giả thiết chuyển plated Li → dead Li cần phản ứng với dung môi nên cũng bị giới hạn khuếch tán qua SEI; $\gamma_0$ là tham số fit.
- (15) $N_\mathrm{Li} = k_\mathrm{Li}\left(c_\mathrm{Li}\exp\!\left(\dfrac{F\alpha_\mathrm{a,Li}\eta_\mathrm{Li}}{RT}\right) - c_e\exp\!\left(-\dfrac{F\alpha_\mathrm{c,Li}\eta_\mathrm{Li}}{RT}\right)\right)$
- (16) $\eta_\mathrm{Li} = \phi_s - \phi_e - \eta_\mathrm{SEI}$

Ghi chú: $N_\mathrm{Li}$ được gọi là "Li stripping flux" (dương = stripping). Mâu thuẫn nhỏ: văn bản tr. 8 nhắc 0.3/0.7 (của Yang/Arora), còn Table S4 dùng 0.35/0.65 "Assumed". Bài chỉ cho plated Li → dead Li; **plated Li → SEI không được mô hình** (tr. 19, đề xuất tương lai).

### 1.5 Particle cracking (Paris' law) và ứng suất — tr. 9–10, §3.3

Ứng suất trong hạt cầu tự do (Zhang et al. [46]):
- (17a) $\sigma_r = \dfrac{2\Omega E}{(1-\nu)}\,[c_\mathrm{avg}(R_i) - c_\mathrm{avg}(r)]$
- (17b) $\sigma_t = \dfrac{\Omega E}{(1-\nu)}\,[2c_\mathrm{avg}(R_i) + c_\mathrm{avg}(r) - \bar c/3)$ — **như in** (ngoặc mở "[" đóng ")", và số hạng "$\bar c/3$"; dạng gốc của Zhang et al. có thể khác — KHÔNG RÕ, cần đối chiếu [46]).
- (17c) $u = \dfrac{(1+\nu)}{(1-\nu)}\Omega r\,c_\mathrm{avg}(r) + \dfrac{2(1-2\nu)}{(1-\nu)}\Omega r\,c_\mathrm{avg}(R_i)$
- (18) $c_\mathrm{avg}(r) = \dfrac{1}{3r^3}\displaystyle\int_0^r \bar c\,r^2\,dr$ **(như in; hệ số 1/(3r³) — với định nghĩa trung bình khối thông thường là 3/r³; KHÔNG RÕ là lỗi in hay quy ước)**, $\bar c = c - c_\mathrm{ref}$ (lệch so với nồng độ không ứng suất).
- Quy ước: $\sigma_r,\sigma_t > 0$ là kéo (tensile).
- Hydrostatic: $\sigma_h = (\sigma_r + 2\sigma_t)/3$ (tr. 10).

Giả thiết vết nứt (Deshpande et al. [27]): vi nứt giống nhau trên bề mặt, dài $l_\mathrm{cr}$, rộng $w_\mathrm{cr}$, mật độ $\rho_\mathrm{cr}$ (số vết/đơn vị diện tích); chỉ chiều dài tăng.
- (19) Paris' law: $\dfrac{dl_\mathrm{cr}}{dN} = \dfrac{k_\mathrm{cr}}{t_0}\left(\sigma_t b_\mathrm{cr}\sqrt{\pi l_\mathrm{cr}}\right)^{m_\mathrm{cr}}$, chỉ khi $\sigma_t>0$; $t_0$ = thời gian một chu kỳ; $b_\mathrm{cr}$ = hệ số hiệu chỉnh cường độ ứng suất; $k_\mathrm{cr}, m_\mathrm{cr}$ từ thực nghiệm (Purewal et al.). (Vế trái "dN" nhưng vế phải chia $t_0$ — như in.)
- (20) $\dfrac{da_\mathrm{cr}}{dt} = \dfrac{a_\pm\rho_\mathrm{cr}w_\mathrm{cr}}{t_0}\cdot\dfrac{dl_\mathrm{cr}}{dt} = \dfrac{a_\pm\rho_\mathrm{cr}w_\mathrm{cr}}{t_0}\cdot k_\mathrm{cr}\left(\sigma_t b_\mathrm{cr}\sqrt{\pi l_\mathrm{cr}}\right)^{m_\mathrm{cr}}$, $\sigma_t>0$ — **như in** (vị trí của $t_0$ không nhất quán về thứ nguyên giữa vế giữa và (19); KHÔNG RÕ).
- Cracking áp dụng cho **cả hai điện cực** (tr. 3, §2).

### 1.6 LAM (loss of active material) do ứng suất — tr. 10–11, §3.4

Chỉ LAM do nứt hạt (không mô hình hoà tan điện cực). Theo Laresgoiti et al. [32], Reniers et al. [10]:
- (22) $\dfrac{\partial\epsilon_a}{\partial t} = \dfrac{\beta}{t_0}\left(\dfrac{\sigma_{h,\max}-\sigma_{h,\min}}{\sigma_c}\right)^{m_2}$, $\sigma_{h,\min}>0$
- (23) dạng tức thời (giữa các chu kỳ $\sigma_{h,\min}=0$): $\dfrac{\partial\epsilon_a}{\partial t} = \dfrac{\beta}{t_0}\left(\dfrac{\sigma_h}{\sigma_c}\right)^{m_2}$, $\sigma_h>0$
  - $\beta$, $m_2$: hằng số "normally obtained from experiments"; $\sigma_c$: ứng suất tới hạn. Chỉ ứng suất kéo đóng góp.
- **Dấu:** văn bản nói (22) ước lượng "the decrease in the accessible volume fraction" nhưng vế phải dương và không có dấu trừ — **KHÔNG RÕ quy ước dấu** (về vật lý $\epsilon_a$ giảm).
- Dạng nào (22 hay 23) được dùng trong mô phỏng: §5.4 tr. 16 nói "The governing equation (23)" → **dùng (23)**.

### 1.7 Porosity change — **KHÔNG RÕ (không có phương trình)**

Văn bản (tr. 6) nói SEI gây "pore clogging"; Fig. 3(c) và tr. 15–16, 20 nói porosity tại biên âm cực–separator về 0 gây sudden failure. Không có phương trình liên hệ $\epsilon_e$ với $L_\mathrm{SEI}$, $c_\mathrm{Li}$, $c_\mathrm{dl}$ hoặc $\epsilon_a$.

### 1.8 Các kênh phản hồi (feedback) của suy giảm vào mô hình DFN

| Kênh | Có trong bài? | Phương trình / mô tả | Trang |
|---|---|---|---|
| η_SEI (film resistance) trong Butler–Volmer intercalation | Có | $\eta = \phi_s-\phi_e-U_\pm(c_s)-\eta_\mathrm{SEI}$ (Table S1); $\eta_\mathrm{SEI}$ theo (8)/(S18) | tr. 7, 29, 30 |
| η_SEI trong BV plating | Có | (16) $\eta_\mathrm{Li} = \phi_s-\phi_e-\eta_\mathrm{SEI}$ | tr. 9 |
| Side reactions vào dòng tổng | Có | $j_\mathrm{tot} = Fa_\pm(N_\mathrm{int} + \sum N_\mathrm{sr})$ (Table S1; $N_\mathrm{sr}$ = phản ứng phụ nói chung) | tr. 29, 30 |
| LLI → n_Li | **KHÔNG RÕ** (không có phương trình; chỉ định tính: SEI và dead Li giữ Li; LLI "negative feedback" làm âm cực khó đạt trạng thái lithi hoá cao nên ức chế plating) | — | tr. 3, 6 |
| Porosity → vận chuyển điện giải | Gián tiếp: Bruggeman $\kappa_\mathrm{eff}=\epsilon_e^{1.5}\kappa$, $D_\mathrm{eff}=\epsilon_e^{1.5}D_e$ (S3) và $\partial(\epsilon c_e)/\partial t$ (Table S1); cách $\epsilon_e$ thay đổi theo suy giảm: **KHÔNG RÕ** | (S3) | tr. 31 |
| LAM → ε_s | Có: (23) cho $\partial\epsilon_a/\partial t$ | (22)/(23) | tr. 10–11 |
| LAM → a (diện tích riêng) | **KHÔNG RÕ** (chỉ định tính: LAM giảm diện tích giao diện → tăng mật độ dòng → tăng ứng suất, positive feedback) | — | tr. 6, 16 |
| Cracks → diện tích cho SEI | Có một phần: (20) cho $a_\mathrm{cr}$; (21) cho $L_\mathrm{SEI,cr}$; cách cộng vào LLI: **KHÔNG RÕ** | (20), (21) | tr. 10 |
| Nhiệt độ → tốc độ | Có qua Arrhenius (7), (S1), (S2), (S4), (S5); T hằng số | — | tr. 7, 30, 31 |

---

## 2. Table S1 — Phương trình DFN (làm sạch) — tr. 30 (SI-2)

Ký hiệu theo O'Kane et al. 2020 [SI-1], với 2 thay đổi: $N_\mathrm{sr}$ là phản ứng phụ nói chung, và thêm $\eta_\mathrm{SEI}$ vào BV (tr. 29, SI-1).

| Biến | Phương trình |
|---|---|
| $\phi_s(x,t)$ | $\sigma_\pm\,\dfrac{\partial^2\phi_s}{\partial x^2} = j_\mathrm{tot}$ |
| $\phi_e(x,t)$ | $-\kappa_\mathrm{eff}(c_e,T)\dfrac{\partial^2\phi_e}{\partial x^2} + \dfrac{2RT}{F}\kappa_\mathrm{eff}(c_e,T)(1-t^+)\dfrac{\partial^2\ln c_e}{\partial x^2} = j_\mathrm{tot}$ |
| $c_e(x,t)$ | $\dfrac{\partial(\epsilon c_e)}{\partial t} = \dfrac{\partial}{\partial x}\left(D_\mathrm{eff}(c_e,T)\dfrac{\partial c_e}{\partial x}\right) + \left(\dfrac{1-t^+}{F}\right)j_\mathrm{tot}$ |
| $c_a(x,r,t)$ | $\dfrac{\partial c_a}{\partial t} = \dfrac{1}{r^2}\dfrac{\partial}{\partial r}\left(D_\pm(T)\,r^2\dfrac{\partial c_a}{\partial r}\right)$ |
| $c_s(x,t)$ | $\dfrac{\partial c_s}{\partial r} = -\dfrac{N_\mathrm{int}}{D_\pm(T)}$ (BC bề mặt hạt) |
| $j_\mathrm{tot}$ | $j_\mathrm{tot} = Fa_\pm\left(N_\mathrm{int} + \sum N_\mathrm{sr}\right)$ |
| $N_\mathrm{int}$ | $N_\mathrm{int} = 2k_\pm(T)\sqrt{\dfrac{c_e}{c_\mathrm{eq}}(c_{m\pm}-c_s)c_s}\;\sinh\!\left(\dfrac{F\eta}{2RT}\right)$ |
| $\eta$ | $\eta = \phi_s - \phi_e - U_\pm(c_s) - \eta_\mathrm{SEI}$ |

Ghi chú: Bảng không ghi điều kiện biên/ban đầu cho φ, c_e, và không ghi phương trình điện áp đầu cực — **KHÔNG RÕ** (không có trong bài). Dấu của $j_\mathrm{tot}$ (A m⁻³) như in. $D_\pm$ chỉ phụ thuộc T, không phụ thuộc nồng độ (tr. 30).

---

## 3. Bảng tham số (chép nguyên văn)

### 3.1 Table S2 — Electrode parameters (BOL) — tr. 31 (SI-3)

Chú thích bảng: "All values taken from the final model values from Tables VII and IX in Chen et al.[2] unless otherwise specified."

| Symbol | Definition | − electrode | + electrode |
|---|---|---|---|
| $A$ | Total planar electrode area, m² | 0.1027 | 0.1027 |
| $a_\pm$ | Surface area to volume ratio, m⁻¹ | 3.84 × 10⁵ | 3.82 × 10⁵ |
| $c_{m\pm}$ | Maximum Li⁺ concentration, mol m⁻³ | 33133 | 63104 |
| $c_{0\pm}$ | Initial Li⁺ concentration, mol m⁻³ | 29866 | 17038 |
| $D_\pm$ | Li⁺ diffusion coefficient at 25 °C, m² s⁻¹ | 3.3 × 10⁻¹⁴ | 4 × 10⁻¹⁵ |
| $E_{D\pm}$ | Activation energy for Li⁺ diffusion, J mol⁻¹ | 30300 [3] | 25000 [6] |
| $E_{k\pm}$ | Activation energy for rate constant, J mol⁻¹ | 35000 | 17800 |
| $k_\pm$ | (De)intercalation rate constant at 25 °C, m s⁻¹ | 2.12 × 10⁻¹⁰ | 1.12 × 10⁻⁹ |
| $r_\pm$ | Electrode particle radius, m | 5.86 × 10⁻⁶ | 5.22 × 10⁻⁶ |
| $\delta_\pm$ | Electrode thickness, m | 8.52 × 10⁻⁵ | 7.56 × 10⁻⁵ |
| $\epsilon_e$ | Electrolyte volume fraction | 0.25 | 0.335 |
| $\epsilon_a$ | Active material volume fraction | 0.75 | 0.665 |
| $\sigma_\pm$ | Electrode conductivity, S m⁻¹ | 215 | 0.18 |

Nguồn đánh dấu: [3] = Ecker et al. 2015; [6] = Cabañero et al. 2018 (giá trị cho NCA, dùng thay cho NMC 811 vì không có dữ liệu — tr. 31). $E_{D-}=30300$ "within one significant figure" của hai giá trị khác [4] Kulova, [5] Schmalstieg (tr. 30–31).
**Lưu ý:** $E_{k\pm}$ không có tham chiếu riêng → theo chú thích thì từ Chen et al.; bài không nói rõ Chen có đo Ek hay không → **KHÔNG RÕ, cần kiểm tra trong Chen 2020**. Bài nói Chen không báo cáo dữ liệu D phụ thuộc nhiệt độ (tr. 30).

### 3.2 Table S3 — Other parameters — tr. 33 (SI-5)

Chú thích: "All values taken from Chen et al.[2]" (nhưng dòng $E_\kappa$ ghi [3] = Ecker).

| Symbol | Definition | Value |
|---|---|---|
| $c_\mathrm{eq}$ | Equilibrium Li⁺ concentration in electrolyte, mol m⁻³ | 1000 |
| $E_\kappa$ | Activation energy for electrolyte conductivity, J mol⁻¹ | 17100 [3] |
| $F$ | Faraday's constant, C mol⁻¹ | 96485 |
| $Q_\mathrm{nom}$ | Nominal capacity, mAh | 5000 |
| $R$ | Universal gas constant, J K⁻¹ mol⁻¹ | 8.314 |
| $t^+$ | Li⁺ transference number | 0.2594 |
| $V_\max$ | Upper cutoff voltage, V | 4.2 |
| $V_\min$ | Lower cutoff voltage, V | 2.5 |
| $\delta_s$ | Separator thickness, m | 1.2 × 10⁻⁵ |
| $\epsilon_e$ | Separator porosity | 0.47 |

### 3.3 Table S4 — Degradation parameters (không thay đổi trong parametric studies) — tr. 34 (SI-6)

| Symbol | Definition | Neg. value | Neg. Ref. | Pos. value | Pos. Ref. |
|---|---|---|---|---|---|
| $c_\mathrm{sol,0}$ | Bulk solvent concentration, mol m⁻³ | 2636 | [7] | — | — |
| $\bar V_\mathrm{SEI}$ | SEI partial molar volume, m³ mol⁻¹ | 9.585 × 10⁻⁵ | [8] | — | — |
| $\rho_\mathrm{SEI}$ | SEI resistivity, Ω m | 2 × 10⁵ | [8] | — | — |
| $L_\mathrm{SEI,0}$ | Initial SEI thickness, m | 5 × 10⁻⁹ | [8] | — | — |
| $E_\mathrm{sol}$ | Solvent diffusion activation energy, J mol⁻¹ | 37000 | [9] | — | — |
| $\alpha_\mathrm{a,Li}$ | Anodic transfer coefficient for Li stripping | 0.35 | **Assumed** | — | — |
| $\alpha_\mathrm{c,Li}$ | Cathodic transfer coefficient for Li plating | 0.65 | **Assumed** | — | — |
| $E$ | Young's modulus [Pa] | 1.5 × 10¹⁰ | [10] | 3.75 × 10¹¹ | [10] |
| $\nu$ | Poisson's ratio | 0.3 | [10] | 0.2 | [10] |
| $\Omega$ | Partial molar volume [m³/mol] | 3.1 × 10⁻⁶ | [10] | 1.25 × 10⁻⁵ | [11] |
| $l_\mathrm{cr,0}$ | Initial crack length [m] | 2 × 10⁻⁵ | [12] | 2 × 10⁻⁵ | [12] |
| $w_\mathrm{cr}$ | Initial crack width [m] | 1.5 × 10⁻⁵ | [12] | 1.5 × 10⁻⁵ | [12] |
| $\rho_\mathrm{cr}$ | number of cracks per unit area [m⁻²] | 3.18 × 10¹⁵ | [12] | 3.18 × 10¹⁵ | [12] |
| $b_\mathrm{cr}$ | Stress intensity factor correction | 1.12 | [12] | 1.12 | [12] |
| $m_\mathrm{cr}$ | Paris' law exponential term | 2.2 | [12] | 2.2 | [12] |
| $\sigma_c$ | Critical stress for particle fracture [Pa] | 6 × 10⁷ | **Assumed** | 3.75 × 10⁸ | **Assumed** |
| $m_2$ | Loss of active material exponential term | 2 | **Assumed** | 2 | **Assumed** |

Tham chiếu SI (tr. 34–36): [7] Ploehn, Ramadass, White 2004 (JES 151 A456); [8] Safari et al. 2009 (JES 156 A145); [9] Waldmann et al. 2014 (JPS 262 129); [10] Ai et al. 2020 (JES 167 013512); [11] Xu et al. 2019 (JMPS 129 160); [12] Purewal et al. 2014 (JPS 272 1154); [13] Single, Latz, Horstmann 2018 (ChemSusChem 11 1950).

Nhận xét (không phải số mới): $l_\mathrm{cr,0}=2\times10^{-5}$ m lớn hơn bán kính hạt $r_-=5.86\times10^{-6}$ m (Table S2) — bài không bình luận; **KHÔNG RÕ** ý nghĩa vật lý. $w_\mathrm{cr}$ ghi "Initial crack width" trong khi văn bản (tr. 9) nói chiều rộng không đổi.

### 3.4 Table S5 — Degradation parameters varied in parametric studies (giá trị mặc định) — tr. 35 (SI-7)

| Symbol | Definition | Neg. default | Neg. Ref. | Pos. default | Pos. Ref. |
|---|---|---|---|---|---|
| $D_\mathrm{sol}$ | Solvent diffusivity in SEI, m² s⁻¹ | 2.5 × 10⁻²² | [13] | — | — |
| $k_\mathrm{Li}$ | Li plating/stripping rate constant, m s⁻¹ | 10⁻⁹ | **Assumed** | — | — |
| $\gamma_0$ | Rate constant for dead Li formation, s⁻¹ | 10⁻⁶ | **Assumed** | — | — |
| $k_\mathrm{cr}$ | Paris' law cracking rate | 3.9 × 10⁻²⁰ | [12] | 3.9 × 10⁻²⁰ | [12] |
| $\beta$ | Loss of active material proportional term | 0.001 | **Assumed** | 0.001 | **Assumed** |

(Đơn vị $k_\mathrm{cr}$ và $\beta$ không ghi trong bảng — **KHÔNG RÕ**.)

---

## 4. Phương trình S1–S7 (Arrhenius, điện giải) — tr. 30–32 (SI-2…SI-4)

- (S1) $D_\pm(T) = D_\pm(T_\mathrm{meas})\exp\!\left(\dfrac{E_{D\pm}}{RT_\mathrm{meas}} - \dfrac{E_{D\pm}}{RT}\right)$
- (S2) $k_\pm(T) = k_\pm(T_\mathrm{meas})\exp\!\left(\dfrac{E_{k\pm}}{RT_\mathrm{meas}} - \dfrac{E_{k\pm}}{RT}\right)$
  - $T_\mathrm{meas} = 298.15$ K (25 °C). Hệ số: $E_{D-}=30300$, $E_{D+}=25000$, $E_{k-}=35000$, $E_{k+}=17800$ J mol⁻¹ (Table S2); $D_-(T_\mathrm{meas})=3.3\times10^{-14}$, $D_+=4\times10^{-15}$ m² s⁻¹; $k_-=2.12\times10^{-10}$, $k_+=1.12\times10^{-9}$ m s⁻¹.
  - Văn bản viết "$D_\pm(c^*_a, T)$" nhưng D chỉ là hàm của T (tr. 30).
- (S3) Bruggeman: $\kappa_\mathrm{eff}(c_e,T) = \epsilon_e^{1.5}\kappa(c_e,T)$, $D_\mathrm{eff}(c_e,T) = \epsilon_e^{1.5}D_e(c_e,T)$ (tr. 31)
- (S4) $\kappa(c_e,T) = \kappa(c_e,T_\mathrm{meas})\exp\!\left(\dfrac{E_\kappa}{RT_\mathrm{meas}} - \dfrac{E_\kappa}{RT}\right)$
- (S5) $D_e(c_e,T) = D_e(c_e,T_\mathrm{meas})\exp\!\left(\dfrac{E_\kappa}{RT_\mathrm{meas}} - \dfrac{E_\kappa}{RT}\right)$ — **dùng chung $E_\kappa$** cho cả κ và De; $E_\kappa = 17100$ J mol⁻¹ (Table S3, nguồn Ecker [3]).
- (S6) $\kappa(c_e,T_\mathrm{meas}) = 1.297\times10^{-10}c_e^3 - 7.94\times10^{-5}c_e^{1.5} + 3.329\times10^{-3}c_e$ [S m⁻¹, $c_e$ mol m⁻³] (tr. 31; văn bản gọi là "cubic polynomial" dù có số hạng $c_e^{1.5}$)
- (S7) $D_e(c_e,T_\mathrm{meas}) = 8.794\times10^{-17}c_e^2 - 3.972\times10^{-13}c_e + 4.862\times10^{-10}$ [m² s⁻¹] (tr. 32)
- Thêm (7): $D_\mathrm{sol}(T)$ với $E_\mathrm{sol}=37000$ J mol⁻¹, $T_\mathrm{ref}=298.15$ K (tr. 7).
- **Không có Arrhenius cho $k_\mathrm{Li}$, $\gamma_0$, $k_\mathrm{cr}$, $\beta$** — bài không nêu → coi như hằng số (KHÔNG RÕ trong code PyBaMM).

---

## 5. Tham số "Assumed" vs có nguồn

Đếm theo các cột "Ref." của Table S4 và S5 (tr. 34–35):

| | Số ký hiệu | Số ô giá trị (âm + dương) |
|---|---|---|
| **Assumed** | **7**: $\alpha_\mathrm{a,Li}$, $\alpha_\mathrm{c,Li}$, $\sigma_c$, $m_2$ (S4); $k_\mathrm{Li}$, $\gamma_0$, $\beta$ (S5) | **10**: $\alpha_\mathrm{a,Li}$(−), $\alpha_\mathrm{c,Li}$(−), $\sigma_c$(−,+), $m_2$(−,+), $k_\mathrm{Li}$(−), $\gamma_0$(−), $\beta$(−,+) |
| Có tham chiếu tài liệu | **15**: $c_\mathrm{sol,0}$, $\bar V_\mathrm{SEI}$, $\rho_\mathrm{SEI}$, $L_\mathrm{SEI,0}$, $E_\mathrm{sol}$, $E$, $\nu$, $\Omega$, $l_\mathrm{cr,0}$, $w_\mathrm{cr}$, $\rho_\mathrm{cr}$, $b_\mathrm{cr}$, $m_\mathrm{cr}$ (13 ở S4); $D_\mathrm{sol}$, $k_\mathrm{cr}$ (2 ở S5) | **24** |
| Tổng | 22 ký hiệu (S4: 17, S5: 5) | 34 ô (S4: 27, S5: 7) |

Lưu ý quan trọng:
- "Có nguồn" ≠ "đo trên LG M50": **không có tham số suy giảm nào được đo cho LG M50** — "The parameters concerning battery degradation were not measured by Chen et al." (tr. 32). Các giá trị có nguồn lấy từ tế bào/vật liệu khác (Safari, Ploehn, Purewal, Ai, Xu, Waldmann, Single).
- $E_{D+}=25000$ là của NCA, không phải NMC 811 (tr. 31).
- Giả định ngầm khác trong văn bản: $L_\mathrm{SEI,cr0}=L_\mathrm{SEI,0}/10000$ ("e.g.", tr. 10); T hằng số, không có mô hình nhiệt (tr. 11); $D_-$ không phụ thuộc nồng độ (tr. 30); OCP âm cực dùng nhánh discharge (tr. 29); tác giả tự nhận Young's modulus NMC 811 "was set too high" (tr. 19).

---

## 6. Giao thức mô phỏng và kết quả định lượng (chỉ văn bản/bảng)

### 6.1 Standard cycling protocol — tr. 11, §4.2
1. Giữ 4.2 V đến khi I < 50 mA (C/100); nghỉ 4 h.
2. Characterization cycle 1: xả 0.5 A (C/10) đến 2.5 V; sạc CC 1.5 A (0.3C) đến 4.2 V; CV 4.2 V đến I < 50 mA (C/100).
3. 1000 chu kỳ: xả 5 A (1C) đến 2.5 V; sạc CC 1.5 A/CV 4.2 V như trên.
4. Characterization cycle 2 giống cycle 1.
5. T = 25 °C trong 1000 chu kỳ (trừ khi nói khác); luôn 25 °C khi characterization.
- Đo suy giảm theo throughput: (24) $Q_\mathrm{tot}(t) = \int_0^t |I(t)|\,dt'$ (tr. 11–12).
- Số học: PyBaMM, method of lines, finite volume với X điểm lưới trong điện cực/separator và Y điểm trong hạt (**giá trị X, Y: KHÔNG RÕ**), IDA (SUNDIALS) qua CasADi; CV có thêm phương trình đại số cho dòng (tr. 12).

### 6.2 Table 1 — Cycling protocols (tất cả cơ chế bật) — tr. 17

| Protocol | Discharge rate | Charge rate | Temperature |
|---|---|---|---|
| (i) | 1C | 0.3C | 25 °C |
| (ii) | 1C | 1.2C | 25 °C |
| (iii) | 0.5C | 0.3C | 25 °C |
| (iv) | 2C | 0.3C | 25 °C |
| (v) | 1C | 0.3C | 5 °C |
| (vi) | 1C | 0.3C | 45 °C |

### 6.3 Các nghiên cứu tham số (parametric studies)
- §5.1 SEI only (tr. 13): quét $D_\mathrm{sol}$; giá trị trong legend Fig. 1 [legend]: 2.5E-22, 2.5E-21, 7.5E-21, 1.25E-20 m² s⁻¹ + PyBaMM default 2 lớp (2.5 × 10⁻²², có trong văn bản).
- §5.2 SEI + plating (tr. 14): 1000 chu kỳ ở 5 °C (characterization ở 25 °C). Legend Fig. 2a [legend]: $k_\mathrm{Li}$ ∈ {1E-10, 1E-9} m/s, $\gamma_0$ ∈ {4E-7, 1E-6, 2.5E-6} s⁻¹.
- §5.3 SEI + cracking (tr. 14): $k_\mathrm{cr}$ ×1 (Table S5), ×10, ×30, ×50 (văn bản) + no cracking.
- §5.4 LAM only (tr. 16): β nhân hệ số "nxpy"; legend Fig. 4 [legend]: n1p1, n1p10, n1p20, n10p1, n20p1.

### 6.4 Kết quả định lượng nêu trong văn bản
| Kết quả | Trang |
|---|---|
| Tăng $D_\mathrm{sol}$ một bậc có ảnh hưởng lớn hơn so với dùng SEI 2 lớp | tr. 13, 20 |
| SEI dày theo √t → LLI theo √t; tốc độ fade giảm dần | tr. 7, 13, 15, 20 |
| $k_\mathrm{Li} > 10^{-9}$ m s⁻¹: fade nhạy với $\gamma_0$ hơn nhiều so với $k_\mathrm{Li}$; $k_\mathrm{Li} < 10^{-9}$: cả hai đều ảnh hưởng lớn | tr. 14, 20 |
| Cracking ×10: fade gần tuyến tính; knee point sau **5000 Ah** (×30) và **3000 Ah** (×50) throughput; ×50 sudden failure ở **6600 Ah** | tr. 14–15 |
| Độ dày SEI trung bình ngừng tăng sau **7500 Ah** (×30) và **4000 Ah** (×50) → nứt nhanh hơn thụ động hoá → pore clogging | tr. 16 |
| Nguyên nhân failure ×50: porosity tại biên âm cực–separator về 0; ×30 sẽ fail tương tự nếu chạy quá 1000 chu kỳ | tr. 15 |
| LAM n20p1: phần thể tích active material âm cực giảm **30%**, tương ứng **25%** capacity loss | tr. 16 |
| LAM âm > dương vì xả 1C vs sạc 0.3C (chỉ điện cực đang de-intercalate chịu ứng suất kéo) và $\sigma_c$: 3.75 × 10⁸ Pa (+) vs 6 × 10⁷ Pa (−) ("over six times lower") | tr. 16–17, 20 |
| Tất cả cơ chế: fade lớn nhất ở 5 °C, tiếp theo 45 °C; 25 °C ít nhất. **Số % cụ thể: KHÔNG RÕ (không có trong văn bản)** | tr. 17 |
| LLI chiếm phần lớn mất dung lượng cho mọi protocol **trừ 5 °C**; ở 5 °C LAM (âm cực) là nguyên nhân chính. **Tỷ lệ số: KHÔNG RÕ** | tr. 17, 18, 20 |
| Protocol (ii) (sạc 1.2C): vẫn mất AM âm cực nhiều hơn dương vì σc dương lớn | tr. 17 |
| Chênh lệch dung lượng giữa 1C đầu/cuối bằng chênh lệch giữa hai lần 0.1C → suy giảm không do tăng dòng | tr. 18 |
| Chênh lệch 0.1C đầu/cuối tương tự giữa các protocol trừ 5 °C | tr. 18 |
| Năm "degradation paths" được xác định (Fig. 7); (i)–(iv) SEI chậm; (vi) cùng đường nhưng nhanh hơn; (v) cracking→LAM tự khuếch đại + plating | tr. 18–19 |
| "Cliff edge" chỉ tái hiện ở kịch bản tăng tốc độ nứt Paris | tr. 19 |

---

## 7. Hạn chế, kiểm chứng (validation), hướng nghiên cứu tương lai

**Hạn chế (tự nêu):**
- Không có mô hình nhiệt; T hằng số do thiếu dữ liệu nhiệt LG M50 (Sturm et al. chỉ có entropic coefficients) (tr. 11).
- $D_\pm$ không phụ thuộc nồng độ dù Chen đo được; không triển khai được trong PyBaMM; $D_-(c_s)$ khó định nghĩa cho graphite+SiOx (tr. 19, 30).
- Không mô hình cơ chế dương cực (phase change, hoà tan kim loại chuyển tiếp, pSEI), không mô hình điện cực composite/bimodal/SiOx (tr. 5).
- Plated Li không chuyển thành SEI; SEI thêm do plating không được tính (tr. 19).
- Young's modulus NMC 811 đặt quá cao → LAM dương cực không đóng góp đáng kể (tr. 19).
- Plating model "requires further parameterization work in order to be of any practical use" (tr. 20).
- LAM: "another degradation mechanism for which more accurate knowledge of key parameters is required" (tr. 20).
- Tham số hoá là "a major challenge" (tr. 1, abstract).
- Sudden failure chỉ có ý nghĩa nếu bộ tham số xảy ra trong thực tế; cần thực nghiệm để xác định dải tham số (tr. 19).
- Mô hình vết nứt dùng giả thiết vi nứt, khác giả thiết hạt cầu lý tưởng (tr. 15).
- Solver CasADi không có event detection → step-and-check (tr. 12).

**Validation:** **Bài không có so sánh với dữ liệu thực nghiệm lão hoá của LG M50.** Kết quả là nghiên cứu độ nhạy/kịch bản. Chỉ nhắc rằng mô hình plating của Arora được Ge et al. kiểm chứng (tr. 4) và Safari thấy diffusion-limited khớp dữ liệu (tr. 4) — đây là validation của tài liệu khác.

**Đề xuất tương lai (tr. 19, §5.7):** thermal–electrochemical coupling; ảnh hưởng SiOx lên khuếch tán rắn, plating, hysteresis điện áp; Li plating trên bề mặt nứt mới; plated Li → SEI; mô hình suy giảm cathode đầy đủ hơn; mất điện giải (bay hơi/tiêu thụ dung môi); nonlinear diffusion cho plating; mô hình hysteresis SiOx [37].

---

## 8. Không có dạng số (chỉ có hình)

Các đại lượng sau **chỉ có trong hình**, không được đọc giá trị (theo quy tắc minh bạch):
- **Fig. S1 (tr. 32):** OCP $U_-(c^*_s)$ (graphite+SiOx) và $U_+(c^*_s)$ (NMC 811) theo nồng độ chuẩn hoá, đo bởi Chen et al. ở 25 °C, dùng phép đo 3 điện cực; âm cực dùng nhánh **discharge** (tr. 29). → Lấy dạng số từ Chen et al. 2020 (bảng/hàm fit) hoặc dữ liệu mở của họ, không từ hình này.
- Fig. 1 (tr. 13): dung lượng và LLI theo throughput với các $D_\mathrm{sol}$.
- Fig. 2 (tr. 14): dung lượng ở 5 °C; dung lượng 25 °C sau 1000 chu kỳ theo $k_\mathrm{Li}$, $\gamma_0$.
- Fig. 3 (tr. 15): dung lượng, LLI, porosity tại biên separator, độ dày SEI trung bình (cracking).
- Fig. 4 (tr. 16): dung lượng, phần AM âm/dương (LAM).
- Fig. 5 (tr. 18): dung lượng, LLI, AM âm/dương cho 6 protocol → **% fade ở 5/25/45 °C chỉ có ở đây**.
- Fig. 6 (tr. 27): đường V–Q tại 4 thời điểm cho 6 protocol.
- Fig. 7 (tr. 28): sơ đồ đường suy giảm (định tính).
- Fig. S2 (tr. 35): diện tích nứt không thứ nguyên.
- Fig. S3 (tr. 36): mật độ dòng giao diện trung bình theo LAM.
- Fig. S4 (tr. 37): phân rã LLI theo SEI / SEI-cracks / plating cho 6 protocol → **tỷ lệ LLI theo cơ chế chỉ có ở đây**.
- Thông số nhiệt (nhiệt dung, độ dẫn nhiệt, entropic coefficient): không có ở cả văn bản lẫn hình.

---

## 9. Ghi chú cho đồ án (EKF + NMPC, MATLAB) — mức độ chắc chắn của tham số

| Cơ chế | Tham số không chắc chắn | Đánh giá cho đồ án |
|---|---|---|
| SEI diffusion-limited 1 lớp (1)–(8) | $D_\mathrm{sol}$ (Single et al., không phải M50), $E_\mathrm{sol}$, $\rho_\mathrm{SEI}$ có nguồn nhưng từ tế bào khác | **Nên đưa vào.** Phương trình đơn giản (1 ODE/điểm lưới), tất cả tham số có nguồn tài liệu; nên ghi rõ không phải tham số M50 và chạy độ nhạy $D_\mathrm{sol}$ (bài cho thấy nó chi phối). Nếu có dữ liệu lão hoá mở thì $D_\mathrm{sol}$ là ứng viên nhận dạng bằng script. |
| Li plating + dead Li (12)–(16) | $k_\mathrm{Li}$, $\gamma_0$, $\alpha_\mathrm{a/c,Li}$ đều **Assumed**; tác giả nói cần tham số hoá thêm mới dùng được thực tế | **Nên đưa vào ở mức ràng buộc/chỉ báo**, rất phù hợp cho sạc tối ưu: ràng buộc NMPC $\eta_\mathrm{Li}=\phi_s-\phi_e-\eta_\mathrm{SEI} \ge 0$ (hoặc biên an toàn) không cần $k_\mathrm{Li}$, $\gamma_0$. Nếu mô phỏng lượng Li mạ thì phải coi là kịch bản (scenario) và trình bày độ nhạy. |
| Cracking (Paris) + SEI on cracks (17)–(21) | $k_\mathrm{cr}$, $m_\mathrm{cr}$, $l_\mathrm{cr,0}$… từ Purewal (tế bào khác); phương trình có điểm in không nhất quán (17b, 18, 20) | **Tuỳ chọn / ngoài phạm vi chính.** Thêm nhiều trạng thái và tính ứng suất; cần đối chiếu Deshpande/Zhang/Ai để sửa lỗi in trước khi code. |
| LAM do ứng suất (23) | $\beta$, $\sigma_c$, $m_2$ đều **Assumed**; E của NMC "set too high" | **Không nên làm cơ chế chính**; nếu có thì chỉ là phân tích độ nhạy. Bài không cho phương trình cập nhật $a$ theo $\epsilon_a$ → phải tự giả định (cần ghi rõ). |
| Porosity change | Không có phương trình trong bài | Nếu cần, phải lấy từ nguồn khác (vd. tài liệu PyBaMM/Safari) — **không có trong O'Kane 2022**. |
| Thermal | Bài không có tham số nhiệt | Phải lấy từ nguồn khác (vd. dữ liệu nhiệt LG M50 công bố riêng); O'Kane 2022 không cung cấp. Lưu ý chỉ có Arrhenius cho D±, k±, κ, De, Dsol. |

Gợi ý tổng thể: mô hình đồ án hợp lý = DFN (Table S1–S3, S1–S7) + SEI 1 lớp (Table S4/S5) + ràng buộc plating; các cơ chế cracking/LAM chỉ nên đưa vào như mở rộng có độ nhạy, vì 7/22 tham số suy giảm là "Assumed" và không tham số suy giảm nào được đo trên LG M50 (tr. 32).
