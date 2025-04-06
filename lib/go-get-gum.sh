#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/common.sh" ] && source "$SCRIPT_DIR/common.sh" "$@" || echo "ℹ️ (No common.sh bling loaded)"

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

# ===========
# 🧠 Platform Detection
# ===========
IS_PI=false
ARCH=$(uname -m)
OS=$(uname -s)

if grep -qi raspberry /proc/cpuinfo 2>/dev/null || [[ "$ARCH" == "arm"* || "$ARCH" == "aarch64" ]]; then
  IS_PI=true
fi

GUM_VERSION="latest"
if $IS_PI; then
  GUM_VERSION="v0.12.0"
fi


# =============
# 📦 Go Install Fallback
# =============
if ! command -v go &>/dev/null; then
  warn "✨ Go (golang) is not installed."

  if $DRY_RUN; then
    info "🧪 DRY RUN: Would run: sudo apt install golang -y"
    exit 0
  fi

  if confirm_prompt "Install Go via apt now?"; then
    maybe_run sudo apt update
    maybe_run sudo apt install golang -y
  else
    warn "Cannot proceed without Go. Aborting."
    exit 1
  fi
fi

# =============
# 🎯 Install Path
# =============
GOBIN="$(go env GOBIN 2>/dev/null || true)"
[ -z "$GOBIN" ] && GOBIN="$(go env GOPATH)/bin"
INSTALL_TARGET="$GOBIN/gum"

# =============
# 🧼 Already Installed?
# =============
if command -v gum &>/dev/null || [ -f "$INSTALL_TARGET" ]; then
  success "✅ gum already installed at: $(command -v gum || echo "$INSTALL_TARGET")"
  exit 0
fi

# ===========
# 🚀 Install gum
# ===========
echo_info "Installing gum with Go (${GUM_VERSION})"

if $DRY_RUN; then
  echo_info "🧪 DRY RUN: Would run:"
  echo "    go install github.com/charmbracelet/gum@${GUM_VERSION}"
  echo "🧪 DRY RUN: gum would land in: $INSTALL_TARGET"
  exit 0
fi

maybe_run go install github.com/charmbracelet/gum@"$GUM_VERSION"

if [ -f "$INSTALL_TARGET" ]; then
  success "✅ gum installed to: $INSTALL_TARGET"

  if [[ ":$PATH:" != *":$GOBIN:"* ]]; then
    warn "gum may not be in your PATH."
    log_block "Add this to your shell profile:"
    log_block "  export PATH=\"\$PATH:$GOBIN\""
  fi
else
  warn "❌ gum install failed or binary not found at $INSTALL_TARGET"
  exit 1
fi

