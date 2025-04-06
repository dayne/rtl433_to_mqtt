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
DEFAULT_CONFIG="mqtt:
  host: localhost
  port: 1883
  topic: sensors/rtl433
"

# ===========
# 🧠 --doit MODE
# ===========
handle_doit_mode() {
  echo_info "Running in non-interactive mode (--doit)"

  if [ -f "$CONFIG_FILE" ]; then
    echo_info "Config file already exists at $CONFIG_FILE — skipping"
  else
    echo_info "Creating default config at $CONFIG_FILE"
    if [ "$DRY_RUN" = true ]; then
      echo_info "🧪 DRY RUN: Would write:"
      echo "$DEFAULT_CONFIG"
    else
      echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
      echo_success "✅ Default config written"
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
    echo_info "Installing bundler gem (user-local)"
    maybe_run gem install --user-install bundler
    export PATH="$HOME/.local/share/gem/ruby/$(ruby -e 'print RUBY_VERSION[/\d+\.\d+/]')/bin:$PATH"
  fi

  if [ -f Gemfile ]; then
    echo_info "Installing Ruby gems locally to vendor/bundle..."
    maybe_run bundle config set path 'vendor/bundle'
    maybe_run bundle install
  else
    warn "No Gemfile found. Skipping bundler setup."
  fi

  # ----------
  # Ruby Gem Check
  # ----------
  $DO_IT || header "💎 Checking Ruby gem: mqtt"
  if ! gem list -i mqtt >/dev/null; then
    warn "Ruby gem 'mqtt' not found"
    if $DO_IT || confirm_prompt "Install Ruby gem 'mqtt'?"; then
      maybe_run gem install mqtt
    fi
  else
    success "mqtt gem already installed"
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
        echo_info "🧪 DRY RUN: Would write config.yml with:"
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
