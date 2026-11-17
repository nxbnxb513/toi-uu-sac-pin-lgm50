# Ai et al. 2022 — mô hình điện cực hỗn hợp silicon/graphite cho LG M50T (KHÔNG có suy giảm)

> Đã đọc TOÀN VĂN bản accepted manuscript trên kho Spiral Imperial (25 trang, "Preprint submitted to Elsevier, January 27, 2022").
> File: `tai_lieu/Ai2022_JPS.pdf`; text: `toan_van_trich_xuat/Ai2022.txt`.
> "tr. N" = trang PDF của bản manuscript, không phải trang tạp chí.

## 1. Trích dẫn, tạp chí, giấy phép

- W. Ai, N. Kirkaldy, Y. Jiang, G. Offer, H. Wang, B. Wu, "A composite electrode model for lithium-ion batteries with silicon/graphite negative electrodes", *Journal of Power Sources* **527** (2022) 231142. DOI: https://doi.org/10.1016/j.jpowsour.2022.231142
- Giấy phép: bản publisher là open access **CC BY** (theo Unpaywall, hybrid). Bản đã đọc là accepted manuscript từ Spiral (handle 10044/1/95291); chưa đối chiếu từng số với bản publisher.

## 2. Nội dung

- Mô hình P2D với **hai hạt cầu (graphite và silicon) tại mỗi nút của điện cực âm**, cùng thế pha rắn, tương tác qua điện phân (tr. 7–10).
- Cell kiểm chứng: **LG M50T** (LG GBM50T2170), tham số gần với LG M50 của Chen 2020 (tr. 10, 20). Đẳng nhiệt T = 298 K (tr. 11).
- **Không có bất kỳ mô hình suy giảm nào** (không LAM, không nứt, không SEI). Câu duy nhất về tuổi thọ là định tính: xả sâu ở C-rate cao khiến pha silicon chịu mật độ dòng rất lớn, "would suggest" làm xấu tuổi thọ silicon (tr. 18–19).

## 3. Phương trình (tr. 7–10)

- Khuếch tán: ∂c_k/∂t = (D_k/r²) ∂/∂r ( r² ∂c_k/∂r ), k = si, g (Eq. 1); biên D_k ∂c_k/∂r |_{R_k} = −j_k^Li / (a_k F) (Eq. 2)
- a_si = 3 V_si ε_s / R_si ; a_g = 3 V_g ε_s / R_g ; V_si + V_g = 1 (Eq. 3)
- j_k^Li = 2 a_k i_k,0 sinh[ 0.5F/(RT) · (φ_s − φ_e − φ_k,ocp) ] (Eq. 4)
- i_si,0 = m_n · sqrt( c_e · c_si,surf · (c_si,max − c_si,surf) ) · c_g,max / c_si,max ; i_g,0 = m_n · sqrt( c_e · c_g,surf · (c_g,max − c_g,surf) ) (Eq. 5)
- Hysteresis silicon: φ_si,ocp = sigmoid(−100 I/Q) · φ_si,ocp^de + sigmoid(100 I/Q) · φ_si,ocp^li (Eq. 6). Bài in "sigmoid(x) = [1 + sinh(x)]/2" (tr. 9); hẳn là tanh, xem mục 7.
- j^Li = j_si^Li + j_g^Li (Eq. 7)

## 4. Bảng tham số (chép nguyên văn)

### Table 2 (tr. 11) — Parameters of the LG M50 cell [Chen 2020]

| Parameter | Description | Negative | Separator | Positive | Trạng thái |
|---|---|---|---|---|---|
| L_k | Thickness [µm] | 85.2 | 12 | 75.6 | từ Chen 2020 (đo) |
| ε_e | Electrolyte volume fraction [%] | 25 | 47 | 33.5 | từ Chen 2020 |
| ε_k | Active material volume fraction [%] | 75 | - | 66.5 | từ Chen 2020 |
| b_k | Bruggeman coefficient | 2.91 | 2.57 | 2.43 | từ Chen 2020 |
| c_max | Max lithium concentration [mol m⁻³] | - | - | 63,104 | từ Chen 2020 |
| c_0 | Initial lithium concentration [mol m⁻³] | - | - | 17,038 | từ Chen 2020 |
| σ_k | Electrode conductivity [S m⁻¹] | 215 | - | 0.18 | từ Chen 2020 |
| D_k | Electrode diffusivity [m² s⁻¹] | - | - | 4×10⁻¹⁵ | từ Chen 2020 |
| R_k | Particle radius [µm] | - | - | 5.22 | từ Chen 2020 |
| m_k | Reaction rate [A m^2.5 mol^-1.5] | 6.48×10⁻⁷ | - | 3.42×10⁻⁶ | từ Chen 2020 |
| c_e^typ | Typical Li concentration in electrolyte [mol m⁻³] | 1×10³ | | | |
| D_e^typ | Typical electrolyte diffusivity [m² s⁻¹] | 5.34×10⁻¹⁰ | | | |
| κ_e^typ | Typical electrolyte conductivity [S m⁻¹] | 1.1 | | | |
| t₊⁰ | Transference number | 0.2594 | | | |

### Table 3 (tr. 12) — Additional parameters of graphite and silicon (* estimation)

| Parameter | Description | Graphite | Silicon | Trạng thái |
|---|---|---|---|---|
| c_max | Max lithium concentration [mol m⁻³] | 28,700 [Ai 2020] | 278,000 [Liu 2020] | văn liệu |
| c_0 | Initial lithium concentration [mol m⁻³] | 23,000* | 275,220* | ước lượng |
| V_k | Volume fraction in active material | 0.98* | 0.02* | ước lượng (lặp để khớp dung lượng) |
| R_k | Particle radius [µm] | 5.86 [Chen 2020] | 1.52 [Chen 2020] | đo (Chen 2020) |
| D_k | Diffusivity [m² s⁻¹] | 5.5×10⁻¹⁴ [Ai 2020] | 1.67×10⁻¹⁴ [Liu 2020] | văn liệu, hằng số |

- V_si = 2 % thay vì ∼10 % của Chen 2020, vì con số 10 % đến từ ảnh EDS bề mặt (tr. 11).

## 5. Kiểm chứng

- C/100 xả tới 2.5 V, nghỉ 1 h, C/100 sạc tới 4.2 V: tái hiện hysteresis điện áp (tr. 12).
- Xả 0.5C, 1C, 1.5C so với Chen 2020: "fair agreement"; lệch ở SOC thấp do dùng hệ số khuếch tán hằng (tr. 12). **Không có sai số dạng số (RMSE) nào được in.**
- Kết quả định tính có trong text: SOC cao graphite mang ∼0.9 I_app, SOC thấp silicon mang ∼0.9 I_app (Fig. 5, tr. 15, là sơ đồ minh hoạ); tăng V_si từ 0.001 đến 0.1 làm đỉnh mật độ dòng trên silicon giảm 90 % (tr. 17); cuối xả 2C silicon ở phía current collector có c/c_max = 0.3 so với 0.2 ở phía separator (tr. 16).

## 6. Dữ liệu / mã nguồn

- Bài không in link mã. Mô hình sau này có trong PyBaMM (tuỳ chọn hạt composite, bộ tham số `Chen2020_composite`, BSD-3) — thông tin từ tài liệu PyBaMM, **chưa kiểm tra mã trong lần đọc này**.

## 7. Không có dạng số (chỉ có hình) / KHÔNG RÕ

- **OCP của graphite và silicon (lithiation và delithiation)**: chỉ có Fig. A1 (tr. 19), nguồn Ai 2020 (graphite) và Verbrugge 2016 (silicon). Không in biểu thức hay bảng.
- Phân chia dòng Si/Gr theo SOC (Fig. 4), nồng độ trung bình theo SOC (Fig. 3c): chỉ hình.
- Hàm sigmoid in là [1 + sinh(x)]/2, không bị chặn trong [0, 1]; gần như chắc chắn là lỗi in của [1 + tanh(x)]/2. KHÔNG RÕ theo bài.
- Stoichiometry ứng với 0 % và 100 % SOC của từng pha: không in (chỉ có c_0 ở trạng thái đầy).
- Không có phụ thuộc nhiệt độ.

## 8. Khớp với các bài cũ

- **Cùng cell?** CÓ: LG M50T, cùng nhóm Imperial/Faraday với Kirkaldy 2022/2024, O'Kane 2022, Li 2025.
- **Bộ tham số nền?** Chen 2020 (Table 2 trùng Chen 2020), chỉ thay anode một pha bằng hai pha.
- **Gắn được gì vào DFN + Li 2025?** Eq. 1–7 và Table 3 cho phép tách anode thành Gr (98 %) + Si (2 %) để tính nồng độ, mật độ dòng và gradient trong hạt silicon theo cửa sổ SOC. Đó là đầu vào bắt buộc cho luật LAM_Si kiểu ứng suất (xem `Philipp2026_tham_so.md`), và cho biết cửa sổ nào thực sự khai thác silicon.
- **Vẫn phải giả định**: toàn bộ tham số suy giảm silicon; hàm OCP silicon/graphite (lấy từ mã PyBaMM hoặc số hoá từ bài gốc Verbrugge 2016); D_si hằng số; tham số cơ học của silicon; khác biệt R_si (1.52 µm ở đây, 0.1 µm ở Philipp 2026). O'Kane 2022 và Li 2025 dùng anode một pha, nên tham số SEI/plating của họ không tự động hợp lệ khi chuyển sang hai pha.

## 9. Kết luận

**Nên có (không thiết yếu).** Bài KHÔNG lấp khoảng trống suy giảm ở SOC thấp: không có phương trình hay tham số lão hoá nào. Giá trị của nó là cầu nối đúng cell (LG M50T) để mô hình hoá silicon như một pha riêng; chỉ cần trích dẫn nếu đồ án thực sự tách anode thành hai pha.
