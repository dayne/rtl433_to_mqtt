#!/bin/bash

# ===========
# 🎭 FLAGS & MODES
# ===========

DRAMATIC=true
DRY_RUN=false

parse_flags() {
  for arg in "$@"; do
    case "$arg" in
      --no-drama|--boring) DRAMATIC=false ;;
      --dramatic) DRAMATIC=true ;;
      --dry-run) DRY_RUN=true ;;
    esac
  done
}

parse_flags "$@"

# ===========
# ⏸️ DRAMATIC PAUSE
# ===========

pause() {
  $DRAMATIC && sleep "${1:-0.5}"
}

# ===========
# 🗃️ STATE FILES
# ===========

set_state() {
  mkdir -p .state
  touch ".state/$1"
}

clear_state() {
  rm -f ".state/$1"
}

is_enabled() {
  [[ -f ".state/$1" ]]
}

# ===========
# 💬 LOGGING
# ===========

log() {
  echo -e "💬 ${1}"
}

success() {
  echo -e "\033[1;32m✅ $1\033[0m"
}

warn() {
  echo -e "\033[5;33m⚠️  $1\033[0m"
}

log_block() {
  echo -e "   $1"
}

log_kv() {
  printf "   \033[1;36m%-15s:\033[0m %s\n" "$1" "$2"
}

info() {
  echo -e "\033[1;36mℹ️  $* \033[0m"
}

# ===========
# 🌀 SPINNERS
# ===========

spin() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while ps a | awk '{print $1}' | grep -q "$pid" 2>/dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "     \b\b\b\b\b\b"
}

spinner_wrap() {
  local msg="$1"
  shift
  $@ &
  local pid=$!
  echo -n "$msg..."
  spin $pid
  wait $pid
  success " done."
}

dramatic_check() {
  local label="$1"
  local service="$2"
  if $DRAMATIC; then
    spinner_wrap "🔍 Checking $label" systemctl is-active --quiet "$service"
    if systemctl is-active --quiet "$service"; then
      success "$label is running"
    else
      warn "$label is not running"
    fi
  else
    check_service_status "$label" "$service"
  fi
}

check_service_status() {
  local label="$1"
  local service="$2"
  if systemctl is-active --quiet "$service"; then
    success "$label is running"
  else
    warn "$label is not running"
  fi
}

# ===========
# ✨ DISPLAY HELPERS
# ===========

divider() {
  printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' "${1:--}"
}

header() {
  divider
  printf "\033[1;36m%*s\n\033[0m" $(((${#1} + $(tput cols)) / 2)) "$1"
  divider
}

type_header() {
  local text="$1"
  local delay="${2:-0.05}"
  echo -ne "\033[1;36m"
  for ((i = 0; i < ${#text}; i++)); do
    echo -n "${text:$i:1}"
    sleep "$delay"
  done
  echo -e "\033[0m"
}

transition_to() {
  clear
  type_header "$1"
  divider
}

ptleop_banner() {
  echo -e "\033[1;35m"
  echo "██████╗ ████████╗██╗     ███████╗ ██████╗ ██████╗ "
  echo "██╔══██╗╚══██╔══╝██║     ██╔════╝██╔═══██╗██╔══██╗"
  echo "██████╔╝   ██║   ██║     █████╗  ██║   ██║██████╔╝"
  echo "██╔═══╝    ██║   ██║     ██╔══╝  ██║   ██║██╔═══╝ "
  echo "██║        ██║   ███████╗███████╗╚██████╔╝██║     "
  echo "╚═╝        ╚═╝   ╚══════╝╚══════╝ ╚═════╝ ╚═╝     "
  echo -e "\033[0m"
  pause 1
}

banner() {
  local delay="${1:-0.15}"  # speed of reveal

  echo -ne "\033[1;36m"
  sleep $delay; echo "        ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~"
  sleep $delay; echo "              📡  SENSOR NODE 433 MHz"
  sleep $delay; echo -n "                "
  for _ in {1..6}; do echo -n ") "; sleep 0.08; done; echo ") 📶"
  sleep $delay; echo "                    ~ ~ ~ ~ ~ ~ ~ ~"
  sleep $delay; echo "                        🔌 SDR USB"
  sleep $delay; echo "                          │"
  sleep $delay; echo "                      ┌───▼───┐         🍓"
  sleep $delay; echo -n "                      │ RASPI │"
  sleep 0.2
  echo -n "───📤───"
  for blip in "→" "→" "→"; do echo -n "$blip"; sleep 0.1; done
  echo " MQTT → ☁️"
  sleep $delay; echo "                      └───────┘"
  sleep $delay; echo "        ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~"
  echo -ne "\033[0m"

  sleep $delay
  echo -e "\033[1;35m        ✨ A R R T E L L   S Y S T E M ✨\033[0m"
  pause 1
}


# ===========
# ✅ EXECUTION + CONFIRMATION
# ===========

confirm_prompt() {
  local msg="${1:-Are you sure?}"
  if [ "$DRY_RUN" = true ]; then
    info "🧪 DRY RUN: Skipping prompt: $msg"
    return 0
  fi

  echo -ne "\033[1;36m$msg [y/N]: \033[0m"
  read -r answer
  case "$answer" in
    [Yy]*) return 0 ;;
    *) warn "Cancelled."; return 1 ;;
  esac
}

maybe_run() {
  if [ "$DRY_RUN" = true ]; then
    info "🧪 DRY RUN: $*"
  else
    "$@"
  fi
}

# ===========
# 🎞️ CREDITS ROLL
# ===========

credits_roll() {
  echo -e "\033[1;35m🎬 Starring:\033[0m"
  pause 1
  echo "  🎙️  rtl_433 as The Radio Whisperer"
  pause 1
  echo "  🛰️  MQTT as The Messenger"
  pause 1
  echo "  💎 Ruby as The Script Wizard"
  pause 1
  echo "  💥 Bash as The Stagehand"
  pause 1
  echo -e "\n\033[1;35mProduced by:\033[0m D.Ay Studios™"
  pause 2
  echo -e "\n\033[1;32m🎉 Thanks for tuning in!\033[0m"
  pause 2
}
