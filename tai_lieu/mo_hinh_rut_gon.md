# Mô hình rút gọn (ROM) cho bộ điều khiển NMPC

*Bước E và G trong `tai_lieu/ke_hoach_tiep_theo.md`. Code: `src/nmpc/`. Chạy trên GitHub Actions: `.github/workflows/nmpc.yml`.*

## 1. Vì sao cần mô hình rút gọn

Mô hình DFN đầy đủ (`src/dfn/`) có 1 652 trạng thái vi phân và 181 ẩn đại số. Một lần mô phỏng mất 10–20 giây. Bộ điều khiển NMPC phải giải một bài toán tối ưu mỗi 30 giây, mỗi bài toán cần tích phân mô hình hàng chục lần cùng với đạo hàm của nó. Với DFN đầy đủ thì không làm được.

Mô hình rút gọn ở đây **không phải là một mô hình khác**. Nó là **chính hệ phương trình DFN**, cùng bộ tham số `dfn_params()` (bộ `approved`), chỉ khác ở cách chia lưới:

- ít ô hơn theo bề dày cell (x),
- ít vỏ hơn trong mỗi hạt (r),
- và một vài phép tính được làm bằng công thức giải tích thay cho giải số.

Nhờ vậy mọi tham số, mọi hàm OCP, j₀, D_s… vẫn y hệt DFN, không có tham số mới phải "chỉnh". Khác biệt giữa ROM và DFN chỉ là sai số rời rạc hoá, và được đo trực tiếp (mục 7).

## 2. Lưới của ROM

DFN mặc định: cực âm 20 ô, màng ngăn 10 ô, cực dương 20 ô; hạt cực âm 60 vỏ, hạt cực dương 20 vỏ (đều nhau).

ROM gộp các ô/vỏ của DFN lại. **Mọi mặt ô và mặt vỏ của ROM đều trùng một mặt của DFN.** Có hai lợi ích:

1. Đổi trạng thái DFN sang ROM bằng **trung bình thể tích chính xác**. Tổng lithium trong hạt và trong điện giải được bảo toàn đúng (kiểm tra tự động trong `rom_unit_tests.m`).
2. Ô cuối của cực âm (sát màng ngăn) rộng **đúng bằng một ô DFN**. Tâm của nó trùng tâm nút DFN sát màng ngăn nhất, x = L_n − L_n/40. Đây là chỗ dễ mạ lithium nhất. Vì vậy thế mạ lithium và stoichiometry bề mặt "phía màng ngăn" của hai mô hình được so ở **cùng một vị trí**, không phải nội suy.

Các cấu hình đã so với DFN (`rom_preset.m`):

| Cấu hình | Ô cực âm (số ô DFN gộp lại, từ x = 0) | Vỏ hạt cực âm (mặt vỏ theo đơn vị R/60) | Ô màng ngăn / cực dương | Vỏ hạt cực dương (đơn vị R/20) |
|---|---|---|---|---|
| A | 4 ô: [9 6 4 1] | 8 vỏ: [0 20 32 40 46 51 55 58 60] | 1 / 2 ô [10 10] | 4 vỏ: [0 10 15 18 20] |
| B | như A | 8 vỏ: [0 24 36 44 50 54 57 59 60] | như A | như A |
| C | 6 ô: [8 5 3 2 1 1] | như B | như A | như A |
| D | như C | 10 vỏ: [0 20 30 38 44 49 53 56 58 59 60] | như A | như A |

Lý do chọn lưới không đều: phản ứng và gradient nồng độ tập trung ở phía màng ngăn (theo x) và ở gần bề mặt hạt (theo r). Dồn ô/vỏ về đó giúp tính đúng hai đại lượng mà NMPC cần nhất: thế mạ lithium và stoichiometry bề mặt phía màng ngăn. Cực dương có hệ số khuếch tán hiệu dụng lớn gấp 84–323 lần do khuếch tán ứng suất (GD-10), nên hạt cực dương gần như đều, 4 vỏ là đủ.

**Chọn cấu hình D** cho NMPC. Lý do (số liệu ở mục 7, khi sạc — trường hợp NMPC dùng): so với A, cấu hình D giảm sai số stoichiometry bề mặt phía màng ngăn và thế mạ lithium khoảng 2–3 lần (η_Li RMS 0.5–3.3 mV thay vì 1.2–7.8 mV), và là cấu hình duy nhất mà ở 2C, 10 °C ROM dừng cùng lý do với DFN (A dừng vì bão hoà bề mặt sau 633 s, DFN tới 4.2 V sau 1089 s). C gần bằng D khi sạc nhưng kém hơn khi xả. Cấu hình D có 87 trạng thái vi phân (hạt cực âm 6 × 10 vỏ, hạt cực dương 2 × 4 vỏ, điện giải 9 ô, nhiệt độ, SOC, 6 nồng độ lithium mạ, 2 bộ đếm lithium mất) và 10 ẩn đại số; DFN có 1 652 + 181.

## 3. Các phương trình (giống DFN, từng bước)

Ký hiệu, quy ước dấu như `src/dfn/dfn_rhs.m`: dòng I > 0 là xả; j > 0 là phản ứng anod (Li rời hạt).

### 3.1 Khuếch tán trong hạt

Mỗi ô x của ROM có một hạt đại diện. Phương trình như DFN:

  ∂θ/∂t = (1/r²) ∂/∂r ( r² D_eff(θ, T) ∂θ/∂r ),  D_eff ∂θ/∂r |_(r=R) = −j_int/(F c_max)

Rời rạc thể tích hữu hạn trên các vỏ của ROM. Thông lượng giữa hai vỏ là (K(θ_{i+1}) − K(θ_i))/Δr, với K là tích phân Kirchhoff của D_eff — **đúng cách DFN làm** (`dfn_Ktable.m`, GD-15). Lý do: D_s,n có những "hố" rất hẹp (rộng ≈ 0.025 theo stoichiometry); lấy D tại điểm giữa có thể cho kết quả sai khi hai vỏ chênh nhau nhiều.

Khác DFN ở một chỗ: DFN tra K trong bảng nội suy pchip; ROM cần biểu thức ký hiệu (để acados lấy đạo hàm), nên tính hiệu K(b) − K(a) = ∫ₐᵇ D_eff ds bằng **cầu phương Gauss–Legendre 8 điểm** của chính hàm `dfn_Ds.m` (`rom_dK.m`). Hai cách cùng tính một tích phân; độ lệch được in trong `rom_unit_tests_*.md`.

Stoichiometry bề mặt: ngoại suy tuyến tính từ tâm hai vỏ ngoài cùng tới r = R (như DFN).

### 3.2 Điện giải

Bảo toàn khối lượng, như DFN:

  ε ∂c_e/∂t = −∂N/∂x + a·j/F,  N = −ε^b D_e ∂c_e/∂x + t₊ i_e/F

Thể tích hữu hạn trên các ô ROM, tính chất tại mặt ô lấy trung bình điều hoà (như DFN). Hàm D_e, κ, t₊, hệ số nhiệt động: công thức Landesfeind & Gasteiger 2019 với hệ số của bộ `approved` (`rom_elyte.m`, so từng số với `dfn_elyte.m`).

### 3.3 Dòng điện và điện thế — chỗ rút gọn chính

Trong DFN, φ_s, φ_e, j tại mọi nút là ẩn đại số (181 ẩn). Trong ROM, mật độ dòng phản ứng j được coi là **không đổi trong mỗi ô** (đây chính là giả thiết của thể tích hữu hạn). Khi đó:

- dòng điện giải i_e(x) và dòng pha rắn i_s(x) = i_app − i_e(x) **biến thiên tuyến tính** trong mỗi ô, tính được bằng cộng dồn a·j·Δx;
- φ_s và φ_e giữa hai tâm ô tính được **bằng tích phân giải tích** của định luật Ohm:
  φ_e(k+1) = φ_e(k) − ∫ i_e/κ_eff dx + 2(1 − t₊)·χ·(RT/F)·[ln c_e(k+1) − ln c_e(k)]
  (cùng dạng dòng điện giải của DFN, GD-18), tương tự cho φ_s với σ.

Vậy chỉ còn ẩn đại số: j tại mỗi ô (4 + 2 = 6 ẩn với cấu hình A) và hai mốc điện thế (φ_e ở ô đầu, φ_s ở ô đầu cực dương) — tổng 8 ẩn. Các phương trình đại số là: Butler–Volmer tại mỗi ô (dạng nghịch đảo η = 2(RT/F)·asinh(j/(2j₀)), như DFN, GD-21), và hai điều kiện tổng dòng (Σ a_n j Δx = i_app; Σ a_p j Δx = −i_app).

Điện áp đầu cực: V = φ_s(x = L) − φ_s(x = 0) − I·R_contact (GD-20), φ_s(0) = 0.

### 3.4 OCP, j₀, màng SEI

- OCP: hàm `dfn_ocp_neg.m`, `dfn_ocp_pos.m` của DFN, ghép nhánh qua **chính hàm chung của DFN** `dfn_ocp_mix.m` (`rom_ocp.m` chỉ gọi lại): cực âm luôn nhánh delithiation (GD-40, duyệt 17/11/2026, `par.ocp_n_branch`), cực dương hysteresis "current sigmoid" (GD-14). `rom_unit_tests.m` mục 6 so `rom_ocp` với aux.Un, aux.Up của `dfn_rhs.m` ở I = −10…5 A và báo lỗi nếu lệch. Hàm tanh đã trơn nên không cần làm trơn thêm.
- j₀: dùng trực tiếp `dfn_j0.m` (GD-06).
- Quá thế màng SEI ρ_SEI·L_SEI·j (BOL) như hook `dfn_aging_state.m`.

### 3.5 Nhiệt lumped

Cùng cân bằng như DFN (GD-12): ρc_p,eff dT/dt = Q̄ − h·A_cool/V_cell·(T − T_amb), cùng các nguồn nhiệt (Joule pha rắn, Joule điện giải, nhiệt phản ứng j(φ_s − φ_e − U), nhiệt thuận nghịch j·T·∂U/∂T, current collector; nhiệt I²R_0 tuỳ GD-05). Vì dòng tuyến tính trong mỗi ô, nhiệt Joule ∫ i²/σ dx được tính **đúng** bằng Δx·(i_trái² + i_trái·i_phải + i_phải²)/3. Nhiệt dung `rom_rhocp.m` (so từng số với `dfn_rhocp.m`).

### 3.6 Làm trơn cho NMPC (ghi rõ mọi chỗ)

NMPC (acados) cần đạo hàm liên tục. DFN có ba chỗ dùng min/max "cứng"; ROM thay bằng hàm trơn sp(u) = (u + √(u² + ε²))/2:

| Chỗ | DFN | ROM | Sai lệch khi xa biên |
|---|---|---|---|
| chặn stoichiometry bề mặt trong j₀, OCP | min/max với [10⁻⁸, 1 − 10⁻⁸] | min/max trơn, ε = 10⁻⁹ | < 10⁻¹⁰ |
| chặn dưới c_e trong log, căn | max(c_e, 0.01) | max trơn, ε = 10⁻³ mol/m³ | < 10⁻⁹ mol/m³ |
| chặn trên c_e ≤ 4000 mol/m³ (S12) | min | min trơn, ε = 0.01 mol/m³ | < 3·10⁻⁸ mol/m³ |

Trong vận hành bình thường không biên nào bị chạm, nên ba chỗ này không làm đổi kết quả.

## 4. Các đại lượng ra cho NMPC

- V, T, SOC (SOC = (x̄_n − x₀)/(x₁₀₀ − x₀), dung lượng 4.861 Ah, GD-24).
- Stoichiometry bề mặt cực âm ở ô sát màng ngăn: x_s,sep.
- φ_s − φ_e ở ô sát màng ngăn.
- Thế mạ lithium η_Li,sep = φ_s − φ_e − ρ_SEI·L_SEI·j (tại ô sát màng ngăn). Thế cân bằng Li/Li⁺ = 0 nên η_Li < 0 nghĩa là mạ thuận lợi về nhiệt động.
- Tốc độ mất lithium do SEI và do mạ lithium (mục 6).

## 5. Đổi trạng thái DFN sang ROM (NMPC "biết hết trạng thái")

`rom_from_dfn.m`. Stoichiometry trong hạt: trung bình thể tích các vỏ DFN nằm trong mỗi vỏ ROM, rồi trung bình các nút DFN trong mỗi ô ROM. c_e: trung bình các ô DFN trong ô ROM. T giữ nguyên. SOC tính từ x̄_n. Lithium mạ: trung bình bộ đếm hậu kiểm theo nút. Ẩn đại số z: giải lại bằng Newton (`rom_solve_z.m`).

Bộ ước lượng EKF (bước F) sẽ thay hàm này: bộ điều khiển chỉ nhận vector trạng thái ước lượng (`nmpc_solve.m`, đối số `xhat`), không đọc gì khác từ DFN.

## 6. Lão hoá trong NMPC — TẠM THỜI

Lão hoá **chưa nằm trong DFN** (bước C chưa làm). Để NMPC và việc chấm điểm có một con số "lithium mất", ta dùng **cùng một công thức** (`aging_rates.m`) ở cả hai nơi:

- trong ROM/NMPC: là trạng thái và hàm mục tiêu;
- trên quỹ đạo DFN: tính **hậu kiểm** (`aging_track.m`), không hồi tiếp vào DFN.

Công thức (đặc tả: `tai_lieu/dac_ta_lao_hoa.md` mục 3, 4, 6.2; phân xử bài gốc: `gia_dinh.md` mục 1):

- SEI (bề mặt gốc + vết nứt): tốc độ mất Li trên thể tích điện cực
  r_SEI = a_n·S₀·(D_int·c_int/L_outer)·exp(−F(φ_s − φ_e)/(RT))·exp(E_SEI/R·(1/T_ref − 1/T)),
  D_int = 9.81·10⁻¹⁹ m²/s, E_SEI = 5000 J/mol (Li 2025 Table 3, cột "5 coupled"), c_int = 15 mol/m³ (SI Table 8), L_outer = L_SEI,0 mỗi lớp (GD-02), S₀ = 2.908 (SI pt. S8). Tương đương hệ số 1/4 mỗi lớp với z_SEI = 2 khi đổi ra độ dày.
- Mạ lithium (O'Kane 2022, α_c = 0.65, α_a = 0.35; k_Li = 10⁻¹⁰ m/s, γ₀ = 10⁻⁷ 1/s, Li 2025 Table 3):
  j_pl = F·k_Li·[c_Li·exp(α_a F η_Li/(RT)) − c_e·exp(−α_c F η_Li/(RT))],
  dc_Li/dt = −a_n j_pl/F − γ₀ c_Li (lithium chết tăng γ₀ c_Li).
- "Lithium mất" = SEI + lithium mạ (gồm cả phần thuận nghịch chưa bóc lại và lithium chết), đơn vị mAh.

Giữ cố định trong một lần sạc: độ dày SEI, độ nhám S₀ (thay đổi trong một lần sạc cỡ 10⁻⁴ lần giá trị, không đáng kể), và **không** cho dòng phụ chảy ngược vào cân bằng điện tích. Khi bước C xong, cả ROM lẫn chấm điểm phải dùng lão hoá thật của DFN.

Lưu ý: luật mạ này không có ngưỡng — kể cả khi η_Li > 0 vẫn có một lượng nhỏ lithium mạ "cân bằng", và nó tăng nhanh khi nhiệt độ thấp.

## 7. Kiểm chứng ROM với DFN

Workflow `.github/workflows/nmpc.yml`, job `rom` (16 job song song: 4 cấu hình × sạc/xả × 25/10 °C). Hai mô hình bắt đầu từ **cùng** trạng thái (ROM là ảnh xạ của trạng thái DFN). Dòng không đổi 0.3C, 1C, 2C. Sạc: từ SOC 0 tới khi DFN dừng; xả: từ SOC 1 tới 2.5 V. Điều kiện dừng giống nhau (4.2 V / 2.5 V, hoặc bề mặt hạt chạm 1 − 10⁻⁴: sự kiện của DFN, GD-16). Sai số tính trên khoảng thời gian chung của hai lần chạy. "sep" = ô cực âm sát màng ngăn (cùng tâm x ở hai mô hình).

Bảng dưới: lượt chạy so sánh cấu hình (https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44045657657), với OCP cực âm cũ (hysteresis). **Lượt chạy lại với OCP cực âm mới (GD-40)**, https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44066290438, chỉ cấu hình D, khi sạc (xả không đổi):

| | T (°C) | C-rate | lý do dừng DFN / ROM | t cuối DFN / ROM (s) | V: RMS / max (mV) | x_s,sep: RMS / max | η_Li,sep: RMS / max (mV) | T max (K) | ảnh xạ: V / φ_s−φ_e,sep max (mV) | SEI DFN / ROM (mAh) | Li mạ DFN / ROM (mAh) | chạy DFN / ROM (s) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sạc | 25 | 0.3C | 4.2 V / 4.2 V | 11446 / 11438 | 1.21 / 2.79 | 0.003 / 0.016 | 0.62 / 2.06 | 0.01 | 0.11 / 0.08 | 0.073 / 0.073 | 3.47 / 3.46 | 22.6 / 2.6 |
| sạc | 25 | 1C | 4.2 V / 4.2 V | 2896 / 2884 | 3.00 / 4.95 | 0.010 / 0.038 | 1.28 / 2.66 | 0.04 | 0.46 / 0.47 | 0.036 / 0.036 | 1.35 / 1.33 | 15.3 / 2.2 |
| sạc | 25 | 2C | 4.2 V / 4.2 V | 1234 / 1227 | 4.92 / 9.39 | 0.016 / 0.061 | 2.13 / 6.84 | 0.10 | 0.60 / 0.91 | 0.028 / 0.028 | 0.66 / 0.64 | 9.1 / 2.0 |
| sạc | 10 | 0.3C | bão hoà / bão hoà | 10809 / 10748 | 1.94 / 3.76 | 0.006 / 0.024 | 0.87 / 2.46 | 0.01 | 0.13 / 0.18 | 0.069 / 0.069 | 3.37 / 3.32 | 15.6 / 1.5 |
| sạc | 10 | 1C | 4.2 V / 4.2 V | 2706 / 2690 | 4.58 / 8.05 | 0.012 / 0.052 | 1.75 / 4.03 | 0.07 | 0.81 / 0.71 | 0.057 / 0.057 | 1.62 / 1.57 | 8.3 / 1.4 |
| sạc | 10 | 2C | 4.2 V / 4.2 V | 1136 / 1124 | 8.57 / 25.09 | 0.023 / 0.104 | 4.07 / 12.84 | 0.27 | 1.92 / 2.33 | 0.049 / 0.051 | 0.80 / 0.77 | 5.9 / 1.3 |

Với OCP mới, sạc ở 25 °C nay tới 4.2 V thay vì dừng vì bão hoà; ở 10 °C, 0.3C vẫn bão hoà (GD-16). Bảng cũ (OCP cực âm hysteresis, cả sạc và xả):

| | T (°C) | C-rate | lý do dừng DFN / ROM | t cuối DFN / ROM (s) | V: RMS / max (mV) | x_s,sep: RMS / max | η_Li,sep: RMS / max (mV) | T max (K) | ảnh xạ: V / φ_s−φ_e,sep max (mV) | SEI DFN / ROM (mAh) | Li mạ DFN / ROM (mAh) | thời gian chạy DFN / ROM (s) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sạc | 25 | 0.3C | bão hoà / bão hoà | 10819 / 10753 | 1.09 / 1.80 | 0.006 / 0.025 | 0.48 / 1.13 | 0.01 | 0.12 / 0.09 | 0.130 / 0.129 | 5.34 / 5.27 | 25.5 / 2.1 |
| sạc | 25 | 1C | bão hoà / bão hoà | 2742 / 2718 | 2.82 / 4.10 | 0.014 / 0.066 | 1.15 / 4.37 | 0.04 | 0.49 / 0.60 | 0.077 / 0.077 | 2.33 / 2.27 | 18.5 / 1.9 |
| sạc | 25 | 2C | 4.2 V / 4.2 V | 1192 / 1186 | 4.53 / 7.45 | 0.018 / 0.086 | 1.88 / 8.41 | 0.09 | 0.97 / 0.81 | 0.074 / 0.075 | 1.29 / 1.25 | 12.3 / 1.8 |
| sạc | 10 | 0.3C | bão hoà / bão hoà | 10212 / 10137 | 1.79 / 2.65 | 0.008 / 0.033 | 0.71 / 1.90 | 0.01 | 0.14 / 0.15 | 0.137 / 0.135 | 5.57 / 5.48 | 15.2 / 1.0 |
| sạc | 10 | 1C | bão hoà / bão hoà | 2549 / 2530 | 4.34 / 6.37 | 0.019 / 0.099 | 1.67 / 5.85 | 0.07 | 0.37 / 0.59 | 0.135 / 0.136 | 2.99 / 2.89 | 8.7 / 1.1 |
| sạc | 10 | 2C | 4.2 V / 4.2 V | 1089 / 1078 | 7.52 / 17.06 | 0.036 / 0.165 | 3.32 / 12.80 | 0.21 | 4.62 / 3.43 | 0.148 / 0.154 | 1.66 / 1.59 | 6.4 / 0.8 |
| xả | 25 | 0.3C | 2.5 V / 2.5 V | 11410 / 11405 | 1.75 / 11.32 | 0.004 / 0.023 | 1.25 / 10.71 | 0.01 | 0.32 / 0.22 | 0.020 / 0.020 | ≈ 0 | 16.0 / 1.1 |
| xả | 25 | 1C | 2.5 V / 2.5 V | 3316 / 3314 | 4.47 / 19.65 | 0.005 / 0.031 | 2.74 / 18.06 | 0.08 | 0.75 / 0.30 | 0.0024 / 0.0024 | ≈ 0 | 16.5 / 1.2 |
| xả | 25 | 2C | 2.5 V / 2.5 V | 1624 / 1622 | 7.24 / 26.93 | 0.007 / 0.051 | 4.23 / 24.55 | 0.20 | 0.95 / 1.01 | 0.0006 / 0.0006 | ≈ 0 | 13.0 / 1.2 |
| xả | 10 | 0.3C | 2.5 V / 2.5 V | 11283 / 11277 | 2.73 / 14.55 | 0.004 / 0.028 | 1.77 / 13.51 | 0.02 | 0.28 / 0.13 | 0.0088 / 0.0088 | ≈ 0 | 15.6 / 1.4 |
| xả | 10 | 1C | 2.5 V / 2.5 V | 3270 / 3266 | 7.31 / 26.03 | 0.006 / 0.033 | 4.54 / 23.68 | 0.15 | 0.67 / 0.76 | 0.0008 / 0.0009 | ≈ 0 | 12.7 / 1.4 |
| xả | 10 | 2C | 2.5 V / 2.5 V | 1598 / 1594 | 10.67 / 37.71 | 0.007 / 0.056 | 5.90 / 34.66 | 0.33 | 1.25 / 1.67 | 0.0003 / 0.0003 | ≈ 0 | 10.0 / 1.3 |

Đọc bảng:
- **Khi sạc** (chế độ NMPC dùng): điện áp lệch RMS 1–8 mV; thế mạ lithium phía màng ngăn lệch RMS 0.5–3.3 mV, lớn nhất 13 mV (2C, 10 °C); nhiệt độ lệch < 0.21 K. Lithium mất tạm thời (SEI, mạ) của ROM lệch DFN 1–5 %.
- Sai số lớn nhất của x_s,sep (0.03–0.17) rơi vào **cuối** mỗi lần sạc, khi bề mặt hạt phía màng ngăn tăng vọt tới 1 (GD-16): một chênh lệch thời điểm nhỏ thành chênh lệch lớn về giá trị. RMS chỉ 0.006–0.036.
- **Khi xả**, sai số lớn nhất (11–38 mV) nằm ở vài phút cuối, gần 2.5 V; RMS 2–11 mV. NMPC không điều khiển xả.
- Cột "ảnh xạ": ROM tính tại trạng thái DFN đã ảnh xạ (đúng cái NMPC "biết hết trạng thái" nhìn thấy) lệch DFN ≤ 4.6 mV về V và ≤ 3.4 mV về φ_s − φ_e.
- ROM chạy nhanh hơn DFN 7–15 lần trong MATLAB (ode15s cả hai). Trong NMPC, ROM được acados sinh mã C.
- Các thành phần (`rom_unit_tests_D.md`): điện giải lệch `dfn_elyte` < 10⁻⁸ tương đối; nhiệt dung khớp `dfn_rhocp` tới sai số máy; tích phân Kirchhoff Gauss–Legendre lệch bảng DFN ≤ 1.1·10⁻³ tương đối (trong khi bảng DFN cũng là xấp xỉ); OCV lúc nghỉ trùng DFN < 1 µV; ảnh xạ bảo toàn lithium tới 10⁻⁹.

Vì sao còn sai số: ROM gộp 20 ô cực âm DFN thành 6 ô và 60 vỏ hạt thành 10 vỏ. Phân bố phản ứng theo x và gradient trong hạt bị làm thô; sai số tăng theo C-rate và khi lạnh (D_s nhỏ, gradient dốc), đúng như bảng.

## 8. Bộ điều khiển NMPC

Code: `nmpc_model.m`, `nmpc_build.m` (tạo bộ giải acados **một lần mỗi job**), `nmpc_solve.m` (một lần giải từ trạng thái ước lượng), `nmpc_closed_loop.m` (vòng kín với DFN), `nmpc_config.m` (các giá trị, GD-26…GD-30).

### 8.1 Biến và mô hình dự báo

- Trạng thái: X = [x_ROM (87); I_ch; t_f]. I_ch ≥ 0 là dòng sạc [A]; t_f là thời gian sạc **còn lại** [giờ], là một trạng thái tự do (không cố định ở nút đầu, đạo hàm bằng 0).
- Điều khiển: u = dI_ch/dτ. Dòng sạc vì vậy liên tục, tuyến tính từng khoảng; ΔI giữa hai nút = u/N.
- Thời gian chuẩn hoá τ ∈ [0, 1]: dx_ROM/dτ = 3600·t_f·f_ROM(x_ROM, z, I = −I_ch), 0 = g_ROM(x_ROM, z, I).
  Vì t_f là ẩn, cùng một bài toán phục vụ cả hai chế độ "ngân sách" và "không giới hạn".
- Ẩn đại số z (10) giữ nguyên trong acados (DAE chỉ số 1, tích phân IRK).

### 8.2 Ràng buộc

| Ràng buộc | Dạng | Loại |
|---|---|---|
| 0 ≤ I_ch ≤ I_max = 10 A | biên trạng thái | cứng (GD-26) |
| V ≤ 4.2 V | h(x, z) ≤ 0 | mềm, phạt L1 10⁴/V + L2 10⁵/V² |
| T ≤ T_max = 45 °C | h ≤ 0 | mềm (GD-27) |
| η_Li,sep ≥ δ = 10 + 35 = 45 mV | h ≤ 0 | mềm (GD-28; +35 mV duyệt 17/11/2026) |
| x_s,sep ≤ 0.99 | h ≤ 0 | mềm (GD-29) |
| t_f ≤ ngân sách còn lại | h ≤ 0 | mềm, 10² mỗi giờ |
| SOC(τ = 1) ≥ SOC đích | h_e ≤ 0 | mềm, 10³ mỗi đơn vị SOC |

Ràng buộc mềm để bài toán luôn có nghiệm. Thứ tự ưu tiên khi không thể thoả cùng lúc: giới hạn vật lý (V, η_Li, x_s) > tới SOC đích > đúng ngân sách thời gian. Nghĩa là nếu ngân sách quá chặt (ví dụ k = 0.8) thì NMPC **sạc lâu hơn ngân sách** chứ không vượt giới hạn vật lý; vòng kín báo phần vượt ngân sách. V, η_Li, x_s phụ thuộc z nên chỉ ràng buộc ở các nút 1…N−1 (acados không cho ràng buộc phụ thuộc z ở nút cuối); vòng kín giải lại mỗi 30 s nên phần cuối được kiểm tra dần.

### 8.3 Hàm mục tiêu

  min ½·w_loss·(n_SEI(τ=1) + n_pl(τ=1)) + ½·w_ΔI·∫ u² dτ

- n_SEI: lithium mất do SEI **dự báo từ lúc giải** (đặt về 0 ở mỗi lần giải); n_pl: lượng lithium mạ (thuận nghịch + chết) — giá trị đầu là lượng hiện có trên pin; mAh (mục 6).
- Viết dưới dạng bình phương tối thiểu y_e = √(w_loss·(n_SEI + n_pl) + ε) để dùng Gauss–Newton (đạo hàm bậc nhất của hàm mục tiêu vẫn đúng). Chế độ "ngân sách": t_f ≤ k·T_CCCV − t (co dần). Chế độ "không giới hạn": t_f ≤ 20 h (chỉ là chặn số học; phải báo nếu chạm). SEI tăng theo thời gian nên có điểm tối ưu bên trong.
- w_ΔI = 10⁻⁴ nhỏ: chỉ để dòng không dao động.

### 8.4 Thời gian dự báo và chu kỳ lấy mẫu

- Dự báo phủ **toàn bộ phần sạc còn lại** (t_f), chia N = 20 khoảng. Lý do: mục tiêu (lithium mất cả lần sạc) và điều kiện cuối (SOC đích, ngân sách) là của cả lần sạc; cắt ngắn tầm dự báo sẽ phải đặt chi phí cuối thay thế không có cơ sở. Mỗi khoảng dài t_f/20 (ví dụ 140 s khi t_f = 0.78 h).
- Giải lại mỗi T_s = 30 s (hoặc ngắn hơn khi khoảng đầu < 30 s ở cuối lần sạc). Lý do: hằng số thời gian nhanh nhất cần theo dõi là của điện giải (L²/D_e ≈ 30–60 s) và lớp vỏ ngoài của hạt; nhiệt (τ ≈ 570 s) và khuếch tán trong hạt cực âm (R²/D_s ≈ 10³ s) chậm hơn nhiều.
- Tích phân: IRK Radau IIA 2 nấc × 8 bước mỗi khoảng. Quét trên CI (`nmpc_irk_sweep.m`, một khoảng 140 s, SOC ≈ 0.47): 2 bước + 20 lần lặp Newton cho NaN (Newton của IRK phân kỳ); 4 bước: sai 3·10⁻³ (max |Δx|); 8 bước: 1.5·10⁻⁴, 14 ms; 16 bước: 4·10⁻⁵, 21 ms.
- SQP, Gauss–Newton, QP bằng HPIPM. **Không có tìm kiếm đường**: acados v0.6 dừng chương trình (`exit(1)`, "not implemented yet for nz>0") khi tìm kiếm đường phải đánh giá ràng buộc phụ thuộc z. Thay vào đó: Levenberg–Marquardt (= 1) làm vùng tin cậy cho bước SQP, và vùng tin cậy riêng cho t_f (× [1/1.3, 1.3], dịch theo nghiệm và giải lại nếu nghiệm chạm biên vùng). Nếu một lần giải thất bại: giữ dòng hiện tại 30 s, khởi tạo lại đoán đầu bằng mô phỏng ROM.

### 8.5 Vòng kín

Pin "thật" = DFN đầy đủ (`src/dfn`, không sửa), chạy từng đoạn T_s với dòng I_ch(t) = I_ch + slope·t do NMPC trả về. Sau mỗi đoạn: ảnh xạ trạng thái DFN → ROM (mục 5) làm "ước lượng" cho lần giải sau. Lão hoá trên quỹ đạo DFN được tính hậu kiểm bằng cùng công thức (mục 6). Kết thúc khi SOC của DFN tới SOC đích (sự kiện của ode15s).

## 9. Kết quả chạy thử và tình trạng (17/11/2026) — CHƯA CHẠY ĐƯỢC VÒNG KÍN

**Đã làm được:**
- CCCV 0.5C theo vùng trên DFN (`cccv_window.m`; số dưới đây chạy với OCP cực âm CŨ, trước GD-40): 0→50 %: T_CCCV = 3500 s, dừng ở SOC đích trong pha CC, SEI 0.021 mAh, Li mạ 1.21 mAh; 25→75 %: 3500 s, SEI 0.064 mAh, Li mạ 2.75 mAh.
- Bộ giải acados (DAE, z trong ràng buộc) sinh mã và biên dịch trong 40–60 s mỗi job; tích phân một khoảng bằng bộ tích phân độc lập khớp ode15s (mục 8.4).

**Chưa làm được — vòng kín NMPC thất bại ở mọi lượt chạy thử** (lượt cuối: https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44065100291 và …/44063937371):
1. Lần giải đầu: SQP (bước cố định + Levenberg–Marquardt) chạy tới giới hạn 60 vòng lặp, mất 48–83 s.
2. Lần giải sau (sau 30 s trên DFN): ma trận động lực của QP có NaN ở các nút cuối (14–19), rồi ở mọi nút. **Tại đúng các trạng thái đó**, bộ tích phân acados chạy riêng (không tính độ nhạy) và ode15s trên ROM đều cho kết quả hữu hạn, đúng. Vậy NaN nằm ở **độ nhạy** của bộ tích phân IRK trong OCP (hoặc ở bộ nhớ đoán đầu của nó), không phải ở mô hình.
3. Đã thử, không khắc phục được: tìm kiếm đường (acados v0.6 dừng chương trình khi ràng buộc phụ thuộc z: "not implemented yet for nz>0"); vùng tin cậy cho t_f; LM 10⁻³, 1, 10; 2/4/8/16 bước IRK; 8/12/20 lần lặp Newton; dừng Newton theo sai số 10⁻⁸; chặn trơn số mũ ngoài vùng vật lý.

**Hướng xử lý cần người dùng chọn** (mỗi hướng đều là thay đổi cách làm so với kế hoạch):
- (a) Khử ẩn đại số z ngay trong mô hình (giải g = 0 bằng Newton sinh mã của CasADi bên trong hàm động lực): mô hình thành ODE thuần, ràng buộc chỉ phụ thuộc x, dùng được tìm kiếm đường của acados. Cùng phương trình, cùng tham số; rủi ro: sinh mã rootfinder trong acados.
- (b) Tầm dự báo ngắn hơn với nhiều khoảng hơn (khoảng ≤ 30 s) và chi phí cuối thay thế — phải có cơ sở cho chi phí cuối.
- (c) Giải bài toán tối ưu bằng CasADi + IPOPT (collocation) thay cho acados — chậm hơn, nhưng có tìm kiếm đường và đánh giá đạo hàm chính xác.

**Ảnh hưởng của vấn đề điện áp sạc (GD-16):** CCCV vùng 50→100 % trên DFN dừng vì bề mặt hạt cực âm phía màng ngăn bão hoà trước 4.2 V (ở 0.3C: ≈ 4.16 V, SOC ≈ 0.92), nên T_CCCV của vùng này là thời gian tới lúc dừng, không phải tới 100 %; NMPC với x_s,sep ≤ 0.99 sẽ phải giảm dòng rất mạnh ở đầu cao. Theo quyết định 17/11/2026 (B), biên mạ lithium được cộng 35 mV (δ = 45 mV).

**Quyết định khác cần người dùng:** hàm mục tiêu tạm thời tính cả lithium mạ **thuận nghịch** (sẽ bóc lại khi xả). Với luật mạ không ngưỡng của Li 2025, phần này lớn hơn SEI 20–60 lần trong một lần sạc (CCCV 0→50 %: 1.21 mAh so với 0.021 mAh), nên nó sẽ quyết định nghiệm tối ưu. Có thể chỉ tính SEI + lithium chết, hoặc mô phỏng thêm pha xả như bước J.
