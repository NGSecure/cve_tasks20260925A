#!/usr/bin/env bash
# 批量自检驱动 —— 在有 docker + 公网 的机器上跑,按置信度从高到低对每个折叠 bundle 跑 build.sh。
# bundle 在两个仓里:A -> $REPO_A_DIR/<cve>,B -> $REPO_B_DIR/<cve>。
# 用法:
#   export REPO_A_DIR=/path/to/cve_tasks20260925A        # 含各 <cve>/ 的目录(仓内子目录)
#   export REPO_B_DIR=/path/to/cve_tasks20260925B
#   bash build-all.sh                 # 跑全部 142 个(converted+partial),conf 高的先跑
#   bash build-all.sh 0.8             # 只跑 confidence>=0.8 的(T1,29 个)
#   bash build-all.sh 0.6 0.8         # 跑 [0.6,0.8) 的(T2)
# 结果写到 build-all.log,并在末尾打印 PASS/FAIL 汇总。失败不中断,继续下一个。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORDER="$HERE/build-order.tsv"
LOG="$HERE/build-all.log"
: > "$LOG"
MIN="${1:-0}"; MAX="${2:-1.01}"
: "${REPO_A_DIR:?set REPO_A_DIR to the dir containing A's <cve>/ bundles}"
: "${REPO_B_DIR:?set REPO_B_DIR to the dir containing B's <cve>/ bundles}"

pass=0; fail=0; miss=0; declare -a FAILED
while IFS=$'\t' read -r repo cve conf status; do
  [ "$repo" = "repo" ] && continue
  awk "BEGIN{exit !($conf>=$MIN && $conf<$MAX)}" || continue
  case "$repo" in A) root="$REPO_A_DIR";; B) root="$REPO_B_DIR";; *) continue;; esac
  dir="$root/$cve"
  if [ ! -f "$dir/build.sh" ]; then
    echo "MISS  $repo/$cve  (no build.sh at $dir)" | tee -a "$LOG"; miss=$((miss+1)); continue
  fi
  echo "===== BUILD $repo/$cve (conf=$conf $status) =====" | tee -a "$LOG"
  if ( cd "$dir" && bash build.sh ) >>"$LOG" 2>&1; then
    echo "PASS  $repo/$cve" | tee -a "$LOG"; pass=$((pass+1))
  else
    echo "FAIL  $repo/$cve  (see build-all.log)" | tee -a "$LOG"; fail=$((fail+1)); FAILED+=("$repo/$cve")
  fi
done < "$ORDER"

echo | tee -a "$LOG"
echo "================ SUMMARY ================" | tee -a "$LOG"
echo "PASS=$pass  FAIL=$fail  MISS=$miss  (range conf ∈ [$MIN,$MAX))" | tee -a "$LOG"
if [ "$fail" -gt 0 ]; then
  echo "failed bundles:" | tee -a "$LOG"
  printf '  %s\n' "${FAILED[@]}" | tee -a "$LOG"
fi
echo "full log: $LOG"
