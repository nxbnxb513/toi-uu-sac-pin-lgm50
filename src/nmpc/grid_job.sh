#!/usr/bin/env bash
# Mot job cua luoi day du (grid.yml, GD-98): mot vung x mot C_base x mot nhiet do x mot phuong phap,
# cac muc k chay SONG SONG (NSLOT tien trinh MATLAB rieng, moi tien trinh mot truong hop).
#   grid_job.sh prep   -> so buoc IRK cua tung k (prep.json), bien dich giao dien MEX acados chung
#   grid_job.sh build  -> tao cac bo giai con thieu (song song), danh dau <SROOT>/<ma>/ok
#   grid_job.sh run    -> chay cac truong hop, toi da NSLOT cung luc, toi DEADLINE (giay POSIX)
# Bien moi truong: VAR W C T KS (vd "1 2 3") RES RESUME SROOT MEXDIR DEADLINE NSLOT MIN_START
#                  MARGIN STEPS_KS (JSON hoac rong) CKPT_AFTER (Inf hoac so lan giai)
set -uo pipefail
SRC="$GITHUB_WORKSPACE/src"
ADDP="addpath('$SRC/dfn'); addpath('$SRC/nmpc'); addpath('$SRC/ekf');"
STEPS="${STEPS_KS:-}"; [ -z "$STEPS" ] && STEPS="[]"
KSM="[$(echo $KS | tr ' ' ',')]"
mkdir -p "$RES" "$SROOT" "$MEXDIR" "$RUNNER_TEMP/wk"

ml() {  # ml <thu muc lam viec> <thu muc bo giai (LD_LIBRARY_PATH) hoac -> <log> <lenh MATLAB>
  local wd="$1" sd="$2" log="$3" cmd="$4" ldp="$LD_LIBRARY_PATH"
  mkdir -p "$wd"
  if [ "$sd" != "-" ]; then mkdir -p "$sd"; ldp="$sd:$LD_LIBRARY_PATH"; fi
  ( cd "$wd" && LD_LIBRARY_PATH="$ldp" LD_RUN_PATH="${sd#-}" matlab -singleCompThread -batch "$cmd" ) > "$log" 2>&1
}

case "$1" in
prep)
  ml "$RUNNER_TEMP/wk/prep" - "$RES/prep_log.txt" \
    "$ADDP try, ocp_compile_interface('$MEXDIR'); catch e, disp(e.message); end; pilot_run($W, $C, $KSM, '$RES', 'D', '$VAR', $T, 330, struct('phase', 'prep', 'prep_out', '$RUNNER_TEMP/prep.json', 'steps_ks', $STEPS));"
  st=$?; cat "$RES/prep_log.txt"; [ $st -eq 0 ] || exit $st
  python3 - "$RUNNER_TEMP/prep.json" <<'PY' >> "$GITHUB_OUTPUT"
import json, sys
p = json.load(open(sys.argv[1]))
if isinstance(p, dict): p = [p]
codes = []
for r in p:
    if r['code'] not in codes: codes.append(r['code'])
for i in range(7):
    print(f'c{i+1}=' + (codes[i] if i < len(codes) else ''))
PY
  ;;
build)
  python3 - "$RUNNER_TEMP/prep.json" > "$RUNNER_TEMP/tobuild.txt" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
if isinstance(p, dict): p = [p]
seen = set()
for r in p:
    if r['code'] in seen: continue
    seen.add(r['code']); print(r['code'], '[' + ','.join(str(int(x)) for x in r['ns']) + ']')
PY
  n=0
  while read -r code ns; do
    if [ -f "$SROOT/$code/ok" ]; then echo "bo giai $code: co san (cache)"; continue; fi
    echo "bo giai $code: tao moi"
    ml "$SROOT/$code" "$SROOT/$code/c_generated_code" "$RES/build_$code.txt" \
      "$ADDP grid_build('$VAR', $ns, '$SROOT', '$MEXDIR');" &
    n=$((n+1)); if [ $n -ge "$NSLOT" ]; then wait -n; n=$((n-1)); fi
  done < "$RUNNER_TEMP/tobuild.txt"
  wait
  for f in "$RES"/build_*.txt; do [ -f "$f" ] && { echo "== $f"; tail -5 "$f"; }; done
  i=0
  while read -r code ns; do i=$((i+1)); [ -f "$SROOT/$code/ok" ] && echo "ok$i=1" >> "$GITHUB_OUTPUT"; done < "$RUNNER_TEMP/tobuild.txt"
  ;;
run)
  declare -A CODE
  while read -r k code; do CODE[$k]=$code; done < <(python3 -c "
import json; p = json.load(open('$RUNNER_TEMP/prep.json')); p = [p] if isinstance(p, dict) else p
[print(r['k'], r['code']) for r in p]")
  n=0
  for k in $KS; do
    left=$(( DEADLINE - $(date +%s) ))
    if [ $left -lt "$MIN_START" ]; then echo "k so $k: con $left s < $MIN_START s, bo qua (run sau chay lai)"; continue; fi
    code="${CODE[$k]}"
    echo "$(date -u +%T) bat dau k so $k (bo giai $code, con $left s)"
    ml "$RUNNER_TEMP/wk/k$k" "$SROOT/$code/c_generated_code" "$RES/log_k$k.txt" \
      "$ADDP pilot_run($W, $C, $k, '$RES', 'D', '$VAR', $T, 330, struct('wall', 'greedy', 'margin_s', $MARGIN, 'min_start_s', 0, 'deadline', $DEADLINE, 'ckpt', true, 'resume_dir', '$RESUME', 'ckpt_after', $CKPT_AFTER, 'solver_root', '$SROOT', 'mex_dir', '$MEXDIR', 'steps_ks', $STEPS));" &
    n=$((n+1)); if [ $n -ge "$NSLOT" ]; then wait -n; n=$((n-1)); fi
  done
  wait
  for f in "$RES"/log_k*.txt; do echo "===== $f"; grep -E "PILOT|CCCV|SOC dich|So buoc|acados|NMPC:|DIEM LUU|CHAY TIEP|DA LUU|LOI|loi|rror|XONG|reuse" "$f" | cut -c1-400; done
  ;;
esac
