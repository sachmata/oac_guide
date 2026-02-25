#!/usr/bin/env bash
# Slidev runner for OAC Guide presentation
# No local install needed — uses pnpm dlx
#
# Usage:
#   ./slidev.sh dev      # Dev server with live reload + presenter mode
#   ./slidev.sh build    # Build static SPA to dist/
#   ./slidev.sh export   # Export to PDF
#   ./slidev.sh          # Default: dev

set -euo pipefail
cd "$(dirname "$0")"

PACKAGES="--package @slidev/cli --package @slidev/theme-seriph"
CMD="${1:-dev}"

case "$CMD" in
  dev)
    pnpm dlx $PACKAGES slidev --open
    ;;
  build)
    pnpm dlx $PACKAGES slidev build --base /oac-guide/
    echo "Built to dist/ — serve with any static file server"
    ;;
  export)
    pnpm dlx $PACKAGES slidev export --output oac-guide.pdf
    echo "Exported to oac-guide.pdf"
    ;;
  *)
    echo "Usage: ./slidev.sh [dev|build|export]"
    exit 1
    ;;
esac
