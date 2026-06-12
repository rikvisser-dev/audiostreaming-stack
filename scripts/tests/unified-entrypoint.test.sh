#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENTRYPOINT="$ROOT_DIR/scripts/unified-entrypoint.sh"

status_panel_block="$(awk '
    /\[\[ "\$STATUS_PANEL_ENABLED" == "1" \]\]/ {
        in_status_panel_gate = 1
    }

    in_status_panel_gate {
        print
    }

    in_status_panel_gate && /^fi$/ {
        exit
    }
' "$ENTRYPOINT")"

assert_contains() {
    local needle="$1"
    local message="$2"

    if [[ "$status_panel_block" != *"$needle"* ]]; then
        echo "$message" >&2
        exit 1
    fi
}

assert_contains \
    "start_service status-api gunicorn" \
    "missing gated status-api gunicorn startup"
assert_contains \
    "--chdir /opt/sonicverse/status-api" \
    "status-api gunicorn startup should use --chdir"
assert_contains \
    "--bind 127.0.0.1:8080" \
    "status-api gunicorn startup should bind to 127.0.0.1:8080"
assert_contains \
    "--workers 2" \
    "status-api gunicorn startup should configure two workers"
assert_contains \
    "--timeout 30" \
    "status-api gunicorn startup should configure a 30-second timeout"
assert_contains \
    "server:app" \
    "status-api gunicorn startup should load server:app"
assert_contains \
    "wait_for_url status-api \"http://127.0.0.1:8080/api/auth-config\"" \
    "missing gated status-api readiness check"
