#!/usr/bin/env sh
#
# OpenVPN GUI — automated installer
#
# Downloads and installs the latest OpenVPN GUI .deb package on
# Debian-based Linux distributions, along with all required
# runtime dependencies.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/berlinify/openvpn-gui/main/install.sh | sh
#
# Or:
#   wget -qO- https://raw.githubusercontent.com/berlinify/openvpn-gui/main/install.sh | sh
#

set -eu

RELEASE_URL="https://github.com/berlinify/openvpn-gui/releases/download/Stable/openvpn-gui_0.2.0_amd64.deb"
TEMP_FILE=""

cleanup() {
  if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE"
  fi
}
trap cleanup EXIT INT TERM

# --- Helpers ----------------------------------------------------------------

echo_info()   { printf "\033[36m[INFO]\033[0m %s\n" "$*"; }
echo_ok()     { printf "\033[32m[ OK ]\033[0m %s\n" "$*"; }
echo_warn()   { printf "\033[33m[WARN]\033[0m %s\n" "$*"; }
echo_error()  { printf "\033[31m[FAIL]\033[0m %s\n" "$*" >&2; }

# --- Checks -----------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
  echo_error "This script must be run as root (use sudo)."
  echo_info  "Example: curl -fsSL https://raw.githubusercontent.com/berlinify/openvpn-gui/main/install.sh | sudo sh"
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo_error "apt-get not found. This installer only supports Debian-based distributions."
  exit 1
fi

# --- Dependency Installation ------------------------------------------------

echo_info "Updating package lists..."
apt-get update -qq

echo_info "Installing runtime dependencies..."

# Core dependencies
DEPS="python3 iputils-ping policykit-1 openvpn"

# Try to install openvpn3 from the default repository (may not be available
# on all distributions; the app gracefully falls back to openvpn if missing).
if apt-get install -y openvpn3 >/dev/null 2>&1; then
  echo_ok "openvpn3 installed"
else
  echo_warn "openvpn3 package not found in repositories."
  echo_warn "See https://community.openvpn.net/openvpn/wiki/OpenVPN3Linux for manual installation."
  echo_info "OpenVPN 2 (openvpn) will be used as fallback."
fi

# Install remaining dependencies
apt-get install -y $DEPS

echo_ok "Dependencies installed"

# --- Download .deb ----------------------------------------------------------

echo_info "Downloading OpenVPN GUI package..."
TEMP_FILE="$(mktemp /tmp/openvpn-gui.XXXXXX.deb)"

if command -v wget >/dev/null 2>&1; then
  wget -qO "$TEMP_FILE" "$RELEASE_URL"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL -o "$TEMP_FILE" "$RELEASE_URL"
else
  echo_error "Neither wget nor curl is available. Install one of them and try again."
  exit 1
fi

if [ ! -s "$TEMP_FILE" ]; then
  echo_error "Download failed or file is empty."
  exit 1
fi

echo_ok "Package downloaded ($(du -h "$TEMP_FILE" | cut -f1))"

# --- Install .deb -----------------------------------------------------------

echo_info "Installing OpenVPN GUI..."
dpkg -i "$TEMP_FILE" || true
apt-get install -f -y  # resolve any missing dependencies
dpkg -i "$TEMP_FILE"

echo_ok "OpenVPN GUI installed successfully!"

# --- Done -------------------------------------------------------------------

echo ""
echo "──────────────────────────────────────────────────"
echo "  OpenVPN GUI 0.2.0 is ready to use!"
echo ""
echo "  Launch it from your application menu or run:"
echo "    openvpn-gui"
echo ""
echo "  Then import a .ovpn profile to get started."
echo "──────────────────────────────────────────────────"
