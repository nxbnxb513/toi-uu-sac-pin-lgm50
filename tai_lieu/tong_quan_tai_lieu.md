# Tổng quan tài liệu: Lão hoá pin Li-ion khi sạc/xả và điều khiển tối ưu giảm lão hoá

*Cập nhật: 17/11/2026. Hướng: mô hình điện hoá–nhiệt–lão hoá ghép, áp dụng cho cell LG M50 21700 (NMC811 / graphite-SiOx, 5 Ah).*

> **Quy tắc:**
> - Dùng tối đa 8 tài liệu (nới từ 5 lên 8 ngày 17/11/2026), tất cả phải được đọc toàn văn. Bài nào không còn dùng thì xoá file khỏi thư mục.
> - **Số liệu phải minh bạch.** Chỉ lấy số từ hai nguồn:
>   (a) bảng hoặc chữ trong 5 tài liệu, có ghi vị trí;
>   (b) tự khớp từ dữ liệu đo thô công khai bằng script nằm trong repo.
> - **Không đọc số liệu từ hình vẽ.** Giá trị nào là giả định thì phải ghi rõ là giả định.
>
> Các bảng tham số chép lại đầy đủ, kèm số trang, nằm trong thư mục `tham_so/`.

---

## 1. Danh sách 9 tài liệu

| # | Tài liệu | Vai trò | Bản đã đọc |
|---|---|---|---|
| [1] | O'Kane S.E.J. et al., "Lithium-ion battery degradation: how to model it", *Phys. Chem. Chem. Phys.* 24 (2022) 7909–7922. DOI [10.1039/D2CP00417H](https://doi.org/10.1039/D2CP00417H) | Cơ chế lão hoá và **phương trình ghép** SEI, mạ Li, nứt hạt, LAM trên nền DFN; tham số lão hoá (Bảng S4–S5) | arXiv:2112.02037v2 kèm SI (`OKane2022_arXiv.pdf`), CC BY |
| [2] | Perez H.E., Hu X., Dey S., Moura S.J., "Optimal Charging of Li-Ion Batteries With Coupled Electro-Thermal-Aging Dynamics", *IEEE TVT* 66(9) (2017) 7761–7770. DOI [10.1109/TVT.2017.2676044](https://doi.org/10.1109/TVT.2017.2676044) | Cách đặt bài toán tối ưu **thời gian sạc ↔ lão hoá**, đường Pareto; bài học rằng profile vòng hở thất bại khi pin già | Bản final của tác giả |
| [3] | Couto L.D. et al., "Faster and Healthier Charging of Lithium-Ion Batteries via Constrained Feedback Control", *IEEE TCST* (2022). DOI [10.1109/TCST.2021.3135149](https://doi.org/10.1109/TCST.2021.3135149) | EKF trên mô hình điện hoá rút gọn, chỉ đo I, V, T_s; ràng buộc mạ Li; điều khiển phản hồi; có thực nghiệm | Bản accepted (NSF PAR) |
| [4] | Chen C.-H. et al., "Development of Experimental Techniques for Parameterization of Multi-scale Lithium-ion Battery Models", *J. Electrochem. Soc.* 167 (2020) 080534. DOI [10.1149/1945-7111/ab9050](https://doi.org/10.1149/1945-7111/ab9050) | **Bộ tham số DFN gốc** của LG M50: hình học, c_max, cửa sổ tỉ lượng, hàm OCP có hệ số, động học theo nhiệt độ, chất điện phân | Bản WRAP (`Chen2020_JES.pdf`), CC BY-NC-ND |
| [5] | O'Regan K., Brosa Planella F., Widanage W.D., Kendrick E., "Thermal-electrochemical parameters of a high energy lithium-ion cylindrical battery", *Electrochimica Acta* 425 (2022) 140700. DOI [10.1016/j.electacta.2022.140700](https://doi.org/10.1016/j.electacta.2022.140700) | **Tham số nhiệt** và sự phụ thuộc nhiệt độ của LG M50; mô hình DFN ghép nhiệt | Bản accepted WRAP (`ORegan2022_ElectrochimActa.pdf`), **không có phụ lục SI** |

| [6] | Kirkaldy N., Samieian M.A., Offer G.J., Marinescu M., Patel Y., "Lithium-ion battery degradation: Comprehensive cycle ageing data and analysis for commercial 21700 cells", *J. Power Sources* 603 (2024) 234185. DOI [10.1016/j.jpowsour.2024.234185](https://doi.org/10.1016/j.jpowsour.2024.234185) | **Thực nghiệm lão hoá theo vùng SOC** trên chính cell LG M50T: 0–30, 70–85, 85–100, 0–100 %; 10/25/40 °C; 40 cell | Bản OA kèm SI (`Kirkaldy2024_JPS.pdf`), CC BY |
| [7] | Li R., Kirkaldy N.D., Oehler F.F., Marinescu M., Offer G.J., O'Kane S.E.J., *Nature Communications* 16 (2025) 2776. DOI [10.1038/s41467-025-57968-3](https://doi.org/10.1038/s41467-025-57968-3) | **Mô hình SEI phụ thuộc điện thế anode (tức phụ thuộc SOC)**, thay cho SEI của [1]; tham số lão hoá **khớp trên dữ liệu LG M50T** của [6] | Bản OA kèm SI 57 trang (`Li2025_NatCommun.pdf`), CC BY |
| [8] | Kirkaldy N. et al., *ACS Appl. Energy Mater.* 5 (2022) 13367. DOI [10.1021/acsaem.2c02047](https://doi.org/10.1021/acsaem.2c02047) | Số liệu dạng chữ về lão hoá ở vùng SOC thấp: silicon trong anode mất 70–80 % dung lượng khi chạy 0–30 % | Bản OA, không có SI (`Kirkaldy2022_ACSAEM.pdf`), CC BY |

| [9] | Ai W., Kirkaldy N., Jiang Y., Offer G., Wang H., Wu B., "A composite electrode model for lithium-ion batteries with silicon/graphite negative electrodes", *J. Power Sources* 527 (2022) 231142. DOI [10.1016/j.jpowsour.2022.231142](https://doi.org/10.1016/j.jpowsour.2022.231142) | Mô hình anode hai pha (graphite + silicon) cho chính cell LG M50T, có tham số từng pha. Không có mô hình lão hoá; OCP từng pha chỉ có ở hình | Bản accepted (`Ai2022_JPS.pdf`) |

**Đã đọc nhưng không dùng vì khác cell (Sony VTC5A), đã xoá file:** Karger et al. 2024 (*J. Power Sources* 593:233947) và Philipp et al. 2026 (arXiv:2604.26545). Ghi nhận một kết luận của Karger 2024 để tham khảo: trong bộ dữ liệu của họ, dòng sạc không nằm trong ba yếu tố lão hoá quan trọng nhất (DOD, nhiệt độ, SOC).

**Phạm vi đề tài (chốt 17/11/2026):** với mỗi vùng sạc (0→10 %, 0→20 %, …, 10→20 %, 10→30 %, …), tìm profile dòng sạc I(t) ít lão hoá nhất và so với CCCV trong chính vùng đó. Lão hoá lịch nằm ngoài phạm vi, chỉ nhắc qua bằng đồ thị thực nghiệm của người dùng.

**Đã loại và đã xoá file:** Lin 2013, Lin 2014 (mạch tương đương của cell A123 LFP), Moura 2017 (bộ quan sát SPMe). Cùng với đó bỏ luôn bộ dữ liệu A123 trên Mendeley.

### Nguồn dữ liệu đo (không phải bài báo)

| Dữ liệu | Nội dung | Giấy phép | Dùng để |
|---|---|---|---|
| O'Regan 2021 Data Repository, Zenodo DOI [10.5281/zenodo.5171874](https://doi.org/10.5281/zenodo.5171874) | CSV đo thô: hệ số entropy dU/dT (2 điện cực), nhiệt dung riêng, độ dẫn nhiệt, độ dẫn điện tử, dòng trao đổi j₀(x,T) ở 15–45 °C, hệ số khuếch tán D_s(x,T) ở 5–45 °C | **CC BY 4.0** | Tự khớp dU/dT, j₀(T), D_s(T). Thay cho các bảng S7–S9 của [5] mà ta không có |
| TEC-reduced-model, Zenodo DOI [10.5281/zenodo.4864437](https://doi.org/10.5281/zenodo.4864437) | Dữ liệu xả LG M50 ở C/10, C/2, 1C, 2C tại 0/10/25 °C, mỗi điều kiện 4 cell; có V, I và **nhiệt độ bề mặt** (giữa thân, đầu dương, đầu âm, môi trường) | BSD-3-Clause; tác giả đề nghị trích dẫn bài Brosa Planella et al. 2021, *Electrochim. Acta* 388:138524 | Kiểm chứng mô hình điện–nhiệt; nhận dạng hệ số tản nhiệt h và nhiệt dung |

---

## 2. Cơ chế lão hoá và các tương tác ([1])

| Cơ chế | Tác nhân | Hệ quả | Phương trình trong [1] |
|---|---|---|---|
| SEI dày lên (giới hạn bởi khuếch tán dung môi, 1 lớp) | T (Arrhenius), thời gian, dòng | Mất Li (LLI); tạo điện trở màng | (1)–(8) |
| Mạ Li / bóc Li, Li chết | η_Li = φs − φe − η_SEI < 0; T thấp, sạc nhanh, SOC cao | LLI; tốc độ tạo Li chết γ = γ₀·L_SEI,0/L_SEI | (12)–(16) |
| Nứt hạt (định luật Paris) và SEI trên vết nứt | Ứng suất do gradient nồng độ, tức C-rate cao và T thấp | Thêm bề mặt mới nên SEI tăng | (17)–(21) |
| Mất vật liệu hoạt tính (LAM) | Ứng suất | ε_s giảm nên dung lượng giảm | (22)–(23) |

Các vòng tương tác chính:
- SEI tăng → điện trở tăng → nhiệt tăng → T tăng → SEI tăng nhanh hơn (hồi tiếp dương).
- η_SEI tăng → η_Li giảm → dễ mạ Li hơn khi pin đã già.
- Nhiệt độ có hai tác động ngược chiều: T cao làm SEI tăng, T thấp làm mạ Li và nứt hạt tăng. Vì vậy có một vùng nhiệt độ tối ưu.
- Mất Li (LLI) → dịch cửa sổ hệ số tỉ lượng → OCV và dung lượng thay đổi.

Theo [1], trong khoảng 25–45 °C LLI chiếm ưu thế; ở 5 °C thì LAM ở điện cực âm chiếm ưu thế. Thứ tự suy giảm là 5 °C nhiều nhất, rồi đến 45 °C, rồi 25 °C. Bài chỉ nêu thứ tự này bằng chữ, không có số %.

**Không cơ chế nào đo trực tiếp được khi pin đang vận hành** ([1]).

---

## 3. Bản đồ nguồn số liệu

| Nhóm tham số | Nguồn minh bạch | Ghi chú |
|---|---|---|
| Phương trình DFN | [4] Bảng I, [1] Bảng S1 | [4] có 2 lỗi in (BV: RT/F; V dùng φ_e) → dùng dạng của [1] |
| Hình học, độ xốp, c_max, bán kính hạt, Bruggeman | [4] Bảng VII, IX; [1] Bảng S2–S3 | Phải chọn rõ dùng giá trị đo (VII) hay giá trị đã tinh chỉnh (IX) |
| Cửa sổ tỉ lượng 0 % / 100 % SOC | [4]: dương 0.9084 / 0.2661, âm 0.0279 / 0.9014 | — |
| OCP U₊(x), U₋(x) | [4] pt. (8), (9), hệ số đầy đủ | Bài không nêu khoảng hợp lệ và nhánh của phép fit (KHÔNG RÕ) |
| Động học j₀, k và năng lượng hoạt hoá | [4] Bảng VI (17.8 / 35.0 kJ/mol); [5] trong chữ (31.1 / 54.8 kJ/mol); [1] pt. S1–S2 | Có hai bộ năng lượng hoạt hoá khác nhau, phải chọn một và nêu lý do |
| D_s theo nhiệt độ | [1]: E_D = 30300 / 25000 J/mol; [5] chỉ cho khoảng giá trị | Có thể tự khớp từ dữ liệu Zenodo 5171874. Theo [1], E_D+ là giá trị của NCA, không phải NMC |
| Chất điện phân κ(c_e), D_e(c_e) | [4] pt. (23)–(25) (Nyman); [1] pt. S6–S7, E = 17100 J/mol | t⁺ = 0.2594 |
| Nhiệt (khối lượng, Cp, độ dẫn nhiệt) | [5] Bảng 5–8 | Mô hình nhiệt **0D (một nhiệt độ)**; h = 15 W/m²K được **tinh chỉnh tay** |
| Nhiệt thuận nghịch dU/dT | Tự khớp từ Zenodo 5171874 | Hệ số trong [5] nằm ở bảng S9, ta không có |
| Tham số lão hoá | [1] Bảng S4–S5 | 7 / 22 ký hiệu là "Assumed"; **không tham số lão hoá nào được đo trên LG M50** |

---

## 4. Những gì còn thiếu hoặc chưa chắc chắn

1. **Mô hình nhiệt.** [5] dùng mô hình 0D vì coi jellyroll có nhiệt độ đều; [1] thì giữ nhiệt độ không đổi. Không có nguồn minh bạch nào cho mô hình 2 trạng thái lõi/bề mặt.
   - **Đề xuất:** plant dùng mô hình 0D theo [5]. Nhận dạng h và nhiệt dung từ dữ liệu nhiệt độ bề mặt (Zenodo 4864437).
   - Muốn có thêm trạng thái lõi thì phải tự tính điện trở nhiệt từ độ dẫn nhiệt các lớp trong [5]. Đây là suy diễn của đề tài, chưa được kiểm chứng, và [5] tự cảnh báo cách gộp này không chính xác. Nếu làm thì chỉ để phân tích độ nhạy.
2. **Tham số lão hoá chưa được kiểm chứng thực nghiệm** trên LG M50 ([1]). Mô hình cho đúng xu hướng và các tương tác, nhưng con số tuổi thọ tuyệt đối không đáng tin. Phải phân tích độ nhạy với các tham số "Assumed".
3. **Mạ Li** nên dùng làm **ràng buộc** η_Li ≥ 0 trong NMPC (như [3]). Ràng buộc này không cần các hằng số giả định k_Li, γ₀. Phương trình mạ Li đầy đủ chỉ dùng trong plant và phải phân tích độ nhạy.
4. **Nứt hạt và LAM** chỉ làm phần mở rộng. Lý do: tham số then chốt đều là giả định, và các pt. (17b), (18)–(20) của [1] có lỗi in.
5. **Dữ liệu kiểm chứng chỉ có phần xả**: [4] ở 25 °C; Zenodo 4864437 ở 0/10/25 °C. Không có dữ liệu kiểm chứng khi sạc.
6. **Các chỗ mâu thuẫn trong bài gốc** (đã đánh dấu KHÔNG RÕ trong `tham_so/`):
   - [4]: c_max âm 29603 hay 29583; k_n không tái tạo được từ pt. (20); bán kính SiOx.
   - [5]: Cp jellyroll 887 hay 866; mật độ separator.
   - [1]: α = 0.3/0.7 trong chữ nhưng 0.35/0.65 trong bảng.

---

## 5. Đại lượng đo được và không đo được

- **Đo được** (cảm biến thực tế): dòng I, điện áp V, nhiệt độ bề mặt T_s.
- **Không đo được, phải ước lượng:**
  - nồng độ Li trong hạt (bề mặt và trung bình), nồng độ c_e;
  - φs − φe và quá thế mạ Li η_Li;
  - độ dày SEI L_SEI, lượng Li đã mạ và Li chết;
  - lượng Li khả dụng n_Li (tức SOH);
  - SOC thực.

---

## 6. Hướng bài toán

Đã chốt, xem `de_bai.md` (đề bài, ràng buộc, giả định) và `mo_hinh_toan.md` (mô hình và phương án điều khiển).

---

## 7. Lão hoá theo vùng SOC ([6], [7], [8])

Chi tiết và số trang: `tham_so/Kirkaldy2024_tham_so.md`, `tham_so/Li2025_tham_so.md`, `tham_so/Kirkaldy2022_tham_so.md`. Mỗi file có mục "Khớp với 5 bài cũ".

### Thực nghiệm ([6], [8])
- [6] chạy 4 vùng SOC ở 3 nhiệt độ, luôn sạc 0.3C và xả 1C. Kết luận bằng chữ: vùng 70–85 % già chậm nhất; 0–30 % và 85–100 % già nhanh hơn; 85–100 % ở 10 °C tệ nhất.
- [6] **không có số theo từng vùng trong bảng hay chữ** (chỉ có hình). Dữ liệu thô công khai trên Zenodo 10.5281/zenodo.10637534 (CC BY 4.0, khoảng 49 GB).
- [8] có số dạng chữ: ở vùng 0–30 %, phần silicon mất 70–80 % dung lượng sau 4–5 kAh; graphite mất khoảng 10 %; LAM điện cực dương không phụ thuộc vùng SOC.

### Mô hình ([7])
- SEI giới hạn bởi khuếch tán lithium xen kẽ (interstitial), 2 lớp. Tốc độ tỉ lệ với exp(−(φs − φe)) / L_SEI, nên **phụ thuộc điện thế anode, tức phụ thuộc SOC** (SI Note 2, pt. S2–S9).
- Tham số khớp (Bảng 3), với c_int = 15 mol/m³:

  | Tham số | Mô hình "chỉ SEI" | Mô hình "5 cơ chế ghép" |
  |---|---|---|
  | D_int (m²/s) | 2.36·10⁻¹⁸ | 9.81·10⁻¹⁹ |
  | V̄_SEI (m³/mol) | 4·10⁻⁵ | 5.22·10⁻⁵ |
  | E_SEI (J/mol) | 1·10⁴ | 5·10³ |

- Mô hình "5 cơ chế ghép" còn cho k_Li = 10⁻¹⁰ m/s, γ₀ = 10⁻⁷ 1/s (thay các giá trị giả định của [1]).

### Hạn chế phải ghi trong báo cáo
1. [7] chỉ khớp trên vùng 70–85 % và kiểm chứng trên 85–100 %, đều ở dòng sạc 0.3C. Tác giả nói rõ mô hình **không tái tạo được vùng 0–30 % và 0–100 %**, vì thiếu cơ chế lão hoá của silicon. Mọi vùng sạc chạm SOC thấp là ngoại suy.
2. Kiểm chứng tốt ở 40 °C (sai số 10.58 %), kém hơn ở 25 °C, thất bại ở 10 °C.
3. [7] dùng bộ tham số nền của [5] với OCP mới và c_max khác [4] (52787 / 32544 mol/m³). Phải chọn một bộ nền thống nhất; nếu ghép D_int vào bộ [4] thì đó là giá trị khởi đầu, cần ghi là giả định.
4. Số mũ của SEI in trong [7] thiếu hệ số F/(RT). Phải đối chiếu với code trên Zenodo 10.5281/zenodo.14995785 trước khi dùng.
5. Không có dữ liệu thực nghiệm nào cho profile dòng sạc tối ưu hay cho lưới vùng SOC bước 10 %. Phần so sánh với CCCV là kết quả mô phỏng.
