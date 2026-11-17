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

KQ_SELFTEST

## 6. Phép thử với pin "thật" là DFN đầy đủ

### 6.1. Tiêu chí chọn cấu hình (đặt TRƯỚC khi xem kết quả đợt chọn 2, 18/11/2026)

So các cấu hình trên cùng ba trường hợp khó (pin lệch tham số `mismatch`): lab 25 °C 1C sai SOC +10 %; bms 25 °C 0.5C sai SOC −10 %; bms_off 10 °C 1C sai SOC +10 %. Cùng chuỗi nhiễu cho mọi cấu hình. Chỉ xét sau 600 s (bỏ giai đoạn hội tụ đầu). Xếp theo thứ tự ưu tiên; chênh lệch nhỏ hơn ngưỡng ghi trong ngoặc coi là hoà và xét tiêu chí sau:

1. **Ước cao η_Li lớn nhất** (η_ước − η_thật > 0, phía nguy hiểm), lấy trường hợp xấu nhất trong ba (hoà nếu < 1 mV).
2. **Độ nhất quán một phía của η_Li**: tỷ lệ thời gian η_thật ≥ η_ước − 3σ, trường hợp xấu nhất (hoà nếu < 5 điểm %).
3. **SOC RMSE**, trường hợp xấu nhất (hoà nếu < 0.1 điểm %).
4. **Trạng thái lão hoá**: sai lệch R_film/R_film,BOL và LLI cuối lần sạc.
5. Không được dừng giữa chừng (bộ giải thất bại).

KQ_THU

## 7. Giao diện cho vòng kín NMPC (ghi chú tích hợp)

KQ_GIAODIEN

## 8. Việc còn mở

KQ_MO
