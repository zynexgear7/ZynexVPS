#!/bin/bash

set -euo pipefail
LOG_FILE="$HOME/zynexvps_setup.log"
exec > (tee -i "$LOG_FILE") 2>&1

echo "🚀 Starting fully optimized 24/7 ZynexVPS setup..."

# Remove old vm.sh if exists
if [ -f "$HOME/vm.sh" ]; then
    echo "🗑 Removing old vm.sh"
    rm -f "$HOME/vm.sh"
fi

# Install essentials
sudo apt-get update -y && sudo apt-get upgrade -y
ESSENTIALS=(git curl wget unzip sudo openssh-client qemu qemu-kvm cloud-utils cdrkit screen)
for pkg in "${ESSENTIALS[@]}"; do
    if ! dpkg -s $pkg &>/dev/null; then
        echo "🔧 Installing $pkg..."
        sudo apt-get install -y $pkg
    fi
done

# Install Node.js
if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install Firebase CLI
if ! command -v firebase &>/dev/null; then
    curl -sL https://firebase.tools | bash
fi

# Setup IDX workspace
IDX_DIR="$HOME/.idx"
DEV_FILE="$IDX_DIR/Dev.nix"
mkdir -p $IDX_DIR
cat > $DEV_FILE << EOL
{ pkgs, ... } : { channel = "stable-24.05"; packages = [pkgs.nodejs pkgs.firebase-tools pkgs.git pkgs.unzip]; env = {}; idx = {extensions = ["Dart-Code.flutter" "Dart-Code.dart-code"]; workspace = {onCreate = {}; onStart = {}}; previews = { enable = false;}}; commands = { deploy = "firebase deploy";};}
EOL

echo "🎉 vm.sh ready and IDX workspace created!"
