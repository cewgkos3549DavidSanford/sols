#!/usr/bin/env bash
set -euo pipefail

START_DATE="2025-03-07T19:11:01"
LOOPS=10
SLEEP_SECONDS=5

for ((i=0; i<LOOPS; i++)); do
  # 计算递增日期（优先使用 GNU date）
  if command -v date >/dev/null 2>&1 && date -d "1970-01-01" >/dev/null 2>&1; then
    COMMIT_DATE="$(date -u -d "${START_DATE} +${i} day" +"%Y-%m-%dT%H:%M:%S")"
  else
    # 兼容无 GNU date 的环境（如部分 macOS），使用 Python 计算
    COMMIT_DATE="$(python - <<'PY'
from datetime import datetime, timedelta, timezone
start = datetime.fromisoformat("2025-02-07T19:11:011").replace(tzinfo=timezone.utc)
i = int(__import__("os").environ.get("I_LOOP", "0"))
print((start + timedelta(days=i)).strftime("%Y-%m-%dT%H:%M:%S"))
PY
)"
  fi

  echo "Commit 1 line" >> README.md
  git add README.md

  GIT_AUTHOR_DATE="${COMMIT_DATE}" GIT_COMMITTER_DATE="${COMMIT_DATE}" git commit -m "Commit 1"
  git push

  if (( i < LOOPS - 1 )); then
    sleep "${SLEEP_SECONDS}"
  fi
done
