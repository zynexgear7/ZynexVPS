#!/bin/bash
set -euo pipefail

# =============================================
# ZYNEX ENGINE ALL-IN-ONE VPS INSTALLER
# Fully automated
# =============================================

# -----------------------------
# Colors
# -----------------------------
ORANGE="\e[38;5;208m"
CYAN="\e[36m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

clear

# -----------------------------
# ZYNEX Logo (display only once)
# -----------------------------
echo -e "${ORANGE}"
echo "  ______ __     __  _   _   ______  __   __  "
echo " |___  / \ \   / / | \ | | |  ____| \ \ / /  "
echo "    / /   \ \_/ /  |  \| | |__     \ V /   "
echo "   / /     \   /   | . \` | |  __|     > <    "
echo "  / /__     | |    | |\  | | |____   / . \   "
echo " /_____|    |_|    |_| \_| |______| /_/ \_\  "
echo "                                             "
echo -e "${CYAN}           ⚡ Z Y N E X ⚡${RESET}\n"

sleep 1

# -----------------------------
# Delete all old ZYNEX/VPS files
# -----------------------------
echo -e "${RED}🗑 Cleaning old files…${RESET}"

OLD_FILES=("$HOME/.vm" "$HOME/vm.sh" "$HOME/old-engine.sh" "$HOME/.zynexengine" "$HOME/engine.sh")
for f in "${OLD_FILES[@]}"; do
    if [ -f "$f" ] || [ -d "$f" ]; then
        rm -rf "$f"
        echo -e "${GREEN}✅ Removed: $f${RESET}"
    fi
done

echo -e "${CYAN}✅ Old files deleted successfully!\n${RESET}"

# -----------------------------
# Root check
# -----------------------------
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Please run as root (sudo)${RESET}"
    exit 1
fi

# -----------------------------
# Update system & install essentials
# -----------------------------
echo -e "${CYAN}🔄 Updating system…${RESET}"
apt-get update -y && apt-get upgrade -y

PACKAGES=(git curl wget unzip sudo openssh-client qemu qemu-kvm cloud-utils cdrkit screen nodejs npm)
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        echo -e "${CYAN}🔧 Installing $pkg…${RESET}"
        apt-get install -y "$pkg"
    else
        echo -e "${GREEN}✅ $pkg already installed${RESET}"
    fi
done

# -----------------------------
# Install Firebase CLI
# -----------------------------
if ! command -v firebase &>/dev/null; then
    echo -e "${CYAN}⚡ Installing Firebase CLI…${RESET}"
    curl -sL https://firebase.tools | bash
else
    echo -e "${GREEN}✅ Firebase CLI already installed${RESET}"
fi

# -----------------------------
# Setup engine directory
# -----------------------------
ENGINE_DIR="/opt/zynexengine"
mkdir -p "$ENGINE_DIR"
SCRIPT_FILE="$ENGINE_DIR/engine.sh"

# -----------------------------
# Engine script
# -----------------------------
cat > "$SCRIPT_FILE" <<'EOL'
#!/bin/bash
set -euo pipefail

# ZYNEX Engine VPS Script
# Runs silently, no logo repeat

while true; do
    echo "🔹 Zynex Engine running… $(date)"
    sleep 60
done
EOL

chmod +x "$SCRIPT_FILE"

# -----------------------------
# Setup systemd service
# -----------------------------
SERVICE_FILE="/etc/systemd/system/zynexengine.service"
cat > "$SERVICE_FILE" <<EOL
[Unit]
Description=Zynex Engine VPS Service (24/7)
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $SCRIPT_FILE
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable zynexengine.service
systemctl start zynexengine.service

# -----------------------------
# Completion
# -----------------------------
echo -e "\n${GREEN}🎉 Zynex Engine all-in-one installed successfully!${RESET}"
echo -e "${CYAN}🔧 Check service: systemctl status zynexengine.service${RESET}"
echo -e "${ORANGE}✨ Powered by Zynex Cloud / ZynexGear7${RESET}\n"
