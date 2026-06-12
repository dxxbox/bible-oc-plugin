#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
PLUGIN_ROOT="$(cd "$(dirname "$0")" && pwd)"
RESTART=false
BASE_URL=""
WATCH=false

usage() {
  cat <<EOF
Usage: $0 [--base-url <url>] [--restart] [--watch] [--help]

Deploy bible-oc-plugin to a local OpenClaw installation.

Options:
  --base-url <url>  BiBLE Atlas HTTP base URL (required for setup)
  --restart         Restart OpenClaw after deploy
  --watch           Tail OpenClaw logs after deploy
  --help            Show this help

Environment:
  OPENCLAW_HOME     OpenClaw home directory (default: ~/.openclaw)
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-url) BASE_URL="$2"; shift 2 ;;
    --restart) RESTART=true; shift ;;
    --watch) WATCH=true; shift ;;
    --help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

echo "==> Step 1/4: Install dependencies"
cd "$PLUGIN_ROOT"
npm ci

echo "==> Step 2/4: Build"
npm run build

echo "==> Step 3/4: Register plugin"
node scripts/install-local.mjs --openclaw-config "$OPENCLAW_HOME/openclaw.json" --write

if [[ -n "$BASE_URL" ]]; then
  echo "==> Step 4/4: Setup plugin"
  openclaw bible setup --base-url "$BASE_URL" --write
  echo "==> Status:"
  openclaw bible status
else
  echo "==> Step 4/4: Skipped (no --base-url, run 'openclaw bible setup' manually)"
fi

if $RESTART; then
  echo "==> Restarting OpenClaw..."
  openclaw server restart || echo "  (restart skipped — openclaw CLI not available or server not running)"
fi

if $WATCH; then
  echo "==> Watching logs..."
  tail -f "$OPENCLAW_HOME/logs/openclaw.log" 2>/dev/null || echo "  (no log file found at $OPENCLAW_HOME/logs/openclaw.log)"
fi

echo "==> Done"
