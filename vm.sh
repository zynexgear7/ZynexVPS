#!/bin/bash

# ====================
# ZynexVPS - Fully Optimized Firebase Studio VPS Setup
#==================

set -euo pipefail # Stop on error, unset var, or pipe failure

LOG_FILE="$HOME/zynexvps_setup.log"
exec > (tee -i "$LOG_FILE") 2>&1

echo "🚀 Starting ZynexVPS Firebase Studio VPS Setup..."

# Helper Functions
install_pkg() {
    if ! dpkg -s "$1" &>/dev/null; then
        echo "🔧 Installing package: $1"
        sudo apt-get install -y $1
    else
        echo "✅ Package $1 already installed"
    fi
}

install_node() {
    if ! command -v node &>/dev/null; then
        echo "⚡ Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        echo "✅ Node.js already installed"
    fi
}

install_firebase() {
    if ! command -v firebase &>/dev/null; then
        echo "⚡ Installing Firebase CLI..."
        curl -sL https://firebase.tools | bash
    else
        echo "✅ Firebase CLI already installed"
    fi
}

echo "🔄 Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

ESSENTIAL_PACKAGES=(git curl wget unzip sudo openssh-client qemu qemu-kvm cloud-utils cdrkit)
echo "🔧 Installing essential packages..."
for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
    install_pkg "$pkg"
done

install_node
install_firebase

IDX_DIR="$HOME/.idx"
DEV_FILE="$IDX_DIR/Dev.nix"
echo "🛀 Setting up IDX workspace at $DEV_FILE..."
mkdir -p "$IDX_DIR"
cat > "$DEV_FILE" << EOL
{ pkgs, ... } : {
  channel = "stable-24.05";
  packages = [
    pkgs.nodejs
    pkgs.firebase-tools
    pkgs.git
    pkgs.unzip
  ];
  env = {};
  idx = {
    extensions = ["Dart-Code.flutter" "Dart-Code.dart-code"];
    workspace = { onCreate = {}; onStart = {} };
    previews = { enable = false; };
  };
  commands = { deploy = "firebase deploy"; };
}
EOL

echo "🎉 ZynexVPS setup complete!"
echo "📄 Log file saved at: $LOG_FILE"
echo "💻 Run 'firebase login' to authenticate"
echo "🚀 Use 'firebase deploy' to deploy your projects"
echo "📂 IDX workspace ready at $DEV_FILE"
