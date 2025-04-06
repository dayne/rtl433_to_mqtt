#!/bin/bash
set -e

# Optional: Use common.sh for logging if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/lib/common.sh" ] && source "$SCRIPT_DIR/lib/common.sh" "$@"

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

# Check for go
if ! command -v go &>/dev/null; then
  echo "❌ 'go' is not installed. Please install Go (https://go.dev/doc/install)."
  exit 1
fi

# Determine install path
GOBIN="${GOBIN:-$(go env GOPATH)/bin}"
INSTALL_TARGET="$GOBIN/gum"

if command -v gum &>/dev/null; then
  success "✅ gum already installed at $(command -v gum)"
  exit 0
fi

if [ "$DRY_RUN" = true ]; then
  info "🧪 DRY RUN: Would run 'go install github.com/charmbracelet/gum@latest'"
  info "🧪 DRY RUN: gum would be placed in $INSTALL_TARGET"
  exit 0
fi

info "📦 Installing gum via go install"
go install github.com/charmbracelet/gum@latest

if [ -f "$INSTALL_TARGET" ]; then
  success "✅ gum installed to $INSTALL_TARGET"
  info "👉 Make sure \$GOBIN is in your PATH (currently: $GOBIN)"
else
  error "❌ gum installation failed or binary not found at $INSTALL_TARGET"
  exit 1
fi
