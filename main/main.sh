#!/bin/bash
set -euo pipefail

# =============================
# ZYNEX Professional Multi-VM Manager
# =============================

# =============================
# Color Codes
# =============================
ORANGE="\e[38;5;208m"
CYAN="\e[36m"
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# Directory to store VM configs and images
VM_DIR="$HOME/ZynexVMs"
mkdir -p "$VM_DIR"

# =============================
# Header / Logo
# =============================
display_header() {
    clear
    echo -e "${ORANGE}"
    echo "========================================================================"
    echo "  ______ __     __  _   _   ______  __   __  "
    echo " |___  / \ \   / / | \ | | |  ____| \ \ / /  "
    echo "    / /   \ \_/ /  |  \| | |____     \ V /   "
    echo "   / /     \   /   | . \`| |  __|     > <  "
    echo "  / /__     | |    | |\  | | |____   / . \ "
    echo " /_____|    |_|    |_| \_| |______| /_/ \_\ "
    echo "                                             "
    echo "                     POWERED BY ZYNEX"
    echo "========================================================================"
    echo -e "${RESET}"
}

# =============================
# Colored Status Messages with Emojis
# =============================
print_status() {
    local type=$1
    local message=$2

    case $type in
        "INFO") echo -e "${CYAN}ℹ️ [INFO]${RESET} $message" ;;
        "WARN") echo -e "${YELLOW}⚠️ [WARN]${RESET} $message" ;;
        "ERROR") echo -e "${RED}❌ [ERROR]${RESET} $message" ;;
        "SUCCESS") echo -e "${GREEN}✅ [SUCCESS]${RESET} $message" ;;
        "INPUT") echo -e "${ORANGE}💡 [INPUT]${RESET} $message" ;;
        *) echo "[$type] $message" ;;
    esac
}

# =============================
# Cleanup Old Files
# =============================
cleanup_old_files() {
    OLD_FILES=("$HOME/.vm" "$HOME/vm.sh")
    for f in "${OLD_FILES[@]}"; do
        if [ -f "$f" ]; then
            print_status "WARN" "🗑 Removing old file: $f"
            rm -f "$f"
        fi
    done
}

# =============================
# Install Dependencies
# =============================
install_dependencies() {
    print_status "INFO" "⚡ Updating system & installing essential packages..."
    sudo apt-get update -y && sudo apt-get upgrade -y
    ESSENTIALS=(git curl wget unzip sudo openssh-client qemu qemu-kvm cloud-utils cdrkit screen)
    for pkg in "${ESSENTIALS[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            print_status "INFO" "🔧 Installing $pkg..."
            sudo apt-get install -y "$pkg"
        else
            print_status "SUCCESS" "✅ $pkg already installed"
        fi
    done
}

# =============================
# Install Node.js v18 LTS
# =============================
install_node() {
    if ! command -v node &>/dev/null; then
        print_status "INFO" "⚡ Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        print_status "SUCCESS" "✅ Node.js already installed"
    fi
}

# =============================
# Install Firebase CLI
# =============================
install_firebase() {
    if ! command -v firebase &>/dev/null; then
        print_status "INFO" "⚡ Installing Firebase CLI..."
        curl -sL https://firebase.tools | bash
    else
        print_status "SUCCESS" "✅ Firebase CLI already installed"
    fi
}

# =============================
# Setup 24/7 systemd service
# =============================
setup_service() {
    SERVICE_FILE="/etc/systemd/system/zynexvps.service"
    print_status "INFO" "⚡ Setting up 24/7 systemd service..."
    
    sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=ZYNEX VPS 24/7 Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $HOME/vm.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable zynexvps.service
    sudo systemctl start zynexvps.service
    print_status "SUCCESS" "🎉 24/7 ZYNEX service is running"
}

# =============================
# VM Management Functions
# =============================
create_vm() {
    print_status "INFO" "💻 Creating new VM..."
    read -p "$(print_status INPUT "Enter VM name: ")" VM_NAME
    read -p "$(print_status INPUT "Disk size (e.g., 20G): ")" DISK_SIZE
    read -p "$(print_status INPUT "Memory in MB (e.g., 2048): ")" MEMORY
    read -p "$(print_status INPUT "CPU count (e.g., 2): ")" CPUS
    read -p "$(print_status INPUT "SSH Port (e.g., 2222): ")" SSH_PORT

    IMG_FILE="$VM_DIR/$VM_NAME.img"
    print_status "INFO" "🖥 Creating QCOW2 disk image: $IMG_FILE ($DISK_SIZE)"
    qemu-img create -f qcow2 "$IMG_FILE" "$DISK_SIZE"

    CONFIG_FILE="$VM_DIR/$VM_NAME.conf"
    cat > "$CONFIG_FILE" <<EOF
VM_NAME="$VM_NAME"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
IMG_FILE="$IMG_FILE"
EOF

    print_status "SUCCESS" "🎉 VM $VM_NAME has been created and configuration saved!"
}

list_vms() {
    print_status "INFO" "📋 Listing all VMs..."
    if compgen -G "$VM_DIR/*.conf" > /dev/null; then
        ls "$VM_DIR" | grep "\.conf$" | sed 's/\.conf$//' | while read vm; do
            echo -e "${CYAN}- $vm${RESET}"
        done
    else
        print_status "WARN" "⚠️ No VMs found!"
    fi
}

delete_vm() {
    read -p "$(print_status INPUT "Enter VM name to delete: ")" VM_NAME
    CONFIG_FILE="$VM_DIR/$VM_NAME.conf"
    IMG_FILE="$VM_DIR/$VM_NAME.img"
    if [[ -f "$CONFIG_FILE" ]]; then
        rm -f "$CONFIG_FILE" "$IMG_FILE"
        print_status "SUCCESS" "🗑 VM $VM_NAME deleted!"
    else
        print_status "ERROR" "❌ VM $VM_NAME not found!"
    fi
}

# =============================
# Main Menu
# =============================
main_menu() {
    display_header
    while true; do
        echo -e "${CYAN}======== ZYNEX VPS MENU ========${RESET}"
        echo -e "${YELLOW}1)${RESET} 💻 Create VM"
        echo -e "${YELLOW}2)${RESET} 📋 List VMs"
        echo -e "${YELLOW}3)${RESET} 🗑 Delete VM"
        echo -e "${YELLOW}4)${RESET} 🚪 Exit"
        echo -e "${CYAN}===============================${RESET}"
        read -p "$(print_status INPUT "Enter your choice: ")" choice
        case $choice in
            1) create_vm ;;
            2) list_vms ;;
            3) delete_vm ;;
            4) exit 0 ;;
            *) print_status "ERROR" "❌ Invalid choice!" ;;
        esac
    done
}

# =============================
# Execution Starts Here
# =============================
cleanup_old_files
install_dependencies
install_node
install_firebase
setup_service
main_menu
