#!/usr/bin/env bash
set -euo pipefail

LOOPS="${LOOPS:-10}"           # 循环次数，可用环境变量覆盖
SLEEP_SECONDS="${SLEEP_SECONDS:-5}"

# 生成 [now-30d, now] 的随机 UTC 时间，ISO8601 到秒
gen_random_datetime() {
  python - <<'PY'
import os, random
from datetime import datetime, timedelta, timezone
now = datetime.now(timezone.utc)
start = now - timedelta(days=30)
# 随机秒
delta_seconds = int((now - start).total_seconds())
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

  # 非最后一次正常推送
  if (( i < LOOPS - 1 )); then
    git push
    sleep "${SLEEP_SECONDS}"
  else
    # 最后一次：清空历史，仅保留本次提交
    BR="$(current_branch)"
    TMP_BRANCH="cleanup-tmp-$(date +%s)"

    # 记录最后一次提交信息（保持相同日期）
    FINAL_MSG="Final commit (history squashed)"

    # 创建无历史分支并提交当前工作区
    git checkout --orphan "${TMP_BRANCH}"
    git add -A
    GIT_AUTHOR_DATE="${COMMIT_DATE}" GIT_COMMITTER_DATE="${COMMIT_DATE}" \
      git commit -m "${FINAL_MSG}"

    # 用新分支替换原分支历史并强推
    git branch -D "${BR}"
    git branch -m "${BR}"
    git push --force origin "${BR}"

    echo "History has been squashed. Only the final commit remains on ${BR}."
  fi
done
