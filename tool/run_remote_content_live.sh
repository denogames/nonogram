#!/usr/bin/env bash
# Runs test/content/remote_content_live_test.dart against a throwaway local
# studio-core-backend (STUDIO_CONTENT_ENABLED=true, temporary PostgreSQL, local only).
# Usage: tool/run_remote_content_live.sh /path/to/studio-core-backend
set -euo pipefail
GAME_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$(cd "${1:?usage: $0 /path/to/studio-core-backend}" && pwd)"
if [[ -z "${TEST_DATABASE_URL:-}" ]]; then
  cd "$BACKEND_DIR"
  exec bash scripts/with-test-postgres.sh bash "$GAME_DIR/tool/run_remote_content_live.sh" "$BACKEND_DIR"
fi
rand() { node -e "process.stdout.write(require('crypto').randomBytes(32).toString('hex'))"; }
PORT="$(node -e "const s=require('net').createServer();s.listen(0,'127.0.0.1',()=>{process.stdout.write(String(s.address().port));s.close()})")"
export NODE_ENV=test LOG_LEVEL=warn DB_MODE=postgres REDIS_MODE=memory HOST=127.0.0.1 PORT
export DATABASE_URL="$TEST_DATABASE_URL" JWT_SECRET="$(rand)" HMAC_SHARED_SECRET="$(rand)" ADMIN_API_KEY="$(rand)"
export STUDIO_CONTENT_ENABLED=true
cd "$BACKEND_DIR"
node --import tsx src/server.ts >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT
for _ in $(seq 1 100); do curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null && break; sleep 0.3; done
echo "backend up on 127.0.0.1:${PORT} ($(git rev-parse --short HEAD))"
cd "$GAME_DIR"
NONOGRAM_LIVE_BACKEND_URL="http://127.0.0.1:${PORT}" NONOGRAM_LIVE_HMAC_KEY="$HMAC_SHARED_SECRET" NONOGRAM_LIVE_ADMIN_KEY="$ADMIN_API_KEY" \
  flutter test test/content/remote_content_live_test.dart
