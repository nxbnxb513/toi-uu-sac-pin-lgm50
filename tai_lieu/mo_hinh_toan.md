# Mô hình toán: pin LG M50, ghép điện hoá – nhiệt – lão hoá

*Viết lại ngày 17/11/2026 theo phạm vi mới. Code tương ứng: `src/model_rhs.m`, `src/params_lgm50.m`, `src/ocp.m`.*

Ký hiệu nguồn:
- [1] O'Kane 2022
- [3] Couto 2022
- [4] Chen 2020
- [5] O'Regan 2022
- [7] Li 2025

Nhãn của từng phương trình:
- **[nguồn]** lấy từ bài báo;
- **[dẫn xuất]** đề tài tự suy ra;
- **[giả định]** không có nguồn trực tiếp.

---

## 1. Lựa chọn mô hình

Mô hình điện hoá là **SPMe** (single-particle có chất điện phân): mỗi điện cực được đại diện bằng một hạt, cộng với phương trình khuếch tán trong chất điện phân. Đây là dạng rút gọn của mô hình DFN trong [1], [4].

Lý do không dùng DFN đầy đủ:
- DFN là hệ vi phân – đại số, khó viết đúng trong MATLAB thuần khi không được chạy thử.
- SPMe là hệ phương trình vi phân thường, giải trực tiếp bằng `ode15s`.

Để vẫn thấy được chỗ dễ mạ lithium nhất (mặt anode sát màng ngăn), đề tài **tính lại điện thế anode theo từng vị trí** trong chiều dày điện cực (mục 3.5). Các phản ứng phụ (SEI, mạ lithium) được tính riêng tại từng vị trí đó.

## 2. Đầu vào, đầu ra, trạng thái

**Quy ước dấu:** I > 0 khi xả, I < 0 khi sạc.

| Loại | Đại lượng |
|---|---|
| Đầu vào | Dòng I(t) [A] |
| Nhiễu | Nhiệt độ môi trường T_amb [K] |
| Đầu ra đo được | Điện áp V, nhiệt độ T |
| Đầu ra không đo được | SOC, η_Li theo vị trí, L_SEI, lượng lithium mất |

**Vector trạng thái** (`src/state_index.m`), lưới mặc định có 55 trạng thái:

| Biến | Số lượng | Ý nghĩa |
|---|---|---|
| c_n(r) | 10 | Nồng độ Li trong hạt anode |
| c_p(r) | 10 | Nồng độ Li trong hạt cathode |
| c_e(x) | 15 | Nồng độ Li⁺ trong chất điện phân (6 + 3 + 6 ô) |
| T | 1 | Nhiệt độ pin |
| L_SEI(x) | 6 | Độ dày SEI tại 6 vị trí trong anode |
| c_Li(x) | 6 | Lithium đã mạ (còn bóc lại được) |
| c_dl(x) | 6 | Lithium chết |
| Q_SEI | 1 | Tích phân dòng SEI |

## 3. Phương trình

### 3.1 Khuếch tán trong hạt [nguồn: [1] Bảng S1]

```
∂c/∂t = (1/r²) ∂/∂r ( D(T) r² ∂c/∂r ),    −D ∂c/∂r |_{r=R} = N_int
```
Thông lượng tổng tại bề mặt hạt:
```
N_tot,n =  I / (F a_n L_n A),      N_tot,p = −I / (F a_p L_p A)
```

### 3.2 Chất điện phân [nguồn: [1] Bảng S1, pt. S3, S6, S7]

```
ε ∂c_e/∂t = ∂/∂x ( ε^1.5 D_e(c_e,T) ∂c_e/∂x ) + s(x)
s = +(1−t⁺) I/(F A L_n) trong anode;  0 trong màng ngăn;  −(1−t⁺) I/(F A L_p) trong cathode
```
Nguồn phản ứng được coi là đều trong mỗi điện cực. Đây là giả thiết của SPMe.

### 3.3 Động học [nguồn: [1] Bảng S1]

```
η_k = (2RT/F) asinh( N_tot,k / ( 2 k_k(T) √( (c̄_e/c_eq)(c_max − c_s)c_s ) ) )
```

### 3.4 Điện áp [dẫn xuất từ DFN với phản ứng đều]

```
V = [U_p(y_s) + η_p] − [U_n(x_s) + η_n + η_SEI] + Δφ_e + Δφ_s
Δφ_e = (2RT/F)(1−t⁺) ln(c̄_e,p / c̄_e,n) − (I/A) ( L_n/(3κ_n) + L_s/κ_s + L_p/(3κ_p) )
Δφ_s = −(I/A) ( L_n/(3σ_n) + L_p/(3σ_p) )
η_SEI = ρ_SEI L_SEI I / (A L_n a_n)                        [nguồn: [1] pt. 8]
```
Hàm OCP U_p, U_n lấy từ [4] pt. (8), (9). Độ dẫn hiệu dụng κ, σ có hệ số Bruggeman 1.5.

### 3.5 Điện thế anode theo vị trí [dẫn xuất]

Với phản ứng đều, dòng trong pha rắn và pha điện ly thay đổi tuyến tính theo x (x = 0 tại collector). Tích phân định luật Ohm cho:

```
φ_s(x) − φ̄_s = −(I/(A σ_n)) ( x − x²/(2L_n) − L_n/3 )
φ_e(x) − φ̄_e = −(I/(A κ_n)) ( x²/(2L_n) − L_n/6 ) + (2RT/F)(1−t⁺) ln( c_e(x)/c̄_e,n )
Δφ(x) = φ_s − φ_e = [U_n + η_n + η_SEI] + [φ_s(x) − φ̄_s] − [φ_e(x) − φ̄_e]
```
Khi sạc (I < 0), Δφ thấp nhất ở mặt sát màng ngăn. Đó là nơi lithium mạ trước.

### 3.6 SEI phụ thuộc điện thế anode [nguồn: [7] SI Note 2; có giả định]

```
j_SEI(x) = c_int D_int(T) F · exp( −F Δφ(x) / (RT) ) / ( L_SEI(x)/2 )        [A/m²]
dL_SEI/dt = j_SEI V̄_SEI / (2F)
```
- Δφ càng thấp (SOC càng cao, sạc càng mạnh) thì SEI lớn càng nhanh. Đây là chỗ mô hình **phân biệt được các vùng sạc**.
- **Giả định 1:** [7] in số mũ là −(φ_s − φ_e), thiếu hệ số F/(RT). Đề tài dùng dạng có F/(RT) để số mũ không thứ nguyên.
- **Giả định 2:** gộp hai lớp SEI thành một độ dày tổng, lớp trong bằng nửa tổng.
- **Giả định 3:** D_int được [7] khớp trên bộ tham số nền của [5]; ở đây ghép vào bộ tham số nền của [4]/[1].

### 3.7 Mạ lithium và lithium chết [nguồn: [1] pt. (12)–(16); tham số từ [7]]

```
η_Li(x) = Δφ(x) − η_SEI(x)
N_Li = k_Li [ c_Li exp(F α_a η_Li/RT) − c_e exp(−F α_c η_Li/RT) ]     (> 0 khi bóc)
dc_Li/dt = −a_n N_Li − γ c_Li
dc_dl/dt =  γ c_Li,        γ = γ₀ L_SEI,0 / L_SEI
```

### 3.8 Ghép phản ứng phụ vào dòng xen cài [nguồn: [1] Bảng S1, j_tot = F a (N_int + ΣN_sr)]

```
N_int,n = N_tot,n + mean(j_SEI)/F − mean(N_Li)
```
Phản ứng phụ lấy bớt lithium lẽ ra đi vào hạt. Nhờ vậy mất lithium tự xuất hiện trong mô hình mà không cần phương trình riêng.

### 3.9 Nhiệt 0D [dẫn xuất từ bảo toàn năng lượng; dạng như [3]]

```
m C_p dT/dt = I (U_p − U_n − V) − I T (∂U_p/∂T − ∂U_n/∂T) − h A_s (T − T_amb)
```
∂U/∂T lấy từ [7] SI Note 8, pt. (S5), (S6). **Giả định:** hệ số có đơn vị mV/K.

### 3.10 Phụ thuộc nhiệt độ [nguồn: [1] pt. S1, S2, S4, S5; [7] S5]

Dạng Arrhenius, P(T) = P(T_ref) exp(E/(R T_ref) − E/(R T)), áp dụng cho D_s, k, κ, D_e và D_int.

### 3.11 Chỉ số lão hoá [dẫn xuất]

```
Q_SEI   = ∫ a_n L_n A · mean(j_SEI) dt                 [C]
Q_dead  = F · mean(c_dl) · L_n A
Q_plate = F · mean(c_Li) · L_n A
```

## 4. Các tương tác có trong mô hình

| # | Tương tác | Phương trình |
|---|---|---|
| 1 | Dòng → nồng độ bề mặt hạt → OCP, quá thế → điện áp | 3.1, 3.3, 3.4 |
| 2 | Dòng → gradient nồng độ điện ly → điện áp và η_Li | 3.2, 3.4, 3.5 |
| 3 | Nhiệt độ → khuếch tán, động học, độ dẫn | 3.10 |
| 4 | Điện hoá → nhiệt sinh → nhiệt độ | 3.9 |
| 5 | Nhiệt độ → tốc độ SEI | 3.6, 3.10 |
| 6 | **SOC và dòng sạc → điện thế anode → tốc độ SEI** | 3.5, 3.6 |
| 7 | SEI dày → điện trở màng → điện áp, nhiệt | 3.4 |
| 8 | SEI dày → η_Li giảm → dễ mạ lithium hơn | 3.7 |
| 9 | SEI dày → lithium chết hình thành chậm hơn | 3.7 |
| 10 | Phản ứng phụ → mất lithium → dịch cửa sổ tỉ lượng | 3.8 |
| 11 | Lithium mạ bóc lại khi quá thế dương | 3.7 |
| 12 | Vị trí trong anode: sát màng ngăn mạ trước | 3.5 |

**Không có trong mô hình:** lão hoá của silicon ở SOC thấp; nứt hạt và mất vật liệu hoạt tính; SEI làm giảm độ xốp; chênh nhiệt độ lõi – vỏ; phân bố phản ứng không đều trong chiều dày điện cực (ngoài phần điện thế ở 3.5).

## 5. Tối ưu dòng sạc (`src/optimise_window.m`)

- Chia vùng sạc thành N = 4 đoạn có lượng điện tích bằng nhau. Mỗi đoạn một dòng không đổi.
- Thời lượng các đoạn: t_k = T_b · softmax(θ)_k, với T_b là thời gian sạc của baseline. Tổng thời gian luôn bằng T_b.
- Hàm mục tiêu: lão hoá của profile chia cho lão hoá của baseline, cộng các hàm phạt khi vi phạm ràng buộc (thời gian, dòng tối đa, nhiệt độ, biên η_Li).
- Thuật toán: tìm kiếm theo toạ độ, bắt đầu từ θ = 0 (dòng không đổi). Kết quả không bao giờ tệ hơn điểm xuất phát.
- Nếu điện áp chạm 4.2 V giữa chừng, mô phỏng tự chuyển sang giữ áp.

## 6. Ước lượng và điều khiển vòng kín (`src/run_ekf_demo.m`)

- **Pin "thật":** mô hình lưới mịn, tham số bị làm lệch 20 % (khuếch tán, động học, tản nhiệt).
- **Bộ ước lượng:** EKF trên mô hình lưới thô (21 trạng thái), tham số danh định, chỉ nhận I, V, T có nhiễu. SOC ban đầu bị đặt sai 5 %.
- **Bộ điều khiển:** tra profile tối ưu theo SOC ước lượng; giảm một nửa dòng khi η_Li ước lượng xuống dưới biên an toàn; giảm dòng khi điện áp đo chạm giới hạn.
- **Nhiễu cảm biến (giả định):** điện áp 2 mV, nhiệt độ 0.1 K, dòng 10 mA cộng lệch 0.5 %.

## 7. Bảng nguồn tham số

Xem chú thích từng dòng trong `src/params_lgm50.m`. Tóm tắt:

| Nhóm | Nguồn |
|---|---|
| Hình học, điện cực, điện ly, năng lượng hoạt hoá | [1] Bảng S2, S3 (gốc từ [4]) |
| Cửa sổ tỉ lượng, OCP | [4] Bảng VII, IX; pt. (8), (9) |
| Nhiệt: khối lượng, C_p, diện tích, h | [5] Bảng 3, 8 (h được [5] chỉnh tay) |
| Entropy ∂U/∂T | [7] SI Note 8 |
| SEI: c_int, D_int, V̄, E, ρ, L₀ | [7] Bảng 3, SI Bảng 8 |
| Mạ lithium: k_Li, γ₀ | [7] Bảng 3 |
| Hệ số truyền α_a, α_c | [1] Bảng S4 (giả định của [1]) |
