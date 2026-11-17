# Bộ ước lượng EKF (bước F)

*Code: `src/ekf/`. Chạy trên GitHub Actions: `.github/workflows/ekf.yml`. Giả định: `tai_lieu/gia_dinh.md` mục 7 (GD-70 … GD-74).*

## 1. Bộ ước lượng làm gì

Bộ điều khiển NMPC cần biết trạng thái bên trong pin (nồng độ lithium trong hạt, trong chất điện ly, nhiệt độ). Pin thật không đo được những thứ đó. Bộ ước lượng EKF (bộ lọc Kalman mở rộng) đoán chúng **chỉ từ ba tín hiệu đo được**: dòng điện, điện áp hai cực, nhiệt độ bề mặt.

Từ trạng thái ước lượng, ta có:

- **SOC** (theo định nghĩa GD-24: lượng lithium trung bình của cực âm);
- **thế mạ lithium phía màng ngăn η_Li** — quan trọng nhất, vì NMPC dùng nó làm ràng buộc an toàn η_Li ≥ 45 mV (GD-28);
- **nhiệt độ** cell;
- **trạng thái lão hoá**: điện trở màng SEI R_film (suy ra độ dày SEI L_SEI = R_film/ρ_SEI) và lượng lithium mất (LLI).

## 2. Mô hình bên trong EKF

EKF dùng **đúng mô hình rút gọn (ROM) của NMPC** (`src/nmpc/rom_equations.m`, cấu hình D, 88 trạng thái + 10 ẩn đại số). Không viết lại phương trình vật lý nào. Chỉ có một thay đổi: điện trở màng SEI R_film (trong ROM là hằng số BOL) được thay bằng **biến** rf × R_film,BOL, để EKF ước lượng rf như một tham số trôi chậm. Đây là cách của Couto 2022 (mục IV-C: R_f(k+1) = R_f(k) + w_R). Với rf = 1, mô hình của EKF trùng ROM của NMPC đến 0 V (tự kiểm tra, mục 5).

Vì sao cần R_film: lão hoá SEI làm R_film tăng, làm điện áp sạc cao hơn. Nếu EKF không có trạng thái này, nó sẽ giải thích phần điện áp dư bằng cách làm sai nồng độ — tức làm sai SOC và η_Li.

Lượng lithium mất (LLI) **không cần trạng thái riêng**: ROM có nồng độ của cả hai điện cực, EKF ước lượng chúng độc lập, nên tổng lithium trao đổi được là một đại lượng suy ra:

  LLI = (Q_n x₁₀₀ + Q_p y₁₀₀) − (Q_n x̄_n + Q_p ȳ_p)  [Ah]

(Q_n, Q_p: dung lượng mỗi điện cực trên một đơn vị stoichiometry; x̄_n, ȳ_p: stoichiometry trung bình.)

**Trạng thái của bộ lọc** (có hiệp phương sai): stoichiometry 60 vỏ hạt cực âm + 8 vỏ cực dương, 9 nồng độ chất điện ly, nhiệt độ, rf — tổng 79. Các trạng thái còn lại của ROM chỉ được truyền theo mô hình: bộ đếm SOC (tính lại từ x̄_n sau mỗi bước, vì nó trùng định nghĩa), lithium mạ thuận nghịch và các bộ đếm lão hoá (không ảnh hưởng điện áp, GD-31, nên không quan sát được).

## 3. Các bước tính

Mỗi chu kỳ lấy mẫu Δt = 5 s:

1. **Dự đoán.** Tích phân ROM (DAE) qua Δt bằng bộ tích phân CasADi `collocation` (Radau IIA bậc 3, 5 khoảng con 1 s). Dòng trong khoảng = nội suy tuyến tính giữa hai mẫu dòng đo được. Ma trận chuyển A = ∂x⁺/∂x và B = ∂x⁺/∂I là **đạo hàm giải tích** do CasADi tính (qua định lý hàm ẩn của bộ giải Newton), không dùng sai phân. Hiệp phương sai: P ← A P Aᵀ + Q·Δt + B Bᵀ σ_I².
2. **Cập nhật.** Phương trình đo y = [V; T] = h(x, z(x)). Jacobian toàn phần H = h_x − h_z g_z⁻¹ g_x (z là ẩn đại số, g = 0 là ràng buộc của ROM), cũng giải tích. Cập nhật Kalman dạng Joseph. Sau cập nhật, stoichiometry được giữ trong (0, 1).
3. Nếu bộ giải Newton của tích phân không hội tụ (kết quả ra ngoài miền vật lý) thì tự chia đôi khoảng con.

R (nhiễu đo của bộ lọc) = nhiễu cảm biến + **sai số mô hình** (5 mV cho điện áp, 0.1 K cho nhiệt độ; GD-73). Sai số mô hình trội hơn nhiễu cảm biến phòng thí nghiệm khoảng 140 lần, nên R không được đặt bằng nhiễu cảm biến.

## 4. Hai mức nhiễu cảm biến

| | Phòng thí nghiệm (GD-70, từ dữ liệu) | BMS thực tế (GD-71, giả định) |
|---|---|---|
| Điện áp | σ 35.5 µV, lượng tử 20 µV | σ 2 mV, độ phân giải 1 mV |
| Dòng | σ 0.17 mA, lượng tử 0.35 mA | σ 25 mA, độ phân giải 10 mA; biến thể `bms_off`: lệch không +50 mA |
| Nhiệt độ bề mặt | độ phân giải 0.1 °C | σ 0.5 K, độ phân giải 0.1 °C |

## 5. Tự kiểm tra (job `selftest`)

Job `selftest` (run 44112714209) kiểm tra từng phần trước khi thử với DFN:

| Kiểm tra | Kết quả |
|---|---|
| Phương trình đo của EKF (rf = 1) so với ROM của NMPC | trùng (lệch < 10⁻¹⁰) |
| Bước dự đoán (không cập nhật) so với mô phỏng ROM bằng ode15s, sạc 1C 600 s | lệch trạng thái 1.2·10⁻⁶, điện áp 0.000 mV |
| Ma trận A = ∂x⁺/∂x (giải tích) so với sai phân | lệch 2·10⁻⁵ (tương đối) |
| Ma trận H (giải tích) so với sai phân | lệch 7·10⁻⁹ |
| Thời gian một bước | 0.54 s (collocation); IDAS 4 s ⇒ dùng collocation |

Kết luận: phần mô hình và đạo hàm của EKF đúng. Sai số ở mục 6 đến từ **pin thật khác mô hình** (DFN đầy đủ, tham số lệch), không phải từ lỗi cài đặt.

## 6. Phép thử với pin "thật" là DFN đầy đủ

### 6.1. Tiêu chí chọn cấu hình (đặt TRƯỚC khi xem kết quả đợt chọn 2, 18/11/2026)

So các cấu hình trên cùng ba trường hợp khó (pin lệch tham số `mismatch`): lab 25 °C 1C sai SOC +10 %; bms 25 °C 0.5C sai SOC −10 %; bms_off 10 °C 1C sai SOC +10 %. Cùng chuỗi nhiễu cho mọi cấu hình. Chỉ xét sau 600 s (bỏ giai đoạn hội tụ đầu). Xếp theo thứ tự ưu tiên; chênh lệch nhỏ hơn ngưỡng ghi trong ngoặc coi là hoà và xét tiêu chí sau:

1. **Ước cao η_Li lớn nhất** (η_ước − η_thật > 0, phía nguy hiểm), lấy trường hợp xấu nhất trong ba (hoà nếu < 1 mV).
2. **Độ nhất quán một phía của η_Li**: tỷ lệ thời gian η_thật ≥ η_ước − 3σ, trường hợp xấu nhất (hoà nếu < 5 điểm %).
3. **SOC RMSE**, trường hợp xấu nhất (hoà nếu < 0.1 điểm %).
4. **Trạng thái lão hoá**: sai lệch R_film/R_film,BOL và LLI cuối lần sạc.
5. Không được dừng giữa chừng (bộ giải thất bại).

### 6.2. Kết quả chọn cấu hình

Run 44120710755 (đợt 1) và 44195061801 (đợt 2). Pin `mismatch` (GD-72). Các số tính sau 600 s. "Ước cao" = η_ước − η_thật > 0 (phía nguy hiểm).

| Cấu hình | Ước cao η_Li xấu nhất (mV): lab 25 °C 1C / bms 25 °C 0.5C / bms_off 10 °C 1C | Tỷ lệ η_thật ≥ η_ước − 3σ, xấu nhất (%) | SOC RMSE xấu nhất (%) | R_film/BOL cuối (thật 1.5) |
|---|---|---|---|---|
| EKF thường (1 lần lặp) — chỉ thử nominal | 13.5 (nominal, thật rf = 1) | – | – | 5.6 (thật 1.0) |
| IEKF, ước lượng rf và LLI liên tục | 12.3 / 5.6 / **19.5** | 11.7 | 0.74 | 2.7–5.7 |
| IEKF + Q của rf nhỏ, σ_V mô hình 10 mV | 12.3 / – / – | – | 0.81 | 4.4 |
| IEKF, giữ rf/LLI 600 s đầu | 11.0 / 5.3 / – | – | 0.94 | 2.7–4.0 |
| IEKF, P₀ nhỏ (rf 0.2, LLI 0.05 Ah) | 8.4 / 5.3 / **12.0** | 1.2 | 0.92 | 1.5–3.6 |
| IEKF, P₀ nhỏ + giữ 600 s | 8.3 / 5.2 / **11.8** | 0.9 | 0.83 | 1.5–3.4 |
| IEKF, giữ rf/LLI cả lần sạc | 6.7 / 4.9 / **11.5** | 0.6 | 0.92 | 1 (giữ) |
| **IEKF, giữ cả lần sạc + P₀ nhỏ (chọn)** | 6.6 / 5.1 / **8.9** | 0.0 | 0.79 | 1 (giữ) |

Theo tiêu chí 1, cấu hình cuối thắng rõ (8.9 mV, các cấu hình khác ≥ 11.5 mV). Tiêu chí 2: mọi cấu hình đều gần 0 % ở ca bms_off 10 °C (hoà) — tức **σ_η của bộ lọc không tin được** ở mọi cấu hình. Tiêu chí 3 hoà (0.79 so với 0.74–0.94 %). Cấu hình chọn ghi trong `ekf_config.m` (GD-75).

**Vì sao giữ R_film và LLI cố định trong lần sạc** (lựa chọn của bộ ước lượng, không đổi mô hình):

- Trong một lần sạc vài giờ, R_film và LLI thay đổi rất chậm (đáng kể chỉ sau hàng trăm chu kỳ), nhưng EKF lại kéo chúng đi rất xa: rf ước 2.7–5.7 khi thật 1.5. Nguyên nhân: phần điện áp lệch do sai SOC đầu và do j₀, D_s thật nhỏ hơn mô hình 20 % đều "giống" một điện trở màng lớn hơn. Couto 2022 (mục IV-C) cũng nói R_f "hấp thụ động học không mô hình hoá".
- rf sai làm hỏng thẳng η_Li: trong ROM η_Li = Δφ − j·R_film, khi sạc j < 0 nên rf quá lớn làm η_Li ước **cao hơn** thật, tức đúng phía nguy hiểm.
- Vì thế rf và LLI được coi là trạng thái chậm, chỉ cập nhật **giữa các lần sạc** (hai thang thời gian), với độ bất định ban đầu nhỏ (giá trị lấy từ lần trước). Trong lần sạc, độ bất định của chúng vẫn nằm trong P (bộ lọc "consider"), nên các trạng thái nhanh không bị tin quá mức.
- Thêm một lợi ích: NMPC dùng R_film BOL cố định, nên η_Li của EKF và của NMPC tính trên cùng mô hình (mục 7).
- Cái giá: trong lần sạc, EKF **không báo được lão hoá** (rf, LLI đứng yên ở giá trị đầu). Đây không phải mất thông tin thật, vì các ước lượng cũ trong lần sạc đều sai (rf sai 80–280 %, LLI sai −47 % đến +80 %).

KQ_THU

## 7. Giao diện cho vòng kín NMPC (ghi chú tích hợp)

Đây là ghi chú cho luồng NMPC (file trong `src/nmpc/` do luồng đó sửa; luồng EKF không sửa).

1. **Cách nối.** `est = ekf_estimator(par, noise, soc_guess, T0, Tamb)`, rồi `cfg.estimator = @(y, trk, meas) est.estimate(meas);` trong `nmpc_closed_loop`. Dòng trong `meas.I` theo quy ước của NMPC (sạc ≥ 0); bộ bọc tự đổi dấu. `xhat` trả về đủ `rom.nx` trạng thái, bộ đếm lão hoá đặt 0 (như `rom_from_dfn`).
2. **Truyền đủ mẫu đo, không chỉ mẫu cuối.** Hiện `nmpc_closed_loop` chỉ đưa một mẫu (t, I, V, T) ở cuối mỗi chu kỳ 30 s. EKF được thử với mẫu 5 s. Nên đưa cả vectơ mẫu của đoạn vừa chạy: `meas = struct('t', t_truoc + o.t, 'I', -o.I, 'V', o.V, 'T', o.T)` (cùng lưới `dt = 5 s` mà `plant_run` đã dùng). `ekf_estimator.estimate` đã nhận vectơ. Thêm nhiễu cảm biến bằng `ekf_sensor(c, I, V, T, seed)` trước khi đưa vào.
3. **Lần gọi đầu.** `meas.V = NaN` ⇒ EKF chỉ dự đoán. Nên cho EKF chạy 600 s đầu (giai đoạn hội tụ, mục 6) với dòng sạc thấp hoặc dùng biên η_Li rộng hơn trong khoảng đó.
4. **R_film của NMPC.** Mô hình NMPC dùng R_film BOL cố định. EKF dùng cùng giá trị trong lần sạc (cấu hình chọn ở mục 6.2 giữ rf trong lần sạc), nên η_Li mà NMPC tính từ `xhat` trùng η_Li của EKF. Nếu sau này cập nhật rf giữa các lần sạc thì NMPC cần nhận rf làm tham số (thêm phần tử vào vectơ `p` của `nmpc_model.m`, nhân `rom.Rfilm_n` và `rom.ap.Rfilm`); nếu không, η_Li của NMPC và EKF sẽ khác nhau.
5. **Biên an toàn.** `xhat` là ước lượng điểm. σ_η từ P quá nhỏ so với sai số thật (mục 6), nên **không** dùng η_ước − 3σ làm ràng buộc. Dùng biên lùi theo sai số thực nghiệm ở mục 6.4.
6. **Thời gian.** ~0.5–0.9 s cho một bước 5 s ⇒ 3–6 s cho một chu kỳ NMPC 30 s, chấp nhận được cho mô phỏng (chưa phải thời gian thực).

## 8. Việc còn mở

KQ_MO
