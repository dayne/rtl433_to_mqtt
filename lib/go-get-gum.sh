#!/bin/bash
set -e

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

confirm_prompt() {
  local msg="$1"
  echo -ne "\033[1;36m$msg [y/N]: \033[0m"
  read -r answer
  case "$answer" in
    [Yy]*) return 0 ;;
    *) echo "❌ Cancelled."; return 1 ;;
  esac
}

GOBIN="$(go env GOBIN 2>/dev/null || true)"
[ -z "$GOBIN" ] && GOBIN="$(go env GOPATH 2>/dev/null)/bin"
INSTALL_TARGET="$GOBIN/gum"

# 1. Ensure Go is available
if ! command -v go &>/dev/null; then
  echo "⚠️  Go (golang) is not installed."

  if $DRY_RUN; then
    echo "🧪 DRY RUN: Would run: sudo apt install golang -y"
    exit 0
  fi

  if confirm_prompt "Install Go via apt now?"; then
    sudo apt update
    sudo apt install golang -y
  else
    echo "❌ Cannot proceed without Go. Aborting."
    exit 1
  fi
fi

# 2. Check if gum already installed
if command -v gum &>/dev/null || [ -f "$INSTALL_TARGET" ]; then
  echo "✅ gum is already installed at: $(command -v gum || echo "$INSTALL_TARGET")"
  exit 0
fi

# 3. Install gum
if $DRY_RUN; then
  echo "🧪 DRY RUN: Would run: go install github.com/charmbracelet/gum@latest"
  echo "🧪 DRY RUN: gum would be placed in $INSTALL_TARGET"
  exit 0
fi

echo "📦 Installing gum with Go..."
go install github.com/charmbracelet/gum@latest

# 4. PATH check
if [ -f "$INSTALL_TARGET" ]; then
  echo "✅ gum installed to: $INSTALL_TARGET"

  if [[ ":$PATH:" != *":$GOBIN:"* ]]; then
    echo
    echo "⚠️  gum may not be in your PATH."
    echo "👉 Add this to your ~/.bashrc or ~/.zshrc:"
    echo "   export PATH=\"\$PATH:$GOBIN\""
  fi
else
  echo "❌ gum installation failed or not found in $INSTALL_TARGET"
  exit 1
fi
