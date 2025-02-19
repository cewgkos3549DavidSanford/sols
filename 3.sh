#!/usr/bin/env bash
set -euo pipefail

LOOPS="${LOOPS:-10}"           # 循环次数，可用环境变量覆盖
SLEEP_SECONDS="${SLEEP_SECONDS:-5}"

# 生成 [今天-365天, 今天-3天] 区间内的随机 UTC 时间（到秒）
gen_random_datetime() {
  python - <<'PY'
import random
from datetime import datetime, timedelta, timezone
now = datetime.now(timezone.utc)
start = now - timedelta(days=365)   # 去年同日附近
end   = now - timedelta(days=3)     # 到3天前
delta_seconds = int((end - start).total_seconds())
rand_seconds = random.randint(0, delta_seconds)
ts = start + timedelta(seconds=rand_seconds)
print(ts.strftime("%Y-%m-%dT%H:%M:%S"))
PY
}

current_branch() {
  git rev-parse --abbrev-ref HEAD
}

for ((i=0; i<LOOPS; i++)); do
  COMMIT_DATE="$(gen_random_datetime)"

  echo "Commit ${i} line" >> README.md
  git add README.md
  GIT_AUTHOR_DATE="${COMMIT_DATE}" GIT_COMMITTER_DATE="${COMMIT_DATE}" \
    git commit -m "Commit ${i}"

  if (( i < LOOPS - 1 )); then
    git push
    sleep "${SLEEP_SECONDS}"
  else
    # 最后一次：清空历史，仅保留本次提交
    BR="$(current_branch)"
    TMP_BRANCH="cleanup-tmp-$(date +%s)"
    FINAL_MSG="Final commit (history squashed)"

    git checkout --orphan "${TMP_BRANCH}"
    git add -A
    GIT_AUTHOR_DATE="${COMMIT_DATE}" GIT_COMMITTER_DATE="${COMMIT_DATE}" \
      git commit -m "${FINAL_MSG}"

    git branch -D "${BR}"
    git branch -m "${BR}"
    git push --force origin "${BR}"

    echo "History has been squashed. Only the final commit remains on ${BR}."
  fi
done
