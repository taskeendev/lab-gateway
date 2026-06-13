#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo "ไม่พบ .env — cp .env.example .env ก่อน" >&2; exit 1; }
set -a; source .env; set +a          # export ทุกค่า (รวมพอร์ตที่ compose ต้องใช้)
python3 render-config.py
# --env-file /dev/null: กัน compose แกะ .env (มี inline array ที่ parser มันไม่ชอบ)
exec docker compose --env-file /dev/null up "$@"
