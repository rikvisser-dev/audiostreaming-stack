#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENTRYPOINT="$ROOT_DIR/scripts/unified-entrypoint.sh"

if ! awk '
    /\[\[ "\$STATUS_PANEL_ENABLED" == "1" \]\]/ {
        in_status_panel_gate = 1
        next
    }

    in_status_panel_gate && /^fi$/ {
        in_status_panel_gate = 0
    }

    in_status_panel_gate && /start_service status-api bash -c/ {
        starts_status_api = 1
    }

    in_status_panel_gate && /gunicorn --bind 127\.0\.0\.1:8080 --workers 2 --timeout 30 server:app/ {
        binds_status_api = 1
    }

    END {
        exit starts_status_api && binds_status_api ? 0 : 1
    }
' "$ENTRYPOINT"; then
    echo "missing gated status-api gunicorn startup on 127.0.0.1:8080" >&2
    exit 1
fi
