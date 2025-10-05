#!/bin/bash
set -euo pipefail

# =============================================
# ZYNEX ENGINE VPS INSTALLER (Premium)
# Version: 1.3 (New Logo)
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
# ZYNEX Logo (New ASCII)
# -----------------------------
echo -e "${ORANGE}"
echo "  ______ __     __  _   _   ______  __   __  "
echo " |___  / \ \   / / | \ | | |  ____| \ \ / /  "
echo "    / /   \ \_/ /  |  \| | | |__     \ V /   "
echo "   / /     \   /   | . \` | |  __|    > <    "
echo "  / /__     | |    | |\  | | |____   / . \   "
echo " /_____|    |_|    |_| \_| |______| /_/ \_\  "
echo "                                             "
echo -e "${CYAN}           ⚡ Z Y N E X ⚡${RESET}\n"

sleep 1

# --- root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Please run as root (sudo)${RESET}"
    exit 1
fi

# --- Update & install dependencies ---
echo -e "${CYAN}🔄 Updating system…${RESET}"
apt-get update -y && apt-get upgrade -y

PACKAGES=(git wget unzip qemu qemu-kvm cloud-utils cdrkit screen curl nodejs npm)
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        echo -e "${CYAN}🔧 Installing $pkg…${RESET}"
        apt-get install -y "$pkg"
    else
        echo -e "${GREEN}✅ $pkg already installed${RESET}"
    fi
done

# --- Install Firebase CLI ---
if ! command -v firebase &>/dev/null; then
    echo -e "${CYAN}⚡ Installing Firebase CLI…${RESET}"
    curl -sL https://firebase.tools | bash
else
    echo -e "${GREEN}✅ Firebase CLI already installed${RESET}"
fi

# --- Setup engine script ---
SCRIPT_DIR="/opt/zynexengine"
mkdir -p "$SCRIPT_DIR"
echo -e "${CYAN}📥 Downloading core engine script…${RESET}"
curl -fsSL "https://raw.githubusercontent.com/zynexgear7/ZynexVPS/main/engine.sh" -o "$SCRIPT_DIR/engine.sh"
chmod +x "$SCRIPT_DIR/engine.sh"

# --- Setup systemd service ---
SERVICE_FILE="/etc/systemd/system/zynexengine.service"
echo -e "${CYAN}⚙️ Creating systemd service…${RESET}"
cat > "$SERVICE_FILE" <<EOL
[Unit]
Description=Zynex Engine VPS Service (24/7)
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $SCRIPT_DIR/engine.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable zynexengine.service
systemctl start zynexengine.service

# --- Completion Message ---
echo -e "\n${GREEN}🎉 Zynex Engine installed successfully!${RESET}"
echo -e "${CYAN}🔧 Check service: systemctl status zynexengine.service${RESET}"
echo -e "${ORANGE}✨ Powered by Zynex Cloud / ZynexGear7${RESET}\n"
