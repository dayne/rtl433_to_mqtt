#!/bin/bash
set -e

# Load shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh" "$@"

# Track flags
DO_IT=false
for arg in "$@"; do
  case "$arg" in
    --doit) DO_IT=true ;;
  esac
done

# ===========
# 📄 Config & Defaults
# ===========
CONFIG_FILE="config.yml"
DEFAULT_CONFIG="rtl_433:
  host: localhost
  port: 1883
  topic: /rtl_433/raw
"

# ===========
# 🧠 --doit MODE
# ===========
handle_doit_mode() {
  info "Running in non-interactive mode (--doit)"

  if [ -f "$CONFIG_FILE" ]; then
    info "Config file already exists at $CONFIG_FILE — skipping"
  else
    info "Creating default config at $CONFIG_FILE"
    if [ "$DRY_RUN" = true ]; then
      info "🧪 DRY RUN: Would write:"
      echo "$DEFAULT_CONFIG"
    else
      echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
      success "✅ Default config written"
    fi
  fi
}

# ===========
# 🎬 Run Main Setup (Interactive or --doit)
# ===========
main() {
  if ! $DO_IT; then
    banner
    header "🎰 rtl433_to_mqtt Setup Wizard"
  fi

  # ----------
  # Dependencies
  # ----------
  $DO_IT || header "🔧 Checking system dependencies..."
  REQUIRED_CMDS=("rtl_433" "mosquitto_pub" "ruby")

  for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      warn "Missing: $cmd"
      if $DO_IT || confirm_prompt "Install $cmd?"; then
        case "$cmd" in
          rtl_433) maybe_run sudo apt install rtl-433 -y ;;
          mosquitto_pub) maybe_run sudo apt install mosquitto-clients -y ;;
          ruby) maybe_run sudo apt install ruby-full -y ;;
        esac
      fi
    else
      #$DO_IT || success "$cmd found"
      success "$cmd found"
    fi
  done

  if ! command -v bundle &>/dev/null; then
    info "Installing bundler gem (user-local)"
    maybe_run gem install --user-install bundler
  fi
  
  # Get the version Ruby uses for gem directory paths
  RUBY_ABI_VERSION=$(ruby -e 'require "rbconfig"; puts RbConfig::CONFIG["ruby_version"]' 2>/dev/null)

  if [ -z "$RUBY_ABI_VERSION" ]; then
    echo "❌ Ruby not found or RbConfig broken."
    exit 1
  fi

  # Construct the correct path
  LOCAL_GEM_BIN="$HOME/.local/share/gem/ruby/$RUBY_ABI_VERSION/bin"
  export PATH="$LOCAL_GEM_BIN:$PATH"

  if [ -f Gemfile ]; then
    info "Installing Ruby gems locally to vendor/bundle..."
    maybe_run bundle config set path 'vendor/bundle'
    maybe_run bundle install
  else
    warn "No Gemfile found. Skipping bundler setup."
  fi

  # ===========
  # 💎 Ruby Gems via Bundler
  # ===========

  if [ -f Gemfile ]; then
    header "💎 Checking Ruby gems with Bundler"

    # Make sure PATH includes local gem bin dir
    if [ -f ruby.sh ]; then
      RUBY_PATH="$(./ruby.sh --print)"
      export PATH="$RUBY_PATH:$PATH"
    fi

    # Check if gems are already installed
    if bundle check --path vendor/bundle &>/dev/null; then
      success "✅ Required gems are already installed"
    else
      warn "⚠️  Gems not yet installed"

      if $DO_IT || confirm_prompt "Install gems locally to vendor/bundle?"; then
        maybe_run bundle config set path 'vendor/bundle'
        maybe_run bundle install
      else
        warn "Gems not installed. This may cause the app to fail later."
      fi
    fi
  else
    warn "No Gemfile found. Skipping Bundler setup."
  fi


  # ----------
  # Config Setup
  # ----------
  if $DO_IT; then
    handle_doit_mode
  elif [ -f "$CONFIG_FILE" ]; then
    warn "⚠️ config.yml already exists — skipping config setup"
  elif command -v gum &>/dev/null; then
    header "🧙 Interactive Config via gum"

    MQTT_HOST=$(gum input --placeholder "Enter MQTT Host (default: localhost)")
    MQTT_PORT=$(gum input --placeholder "Enter MQTT Port (default: 1883)")
    MQTT_TOPIC=$(gum input --placeholder "Enter MQTT Topic (default: sensors/rtl433)")

    CONFIG_YML_CONTENT="mqtt:
  host: ${MQTT_HOST:-localhost}
  port: ${MQTT_PORT:-1883}
  topic: ${MQTT_TOPIC:-sensors/rtl433}
"

    if confirm_prompt "Write new config.yml?"; then
      if [ "$DRY_RUN" = true ]; then
        info "🧪 DRY RUN: Would write config.yml with:"
        echo "$CONFIG_YML_CONTENT"
      else
        echo "$CONFIG_YML_CONTENT" > "$CONFIG_FILE"
        success "✅ config.yml written"
      fi
    else
      warn "Skipped writing config.yml"
    fi
  else
    warn "gum not found — skipping interactive config"
    log_block "To install gum: https://github.com/charmbracelet/gum"
  fi

  # ----------
  # rtl_433 Test (optional)
  # ----------
  if ! $DO_IT && confirm_prompt "Run rtl_433 test scan now? (Ctrl+C to skip)"; then
    maybe_run rtl_433 -G | head -n 10
  fi

  if ! $DO_IT; then
    header "🎉 Setup Complete"
    credits_roll
  fi
}

main
