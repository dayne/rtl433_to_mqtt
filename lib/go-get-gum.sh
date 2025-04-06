#!/bin/bash
set -e

# Optional: Source common.sh if you want fancy logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/common.sh" ] && source "$SCRIPT_DIR/common.sh" "$@"

# Flags
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="gum"
GUM_BIN="$INSTALL_DIR/$BINARY_NAME"
REPO="https://github.com/charmbracelet/gum"
RELEASE_URL="https://github.com/charmbracelet/gum/releases/latest/download"

# Detect system
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

# Normalize ARCH names
case "$ARCH" in
  x86_64) ARCH="x86_64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)
    error "❌ Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

FILENAME="gum_${OS}_${ARCH}.tar.gz"
DOWNLOAD_URL="${RELEASE_URL}/${FILENAME}"

# Install function
install_gum() {
  info "📦 Downloading gum for $OS/$ARCH"
  TMPDIR=$(mktemp -d)
  cd "$TMPDIR"

  curl -sSL "$DOWNLOAD_URL" -o gum.tar.gz
  tar -xzf gum.tar.gz

  if [ -f "$BINARY_NAME" ]; then
    info "📁 Installing gum to $INSTALL_DIR"
    sudo mv "$BINARY_NAME" "$INSTALL_DIR/"
    sudo chmod +x "$GUM_BIN"
    success "✅ gum installed to $GUM_BIN"
  else
    error "Extracted archive didn't contain 'gum'"
    exit 1
  fi

  cd /
  rm -rf "$TMPDIR"
}

# Main
if command -v gum &>/dev/null; then
  success "✅ gum is already installed at $(command -v gum)"
  exit 0
fi

info "gum not found. Installing latest release from $REPO"

if [ "$DRY_RUN" = true ]; then
  info "🧪 DRY RUN: Would fetch $DOWNLOAD_URL and install to $INSTALL_DIR"
  exit 0
else
  install_gum
fi
