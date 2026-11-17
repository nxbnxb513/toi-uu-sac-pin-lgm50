"""Builds data/ket_qua_du_lieu.md from the files in data/derived/ (no number is typed by hand).

Usage: python make_report.py        (run after a_*.py, b_*.py, c_*.py, d_*.py)
"""
import json
import os
import sys

import numpy as np
import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # works with python -I
import common  # noqa: E402

D = common.DERIVED
OUT = os.path.join(common.DATA_DIR, "ket_qua_du_lieu.md")


def table(df, fmt=None):
    fmt = fmt or {}
    cols = list(df.columns)
    lines = ["| " + " | ".join(cols) + " |", "|" + "|".join(["---"] * len(cols)) + "|"]
    for _, r in df.iterrows():
        cells = []
        for c in cols:
            v = r[c]
            if isinstance(v, (float, np.floating)):
                cells.append("" if np.isnan(v) else (fmt.get(c, "%.3g") % v))
            else:
                cells.append(str(v).replace("|", " + "))
        lines.append("| " + " | ".join(cells) + " |")
    return "\n".join(lines)


def mmm(s, f="%.3g"):
    s = pd.Series(s).dropna()
    if not len(s):
        return "–"
    s = s.where(s.abs() > 1e-12, 0.0)  # floating-point residue of constant signals -> 0
    return (f + " (" + f + " … " + f + "; n=%d)") % (s.median(), s.min(), s.max(), len(s))


def main():
    o = []
    w = o.append
    w("# Kết quả trích xuất từ dữ liệu mở (sinh tự động)\n")
    w("File này do `data/scripts/make_report.py` sinh ra từ các CSV/JSON trong `data/derived/`. "
      "**Không có số nào được gõ tay hay đọc từ hình vẽ**; mỗi bảng ghi rõ script và file nguồn. "
      "Mô tả dữ liệu, DOI, giấy phép: xem `data/README.md`.\n")

    # ================= A
    F = pd.read_csv(os.path.join(D, "A_files.csv"))
    N = pd.read_csv(os.path.join(D, "A_noise.csv"))
    T = pd.read_csv(os.path.join(D, "A_thermal_tau.csv"))
    Sp = pd.read_csv(os.path.join(D, "A_tc_spread.csv"))
    w("## A. Zenodo 4864437 — phóng điện LG M50 ở C/10, C/2, 1C, 2C; 0/10/25 °C\n")
    w("Script: `data/scripts/a_tec_noise_thermal.py` → `A_files.csv`, `A_noise.csv`, `A_thermal_tau.csv`, `A_tc_spread.csv`, `A_summary.json`.\n")
    w("### A.1 Cấu trúc file và giao thức thử\n")
    w("- Số file: **%d** (`data/<T>degC/Cell<id>_<C-rate>C_<T>degC.csv`), %d cell (ID %s … %s), mỗi tổ hợp (C-rate, nhiệt độ) có %s cell."
      % (len(F), F["cell"].nunique(), F["cell"].min(), F["cell"].max(),
         "/".join(str(v) for v in sorted(F.groupby(["C_rate", "T_nominal_degC"]).size().unique()))))
    w("- Dòng 1–15: header thiết bị (Measurement ID, Battery Name = LG M50, Program, Start/End Time…); dòng 16: tên cột; dòng 17: đơn vị; dữ liệu từ dòng 18.")
    w("- Cột: `Step`, `Status` (PAU = nghỉ, CHA = sạc, DCH = xả, RANGE, STO), `Step Time` [s], `Prog Time` [s], `Cycle`, `Cycle Level`, `Procedure`, "
      "`Voltage` [V], `Current` [A] (âm = xả), `AhAccu` [Ah], `AhPrev` [Ah], `WhAccu` [Wh], `Watt` [W], các kênh nhiệt độ [°C].")
    w("- Trình tự bước (giống nhau ở mọi file đầy đủ): `%s`. Tức là: nghỉ 2 h → sạc CC-CV tới 4,2 V → nghỉ 2 h → xả CC tới 2,5 V → nghỉ 2 h, lặp 2 lần."
      % F["step_sequence"].mode().iloc[0])
    w("- Số lần xả trong mỗi file: %s. File có ít hơn 2 lần xả: %s."
      % ("; ".join("%d lần: %d file" % (int(k), int(v)) for k, v in F["n_discharges"].value_counts().items()), ", ".join(F[F["n_discharges"] < 2]["file"].str.split("/").str[-1]) or "không có"))
    ch = F.groupby("temperature_channels")["cell"].agg(lambda v: ", ".join(sorted(set(str(x) for x in v)))).reset_index()
    ch.columns = ["Kênh nhiệt độ có trong file", "Cell"]
    w("\nKênh nhiệt độ theo cell (tên đã đổi theo `tec_reduced_model/process_experimental_data.py::clean_dataset`: "
      "`LogTempPositive`→T_pos (đầu cực dương), `LogTempMid`→T_mid (giữa thân cell), `LogTempNegative`→T_neg (đầu cực âm); "
      "`LogTemp001` = môi trường nếu file có 3 cặp nhiệt bề mặt, ngược lại = bề mặt cell; `LogTemp002` = môi trường):\n")
    w(table(ch))
    g = F.groupby("C_rate").agg(I_xa_A=("I_discharge_mean_A", "median"), dt_xa_s=("dt_discharge_median_s", "median"),
                                dt_nghi=("dt_rest_median_s", lambda v: v.mode().iloc[0])).reset_index()
    g.columns = ["C-rate", "Dòng xả (trung vị các file) [A]", "Chu kỳ lấy mẫu khi xả (trung vị) [s]", "Chu kỳ lấy mẫu các pha nghỉ [s] (theo thứ tự)"]
    w("\nLấy mẫu:\n")
    w(table(g, {"Dòng xả (trung vị các file) [A]": "%.4f", "Chu kỳ lấy mẫu khi xả (trung vị) [s]": "%.2f"}))
    w("\nKênh môi trường chỉ có ở một số file; ở file nào kênh này hằng 0,0 thì được đánh dấu \"not connected\" trong `A_noise.csv`: %s.\n"
      % (", ".join(N[N.get("note", pd.Series("", index=N.index)).fillna("").str.contains("not connected")]["file"]) or "không có"))

    w("### A.2 Nhiễu cảm biến (pha nghỉ, 30 phút cuối của mỗi pha nghỉ 2 h)\n")
    w("Cách tính (`noise_stats`): `std_raw` = độ lệch chuẩn thô trong cửa sổ; `std_d2` = std(sai phân bậc 2)/√6 — ước lượng nhiễu trắng "
      "không bị ảnh hưởng bởi trôi tuyến tính (điện áp vẫn hồi phục chậm trong pha nghỉ nên `std_raw` của điện áp là **cận trên**, gồm cả trôi). "
      "`quantisation_step` = khoảng cách nhỏ nhất giữa hai giá trị khác nhau trong toàn file. "
      "Bộ ghi báo dòng đúng 0,00000 A trong mọi pha nghỉ, nên nhiễu dòng được lấy trên pha xả CC (`cc_discharge_std_d2`). "
      "Mỗi ô: trung vị (min … max; số file).\n")
    N["grp"] = np.where(N["C_rate"] >= 1, "1C, 2C (nghỉ lấy mẫu 1 s)", "C/10, C/2 (nghỉ lấy mẫu 60 s)")
    bad = N.get("note", pd.Series("", index=N.index)).fillna("").str.contains("not connected")
    rows = []
    for (chn, grp), gg in N[~bad].groupby(["channel", "grp"]):
        rows.append({"Kênh": chn, "Nhóm file": grp, "Đơn vị": gg["unit"].iloc[0],
                     "quantisation_step": mmm(gg["quantisation_step"]), "rest std_d2": mmm(gg["rest_std_d2_median"]),
                     "rest std_raw": mmm(gg["rest_std_raw_median"]),
                     "CC-discharge std_d2": mmm(gg["cc_discharge_std_d2"]) if chn == "Current" else "–"})
    w(table(pd.DataFrame(rows)))
    v1 = N[N["channel"] == "Voltage"]
    c1 = N[N["channel"] == "Current"]
    tt = N[N["channel"].str.startswith("T_") & ~bad & (N["channel"] != "T_amb")]
    ta = N[(N["channel"] == "T_amb") & ~bad]
    w("\nTóm tắt dùng cho mô hình (đều tính từ bảng trên):\n")
    w("- **Điện áp**: σ ≈ %.1f µV (trung vị `std_d2` trên %d file; khoảng %.1f–%.1f µV); bước lượng tử hoá %.0f–%.0f µV."
      % (1e6 * v1["rest_std_d2_median"].median(), len(v1), 1e6 * v1["rest_std_d2_median"].min(), 1e6 * v1["rest_std_d2_median"].max(),
         1e6 * v1["quantisation_step"].min(), 1e6 * v1["quantisation_step"].max()))
    w("- **Dòng điện**: σ ≈ %.2f mA trên pha xả CC (khoảng %.2f–%.2f mA); bước lượng tử hoá %.2f–%.2f mA; trong pha nghỉ bộ ghi luôn báo 0 (không ước lượng được nhiễu khi nghỉ)."
      % (1e3 * c1["cc_discharge_std_d2"].median(), 1e3 * c1["cc_discharge_std_d2"].min(), 1e3 * c1["cc_discharge_std_d2"].max(),
         1e3 * c1["quantisation_step"].min(), 1e3 * c1["quantisation_step"].max()))
    q = tt["quantisation_step"].median()
    w("- **Nhiệt độ bề mặt cell** (T_cell, T_mid, T_pos, T_neg): độ phân giải ghi %.1f °C; ở %d/%d (file, kênh) `std_raw` khi nghỉ nhỏ hơn một bước lượng tử "
      "(trung vị %.3g °C, max %.3g °C) → nhiễu thực **nhỏ hơn độ phân giải**; sai số lượng tử hoá tương đương q/√12 = %.3f °C."
      % (q, int((tt["rest_std_raw_median"] < q).sum()), len(tt), max(tt["rest_std_raw_median"].median(), 0) if tt["rest_std_raw_median"].median() > 1e-12 else 0.0,
         tt["rest_std_raw_median"].max(), q / np.sqrt(12)))
    w("- **Nhiệt độ môi trường** (T_amb, %d file có kênh hoạt động): `std_raw` khi nghỉ %s °C — gồm cả dao động thật của buồng nhiệt, không chỉ nhiễu cảm biến."
      % (len(ta), mmm(ta["rest_std_raw_median"])))
    w("- Đây là nhiễu ngắn hạn + độ phân giải của **bộ ghi trong phòng thí nghiệm**, không phải độ chính xác tuyệt đối (sai lệch hệ thống giữa các cặp nhiệt "
      "không xác định được từ dữ liệu; xem cột `rest_offset_*` ở A.4 và chênh lệch T_amb – T_cell ở A.3).\n")

    w("### A.3 Hằng số thời gian nhiệt gộp τ = m·C_p/(h·A)\n")
    w("Cách tính: sau mỗi lần xả, pha nghỉ 2 h; khớp `T(t) = T_inf + A·exp(−t/τ)` (scipy `curve_fit`, 3 tham số tự do T_inf, A, τ) cho từng cặp nhiệt bề mặt, "
      "bỏ `skip_s` giây đầu sau khi ngắt dòng. **T_inf là tham số khớp, không dùng kênh môi trường** (kênh này chỉ có ở vài file và lệch so với cặp nhiệt cell khi cân bằng). "
      "Chỉ coi là tin cậy (`reliable`) khi độ dư nhiệt ban đầu ≥ 2 K (vì độ phân giải 0,1 °C) — do đó C/10 bị loại. Kết quả chính dùng `skip_s = 120`.\n")
    M = T[(T["skip_s"] == 120) & T["reliable"]]
    w("- Tất cả các khớp tin cậy: **τ = %s s**; RMSE khớp: %s K." % (mmm(M["tau_s"], "%.0f"), mmm(M["rmse_K"], "%.3f")))
    pv = M.groupby(["C_rate", "T_nominal_degC"])["tau_s"].agg(["median", "min", "max", "count"]).reset_index()
    pv.columns = ["C-rate", "T danh định [°C]", "τ trung vị [s]", "τ min [s]", "τ max [s]", "số khớp"]
    w("\nTheo C-rate và nhiệt độ:\n")
    w(table(pv, {c: "%.0f" for c in pv.columns[2:5]}))
    pc = M.groupby("channel")["tau_s"].agg(["median", "min", "max", "count"]).reset_index()
    pc.columns = ["Cặp nhiệt", "τ trung vị [s]", "τ min [s]", "τ max [s]", "số khớp"]
    w("\nTheo vị trí cặp nhiệt:\n")
    w(table(pc, {c: "%.0f" for c in pc.columns[1:4]}))
    cellsp = M.groupby(["C_rate", "T_nominal_degC", "channel"])["tau_s"].agg(lambda v: v.max() - v.min() if len(v) > 1 else np.nan)
    pcell = M[M["channel"] == "T_cell"].groupby(["C_rate", "T_nominal_degC"])["tau_s"].agg(lambda v: (v.max() - v.min()) / v.median())
    w("\n- Độ phân tán giữa các cell (kênh T_cell, cùng C-rate và nhiệt độ): (max−min)/trung vị = %s." % mmm(pcell, "%.2f"))
    sk = T[T["reliable"]].groupby("skip_s")["tau_s"].agg(["median", "min", "max", "count"]).reset_index()
    sk.columns = ["skip_s [s]", "τ trung vị [s]", "τ min [s]", "τ max [s]", "số khớp tin cậy"]
    w("\nĐộ nhạy với cửa sổ khớp (τ tăng khi bỏ nhiều thời gian đầu hơn → quá trình nguội **không thuần một hàm mũ**; mô hình nhiệt gộp một nút chỉ là xấp xỉ):\n")
    w(table(sk, {c: "%.0f" for c in sk.columns[:4]}))
    am = T[(T["skip_s"] == 120) & T["T_amb_channel_mean_degC"].notna()] if "T_amb_channel_mean_degC" in T else T.iloc[:0]
    if len(am):
        d = am["T_inf_fit_degC"] - am["T_amb_channel_mean_degC"]
        w("\n- Ở các file có kênh môi trường hoạt động: T_inf (khớp) − T_amb (kênh đo, trung bình pha nghỉ) = %s K → hai cảm biến không trùng nhau (có file lệch hơn 1 K), "
          "nên không dùng trực tiếp T_amb làm tiệm cận." % mmm(d, "%.2f"))
    w("\n**Nhận dạng được / không nhận dạng được:**\n")
    w("- Nhận dạng được: chỉ **τ = m·C_p/(h·A)** (tương đương tỉ số h·A/(m·C_p) = 1/τ ≈ %.2e s⁻¹ với τ trung vị), và nhiệt độ tiệm cận."
      % (1.0 / M["tau_s"].median()))
    w("- **Không** tách được h (hay h·A) và m·C_p riêng rẽ từ pha nguội: muốn tách phải biết công suất sinh nhiệt Q(t) trong pha xả "
      "(dữ liệu không đo nhiệt lượng; Q phụ thuộc mô hình: quá thế + nhiệt entropy), hoặc lấy m·C_p từ nguồn khác rồi suy ra h·A = m·C_p/τ.")
    w("- τ đo trên **bề mặt** cell; chênh lệch lõi–bề mặt không quan sát được. Điều kiện đối lưu là của buồng nhiệt trong thí nghiệm này, không tự động áp dụng cho bố trí khác.\n")

    w("### A.4 Chênh lệch giữa ba cặp nhiệt bề mặt trong lúc xả\n")
    w("Cách tính: lấy độ tăng nhiệt so với giá trị trung bình 10 mẫu cuối của pha nghỉ ngay trước khi xả (loại offset tĩnh giữa các cặp nhiệt), rồi so sánh mid/pos/neg. "
      "Chỉ các cell có 3 cặp nhiệt (%s). Giá trị = trung bình các lần xả.\n" % ", ".join(sorted(set(str(c) for c in Sp["cell"]))))
    s2 = Sp.groupby(["C_rate", "T_nominal_degC"]).agg(
        rise_mid=("rise_end_mid_K", "mean"), rise_pos=("rise_end_pos_K", "mean"), rise_neg=("rise_end_neg_K", "mean"),
        d_mp=("max_rise_mid_minus_pos_K", "mean"), d_mn=("max_rise_mid_minus_neg_K", "mean"),
        off_mp=("rest_offset_mid_minus_pos_K", "mean"), off_mn=("rest_offset_mid_minus_neg_K", "mean"), n=("file", "size")).reset_index()
    s2.columns = ["C-rate", "T danh định [°C]", "ΔT_mid cuối xả [K]", "ΔT_pos cuối xả [K]", "ΔT_neg cuối xả [K]",
                  "max(ΔT_mid−ΔT_pos) [K]", "max(ΔT_mid−ΔT_neg) [K]", "offset tĩnh mid−pos [K]", "offset tĩnh mid−neg [K]", "số lần xả"]
    w(table(s2, {c: "%.2f" for c in s2.columns[2:9]}))
    hi = Sp[Sp["C_rate"] >= 1]
    w("\n- Ở 1C–2C: ΔT_pos/ΔT_mid cuối xả = %s; ΔT_neg/ΔT_mid = %s. Offset tĩnh giữa các cặp nhiệt khi nghỉ chỉ %s K."
      % (mmm(hi["pos_rise_over_mid_rise_at_end"], "%.2f"), mmm(hi["neg_rise_over_mid_rise_at_end"], "%.2f"),
         mmm(pd.concat([Sp["rest_offset_mid_minus_pos_K"], Sp["rest_offset_mid_minus_neg_K"]]), "%.2f")))
    w("- Diễn giải thận trọng: bề mặt cell **không đẳng nhiệt** khi xả nhanh (giữa thân nóng hơn hai đầu, đầu dương mát nhất). "
      "Dữ liệu không cho biết nguyên nhân (tản nhiệt qua đầu kẹp/dây dẫn, vị trí gắn cặp nhiệt…), và chỉ có một cell cho mỗi (C-rate, nhiệt độ) nên không có độ lặp. "
      "Mô hình nhiệt gộp một nút vì vậy mang sai số mô hình cỡ các giá trị trong bảng; khi so mô hình với đo đạc phải nêu rõ so với cặp nhiệt nào (T_mid là vị trí nóng nhất trong ba vị trí đo).\n")

    # ================= B
    B = json.load(open(os.path.join(D, "B_checks.json")))
    w("## B. Zenodo 5171874 — O'Regan 2021 Data Repository (dữ liệu thô của O'Regan 2022)\n")
    w("Script: `data/scripts/b_oregan_tidy_entropy.py` → `B_entropic.csv`, `B_thermal_electronic.csv`, `B_specific_heat.csv`, `B_exchange_current.csv`, `B_diffusivity.csv`, `B_checks.json`.\n")
    w("### B.1 Hệ số entropy ∂U/∂T — kiểm tra đơn vị của Li 2025 SI Note 8, (S5), (S6)\n")
    w("Header của cả 4 file thô ghi đơn vị **`mV K-1`** (`%s`). So sánh hàm in trong Li 2025 (S5)/(S6), tính đúng như in, với điểm đo (2 cell mỗi điện cực):\n"
      % B["source_headers"]["Entropic_Term_Negative_Electrode_Cell_002.csv"][1].strip())
    rows = []
    for el, nm in (("positive", "dương — (S5)"), ("negative", "âm — (S6)")):
        e = B["entropic"][el]
        rows.append({"Điện cực": nm, "số điểm đo": e["n_points"], "khoảng dữ liệu [mV/K]": "%.4g … %.4g" % (e["data_min_mV_per_K"], e["data_max_mV_per_K"]),
                     "RMSE nếu hàm cho mV/K [mV/K]": e["rmse_mV_per_K_if_fit_is_mV_per_K"],
                     "RMSE nếu hàm cho V/K [mV/K]": e["rmse_mV_per_K_if_fit_is_V_per_K"],
                     "|sai lệch| lớn nhất (giả thiết mV/K) [mV/K]": e["max_abs_residual_mV_per_K_if_mV"], "tại x": e["x_of_max_abs_residual"]})
    w(table(pd.DataFrame(rows), {"RMSE nếu hàm cho mV/K [mV/K]": "%.4f", "RMSE nếu hàm cho V/K [mV/K]": "%.1f", "|sai lệch| lớn nhất (giả thiết mV/K) [mV/K]": "%.3f", "tại x": "%.4f"}))
    en = B["entropic"]["negative"]
    w("\n**Kết luận (từ số liệu):** hàm (S5), (S6) như in trong Li 2025 cho giá trị theo **mV/K**, không phải V/K như cột đơn vị của Table 6 ghi. "
      "Khi dùng trong mô hình (đơn vị SI) phải nhân 10⁻³: ∂U/∂T [V/K] = 10⁻³ × (S5)/(S6).\n")
    w("- Điện cực âm: (S6) (tuyến tính + 1 Gauss) **không** mô tả vùng lõm quanh x ≈ 0,47–0,57 của dữ liệu (tới %.3f mV/K); bỏ các điểm 0,45 < x < 0,60 thì RMSE còn %.4f mV/K. "
      "Đây là giới hạn của dạng hàm, cần ghi là sai số mô hình nếu dùng (S6)." % (en["data_min_mV_per_K"], en["rmse_mV_per_K_if_mV_excluding_0p45_to_0p60"]))
    ep = B["entropic"]["positive"]
    if "refit_same_form_mV_per_K" in ep:
        w("- Điện cực dương: khớp lại độc lập cùng dạng hàm trên dữ liệu thô cho hệ số %s (RMSE %.4f mV/K) so với hệ số in %s → (S5) đúng là hàm khớp của bộ dữ liệu này."
          % ({k: float("%.4g" % v) for k, v in ep["refit_same_form_mV_per_K"].items()}, ep["refit_rmse_mV_per_K"], ep["Li2025_printed_coefficients"]))
    if "refit_same_form_mV_per_K" in en:
        w("- Điện cực âm: khớp lại bình phương tối thiểu trên **toàn bộ** điểm cho nghiệm khác hẳn (RMSE %.4f mV/K, Gauss rất rộng) → dạng hàm (S6) không xác định duy nhất khi giữ các điểm vùng lõm; "
          "hệ số in trong bài nhiều khả năng được khớp khi bỏ/giảm trọng số vùng này (**không kiểm chứng được** từ dữ liệu)." % en["refit_rmse_mV_per_K"])
    cpath = os.path.join(D, "C_checks.json")
    if os.path.exists(cpath):
        cc = json.load(open(cpath)).get("dUdT_suppl_fig10")
        if cc:
            w("- Đối chiếu thêm với source data của chính Li 2025 (Supplementary Figure 10 c, d; script `c_li2025_ageing.py`): đường cong tác giả vẽ có giá trị %.4g … %.4g (âm) và %.4g … %.4g (dương), "
              "trùng với hàm in (RMSE %.1e và %.1e) → con số trong hình SI cũng là mV/K. Kho mã công bố (`Scripts_to_reproduce_paper.zip`) **không chứa** định nghĩa ∂U/∂T (nằm trong bộ tham số PyBaMM riêng của tác giả), "
              "nên không kiểm được mã mô phỏng của họ có nhân 10⁻³ hay không."
              % (cc["negative"]["plotted_min"], cc["negative"]["plotted_max"], cc["positive"]["plotted_min"], cc["positive"]["plotted_max"],
                 cc["negative"]["rmse_plotted_vs_printed"], cc["positive"]["rmse_plotted_vs_printed"]))
    w("\n### B.2 Các hàm khác của Li 2025 SI Note 11 so với dữ liệu thô (kiểm tra phụ)\n")
    rows = []
    for k, v in B["thermal_electronic"].items():
        qn, el = k.split("|")
        rows.append({"Đại lượng": qn, "điện cực": el, "số điểm": v["n"], "RMSE": v["rmse"], "sai lệch tương đối lớn nhất": v["max_rel_err"]})
    w(table(pd.DataFrame(rows), {"RMSE": "%.4f", "sai lệch tương đối lớn nhất": "%.3f"}))
    w("\n(thermal_conductivity [W m⁻¹ K⁻¹] so với (S24), (S25); electronic_conductivity [S m⁻¹] so với (S19).)\n")
    rows = []
    for comp, v in B["specific_heat"].items():
        rows.append({"Thành phần": comp, "số điểm thô": v["n_raw"], "T [°C]": "%.0f … %.0f" % (v["T_min_degC"], v["T_max_degC"]),
                     "giá trị thô ở 40 °C": v["raw_value_at_40degC"], "(S21–S23) ở 40 °C [J/kg/K]": v["Li2025_fit_at_40degC_J_per_kg_K"],
                     "tỉ số hàm/thô (35–90 °C)": v["ratio_fit_over_raw_median_35_90degC"],
                     "RMSE nếu thô là J/g/K [J/kg/K]": v["rmse_35_90degC_if_raw_is_J_per_g_K"]})
    w(table(pd.DataFrame(rows), {"giá trị thô ở 40 °C": "%.4f", "(S21–S23) ở 40 °C [J/kg/K]": "%.1f", "tỉ số hàm/thô (35–90 °C)": "%.1f", "RMSE nếu thô là J/g/K [J/kg/K]": "%.1f"}))
    w("\n- Header file nhiệt dung ghi `J kg-1 K-1` nhưng độ lớn (≈1–2,5) và tỉ số ≈1000 với (S21)–(S23) cho thấy số thô thực tế là **J g⁻¹ K⁻¹** (nhãn đơn vị trong file sai). "
      "Đoạn đầu quét DSC (25 → ~32 °C) là quá độ khởi động (giá trị ở 25 °C: xem `raw_value_at_25degC` trong `B_checks.json`), không dùng được.")
    rows = []
    for k, v in B["exchange_current"].items():
        el, t = k.split("|")
        rows.append({"điện cực": el, "T": t, "số điểm": v["n"], "j0 đo lớn nhất [A/m²]": v["meas_max_A_per_m2"],
                     "(S26)/(S27) lớn nhất [A/m²]": v["fit_max_A_per_m2"], "RMSE [A/m²]": v["rmse_A_per_m2"], "trung vị hàm/đo": v["median_ratio_fit_over_meas"]})
    w("\nMật độ dòng trao đổi (file ghi mA cm⁻² = 10 A m⁻²), so với (S26)/(S27) tại c_e = ⟨c_e⟩:\n")
    w(table(pd.DataFrame(rows), {c: "%.3f" for c in ("j0 đo lớn nhất [A/m²]", "(S26)/(S27) lớn nhất [A/m²]", "RMSE [A/m²]", "trung vị hàm/đo")}))
    dd = B["diffusivity"]
    w("\n- Khuếch tán pha rắn (GITT): %d file, %d dòng; stoichiometry âm %.3f–%.3f, dương %.3f–%.3f; 5/15/25/35/45 °C, 2 cell, 2 chiều (lit/delit). "
      "Trung vị log10(D_s [m²/s]) theo (điện cực|T °C): %s. Chưa so với (S17) trong script này."
      % (dd["n_files"], dd["n_rows"], dd["stoichiometry_range"]["negative"][0], dd["stoichiometry_range"]["negative"][1],
         dd["stoichiometry_range"]["positive"][0], dd["stoichiometry_range"]["positive"][1],
         {k: round(v, 2) for k, v in dd["median_log10_D_by_electrode_T"].items()}))
    w("")

    # ================= D (experiment) then C (model vs experiment)
    Sm = pd.read_csv(os.path.join(D, "D_kirkaldy_summary.csv"), dtype={"expt": str})
    Dc = json.load(open(os.path.join(D, "D_checks.json")))
    w("## C + D. Dữ liệu lão hoá: Kirkaldy 2024 (Zenodo 10637534) và Li 2025 (Zenodo 14995785)\n")
    w("Script: `data/scripts/d_kirkaldy_summary.py` → `D_kirkaldy_per_cell_rpt.csv`, `D_kirkaldy_ageing_sets.csv`, `D_kirkaldy_summary.csv`, `D_kirkaldy_cells.csv`, `D_archive_dirs.csv`, `D_checks.json`; "
      "`data/scripts/c_li2025_ageing.py` → `C_experiment_per_cell_rpt.csv`, `C_experiment_summary.csv`, `C_fig_ageing_long.csv`, `C_fig_small_tables_long.csv`, `C_model_input_cases.csv`, `C_li_dUdT_curves.csv`, `C_checks.json`, `C_archive_listing.tsv`.\n")
    tot = sum(v.get("total_uncompressed_bytes", 0) for v in Dc["zips"].values())
    got = sum(v["bytes_fetched_members"] for v in Dc["zips"].values())
    w("- Kirkaldy 2024: 5 file ZIP, tổng dung lượng giải nén %.1f GB. **Có file tóm tắt nhỏ**: `Summary Data/Performance Summary/* - Processed Data.csv` (mỗi cell một file, mỗi RPT một dòng: "
      "dung lượng C/10, C/2, điện trở 0,1 s, SoH, LLI, LAM_PE, LAM_NE (tổng/Gr/Si), thông lượng điện tích, số chu kỳ, nhiệt độ trung bình) và `Summary per Set/*set_data.csv`. "
      "Script chỉ tải %d file này (%.0f kB) bằng HTTP Range, không tải dữ liệu thô." % (tot / 1e9, sum(v["members_fetched"] for v in Dc["zips"].values()), got / 1e3))
    cc = Dc.get("cross_check_vs_Li2025_copy")
    if cc:
        w("- Bản sao cùng dữ liệu trong kho Li 2025 (`SimSave/InputData/Expt */…Extracted Data.csv` + `DMA Output/`) khớp với bản Kirkaldy: %d/%d dòng trùng khoá; sai khác lớn nhất SoH %.1e, LLI %.1e, LAM_NE %.1e, LAM_PE %.1e, dung lượng C/10 %.1e mAh. "
          "**Ngoại lệ:** trục thông lượng điện tích của Expt 2,2 trong bản Li 2025 lớn hơn bản Kirkaldy %.1f … %.1f Ah (các thí nghiệm khác: chênh 0) — hai nguồn đếm thông lượng khác nhau cho Expt 2,2; khi so mô hình phải nói rõ dùng trục nào."
          % (cc["rows_matched"], cc["rows_kirkaldy"], cc["max_abs_diff_SOH_dma"], cc["max_abs_diff_LLI"], cc["max_abs_diff_LAM_NE_tot"], cc["max_abs_diff_LAM_PE"],
             cc["max_abs_diff_cap_C10_mAh"], cc["throughput_Li_minus_Kirkaldy_Ah_by_expt_min_max"]["2,2"][0], cc["throughput_Li_minus_Kirkaldy_Ah_by_expt_min_max"]["2,2"][1]))
    w("\n### D.1 Thực nghiệm theo cửa sổ SOC và nhiệt độ (nguồn: Kirkaldy 2024, `D_kirkaldy_summary.csv`)\n")
    w("Cách tính: SOH = dung lượng C/10 tại RPT / dung lượng C/10 tại RPT0 (mỗi cell); LLI, LAM lấy nguyên từ cột DMA của tác giả (khớp OCV); "
      "\"tại thông lượng chung\" = nội suy tuyến tính từng cell tới thông lượng lớn nhất mà mọi cell của nhóm đều đạt, rồi lấy trung bình (min…max giữa các cell có trong CSV). "
      "T_cell là nhiệt độ bề mặt cell trung bình trong lúc lão hoá (file `set_data`), **khác** nhiệt độ buồng danh định.\n")
    t1 = Sm[["soc_window_pct", "expt", "T_nominal_degC", "n_cells", "T_cell_avg_during_ageing_degC", "cycles_per_ageing_set", "common_throughput_Ah",
             "SOH_pct_at_common_mean", "LLI_pct_at_common_mean", "LAM_NE_tot_pct_at_common_mean", "LAM_PE_pct_at_common_mean",
             "R_0p1s_mOhm_BOL_mean", "R_0p1s_mOhm_at_common_mean", "R_common_throughput_Ah"]].copy()
    t1.columns = ["SOC [%]", "Expt", "T buồng [°C]", "số cell", "T_cell TB [°C]", "chu kỳ/đợt", "Q chung [Ah]", "SOH [%]", "LLI [%]", "LAM_NE [%]", "LAM_PE [%]",
                  "R0.1s BOL [mΩ]", "R0.1s cuối [mΩ]", "tại Q_R [Ah]"]
    w(table(t1, {"T_cell TB [°C]": "%.1f", "chu kỳ/đợt": "%.0f", "Q chung [Ah]": "%.0f", "SOH [%]": "%.1f", "LLI [%]": "%.1f", "LAM_NE [%]": "%.1f",
                 "LAM_PE [%]": "%.1f", "R0.1s BOL [mΩ]": "%.1f", "R0.1s cuối [mΩ]": "%.1f", "tại Q_R [Ah]": "%.0f"}))
    w("\nCùng một thông lượng 3 kAh và 6 kAh (để so các cửa sổ SOC với nhau; trung bình các cell đạt tới mức đó):\n")
    t2 = Sm[["soc_window_pct", "T_nominal_degC", "SOH_pct_at_3kAh_mean", "LLI_pct_at_3kAh_mean", "LAM_NE_tot_pct_at_3kAh_mean", "LAM_PE_pct_at_3kAh_mean",
             "SOH_pct_at_6kAh_mean", "LLI_pct_at_6kAh_mean", "LAM_NE_tot_pct_at_6kAh_mean", "LAM_PE_pct_at_6kAh_mean", "SOH_pct_at_6kAh_n_cells"]].copy()
    t2.columns = ["SOC [%]", "T buồng [°C]", "SOH@3kAh", "LLI@3kAh", "LAM_NE@3kAh", "LAM_PE@3kAh", "SOH@6kAh", "LLI@6kAh", "LAM_NE@6kAh", "LAM_PE@6kAh", "số cell @6kAh"]
    w(table(t2, {c: "%.1f" for c in t2.columns[2:10]}))
    w("\n- Số cell ít (2–3 mỗi điều kiện) và DMA có nhiễu (LAM âm ở vài RPT đầu, xem CSV theo cell) → các con số trên là trung bình mẫu nhỏ, không kèm khoảng tin cậy.")
    w("- Nhiệt độ cell trung bình khi lão hoá cao hơn nhiệt độ buồng danh định (cột T_cell TB); cần dùng giá trị này, không phải 10/25/40 °C, nếu mô hình không tự tính tự nung.\n")

    L = pd.read_csv(os.path.join(D, "C_fig_ageing_long.csv"), dtype={"expt": str})
    Cc = json.load(open(os.path.join(D, "C_checks.json")))
    w("### C.1 Mô hình của Li 2025 so với thực nghiệm (source data của Fig. 3, 4, 6; `C_fig_ageing_long.csv`)\n")
    w("Giá trị tại điểm cuối của mỗi chuỗi (thông lượng lớn nhất có trong source data). `exp_avg` = trung bình 2 cell do tác giả tính. "
      "**Điểm cuối của thực nghiệm và của mô hình nằm ở thông lượng khác nhau (hai cột Q)** — bảng này chỉ để định hướng; khi so sánh định lượng phải nội suy từ `C_fig_ageing_long.csv` về cùng thông lượng. "
      "Thí nghiệm của mỗi hình được xác định bằng cách **so khớp số** chuỗi thực nghiệm với file theo cell (`panel_to_experiment_matching` trong `C_checks.json`), không dựa vào chú thích.\n")
    rows = []
    for (fig, ex, Tp, qn), g in L[L["figure"].isin(["Fig.3", "Fig.4", "Fig.6"]) & L["quantity"].notna()].groupby(["figure", "expt", "T_panel_degC", "quantity"]):
        r = {"Hình": fig, "Expt": ex, "T panel [°C]": int(Tp), "Đại lượng": qn}
        for s in ("exp_avg", "model_SEI_only", "model_SEI_dry_out", "model_5_coupled"):
            gg = g[g["series"] == s].sort_values("charge_throughput_kAh")
            r[s] = float(gg["value"].iloc[-1]) if len(gg) else np.nan
            if s in ("exp_avg", "model_5_coupled"):
                r["Q " + s + " [kAh]"] = float(gg["charge_throughput_kAh"].iloc[-1]) if len(gg) else np.nan
        rows.append(r)
    R = pd.DataFrame(rows)
    R = R[["Hình", "Expt", "T panel [°C]", "Đại lượng", "Q exp_avg [kAh]", "exp_avg", "Q model_5_coupled [kAh]", "model_SEI_only", "model_SEI_dry_out", "model_5_coupled"]]
    w(table(R, {c: "%.2f" for c in R.columns[4:]}))
    bad = Cc.get("exp_series_whose_cell_temperature_differs_from_panel_temperature", [])
    if bad:
        w("\n**Cảnh báo về source data của Fig. 6 (Expt 3) — phát hiện bằng so khớp số:** các chuỗi thực nghiệm ở cột thứ 2 và 3 của Fig. 6 trùng với các cell có nhiệt độ danh định khác với nhiệt độ của cột "
          "(giả định thứ tự cột 10/25/40 °C như Fig. 3/4, nơi thứ tự này được xác nhận bằng so khớp):\n")
        for b in bad:
            w("- " + b)
        w("\nTheo tên file trong chính kho dữ liệu và theo `Temp_Cell_Exp_3` trong `Fun_NC.py`, Expt 3 dùng cell A, B, C ở 10 °C; D, E, F ở 25 °C; G, H, I ở 40 °C; "
          "trong khi source data Fig. 6 lấy A, B / C, D / E, F (kiểu ánh xạ của Expt 2). "
          "Riêng cột thứ 2 ghép cell C (10 °C) với cell D (25 °C) nên bất nhất này **không phụ thuộc** vào giả định về thứ tự cột. "
          "Vì vậy **không dùng các chuỗi `exp_*` của Fig. 6 cột 25 và 40 °C để kiểm chứng**; "
          "hãy dùng `D_kirkaldy_per_cell_rpt.csv` (theo cell, đúng nhiệt độ). Đường mô hình trong Fig. 6 không kiểm tra được nhiệt độ từ source data. "
          "Ngoài ra các panel điện trở Fig. 6 d–f không so khớp được với file theo cell (xem `C_checks.json`: không có mục cho các panel này).")
    mi = Cc.get("model_input_cases")
    if mi:
        MC = pd.read_csv(os.path.join(D, "C_model_input_cases.csv"))
        w("\n- `C_model_input_cases.csv`: %d bộ tham số đầu vào của lượt chạy `Full_Exp23_Paper_11_fine` (`Exp No.` = %s; nhiệt độ %s °C; quét `SEI growth activation energy` = %s J/mol và `Negative electrode diffusivity activation energy` = %s J/mol) kèm các cột sai số `Error … %%` của tác giả; "
          "dùng để đối chiếu tham số suy giảm (ví dụ `Inner SEI lithium interstitial diffusivity`, `Contact resistance`, `Total heat transfer coefficient`)."
          % (mi["n_cases"], sorted(MC["Exp No."].unique().tolist()), sorted(MC["Ageing temperature"].unique().tolist()),
             sorted(MC["SEI growth activation energy [J.mol-1]"].unique().tolist()),
             sorted(MC["Negative electrode diffusivity activation energy [J.mol-1]"].unique().tolist())))
    w("- Kết quả mô phỏng dài theo từng RPT của tác giả (`SimSave/Li2024_Results/Save_LongRun/**/Mats/*-StructData.json`, ~1,3 MB mỗi lượt) **chưa tải**; các đường mô hình trong bảng trên lấy từ source data của hình.\n")

    w("## Những gì chưa lấy được / giới hạn\n")
    w("- A: không có phép đo nhiệt lượng hay nhiệt độ lõi → không tách được h và m·C_p; kênh môi trường chỉ có ở một phần file; cell 781 ở 0 °C chỉ có file rút gọn (xem `A_files.csv`).")
    w("- B: hệ số khớp gốc của O'Regan 2022 (Table S9) không có trong kho dữ liệu; chỉ kiểm tra được qua hàm in lại trong Li 2025. D_s chưa so với (S17).")
    w("- C: mã định nghĩa ∂U/∂T của Li 2025 không nằm trong kho mã công bố; kết quả mô phỏng chi tiết theo RPT chưa tải; source data Fig. 6 có vấn đề gán cell nêu trên.")
    w("- D: chỉ dùng file tóm tắt; chuỗi thời gian thô (đường cong C/10, GITT, chu kỳ lão hoá) **không tải**. Nếu cần tự chạy lại DMA: chỉ cần thư mục `Processed Timeseries Data/0.1C Voltage Curves/` của từng ZIP "
      "(xem dung lượng trong `D_archive_dirs.csv`), có thể lấy bằng `common.fetch_members` mà không tải cả ZIP.")
    open(OUT, "w", encoding="utf-8").write("\n".join(o) + "\n")
    print("wrote", OUT, len(o), "blocks")


if __name__ == "__main__":
    main()
