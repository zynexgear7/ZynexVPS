#!/bin/bash
set -euo pipefail

# ───────────────────────────────
#   🚀 ZYNEX VPS MANAGER 24/7
# ───────────────────────────────

# -------------------------
# Colors & symbols
# -------------------------
cyan="\033[1;36m"
yellow="\033[1;33m"
green="\033[1;32m"
red="\033[1;31m"
magenta="\033[1;35m"
reset="\033[0m"

# -------------------------
# Display ZYNEX Logo
# -------------------------
clear
echo -e "${cyan}"
echo "  ______ __     __  _   _   ______  __   __  "
echo " |___  / \\ \\   / / | \\ | | |  ____| \\ \\ / /  "
echo "    / /   \\ \\_/ /  |  \\| | | |__     \\ V /   "
echo "   / /     \\   /   | . \` | |  __|     > <    "
echo "  / /__     | |    | |\\  | | |____   / . \\   "
echo " /_____|    |_|    |_| \\_| |______| /_/ \\_\\  "
echo
echo "      ⚡🔥  ${yellow}Z Y N E X   V P S   M A N A G E R${cyan}  🔥⚡"
echo "                Powered by ${green}ZYNEX CODE${reset}"
echo

# -------------------------
# Update & install dependencies
# -------------------------
echo -e "${yellow}🔄 Updating system packages...${reset}"
apt-get update -y && apt-get upgrade -y

echo -e "${yellow}📦 Installing required tools...${reset}"
apt-get install -y sudo curl wget unzip git qemu-kvm cloud-utils net-tools screen openssh-client

# -------------------------
# Directory setup
# -------------------------
VM_DIR="$HOME/ZynexVPS"
mkdir -p "$VM_DIR"

# -------------------------
# Utility Functions
# -------------------------
print_status() {
    local type="$1"
    local msg="$2"
    case $type in
        "INFO") echo -e "${cyan}[INFO]${reset} $msg" ;;
        "WARN") echo -e "${yellow}[WARN]${reset} $msg" ;;
        "SUCCESS") echo -e "${green}[SUCCESS]${reset} $msg" ;;
        "ERROR") echo -e "${red}[ERROR]${reset} $msg" ;;
        "INPUT") echo -e "${magenta}[INPUT]${reset} $msg" ;;
        *) echo "[$type] $msg" ;;
    esac
}

validate_input() {
    local type="$1"
    local val="$2"
    case $type in
        number) [[ "$val" =~ ^[0-9]+$ ]] ;;
        size) [[ "$val" =~ ^[0-9]+[GgMm]$ ]] ;;
        port) [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge 23 ] && [ "$val" -le 65535 ] ;;
        name) [[ "$val" =~ ^[a-zA-Z0-9_-]+$ ]] ;;
        username) [[ "$val" =~ ^[a-z_][a-z0-9_-]*$ ]] ;;
        *) return 1 ;;
    esac
}

# -------------------------
# VM Functions
# -------------------------
list_vms() {
    find "$VM_DIR" -maxdepth 1 -name "*.conf" -exec basename {} .conf \; 2>/dev/null
}

load_vm_config() {
    local vm="$1"
    local cfg="$VM_DIR/$vm.conf"
    if [[ -f "$cfg" ]]; then
        source "$cfg"
        return 0
    else
        print_status "ERROR" "VM config $vm not found"
        return 1
    fi
}

save_vm_config() {
    local cfg="$VM_DIR/$VM_NAME.conf"
    cat > "$cfg" <<EOF
VM_NAME="$VM_NAME"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
GUI_MODE="$GUI_MODE"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$CREATED"
EOF
    print_status "SUCCESS" "Saved config for $VM_NAME"
}

setup_vm_image() {
    print_status "INFO" "Preparing VM image..."
    mkdir -p "$VM_DIR"
    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"

    # Create minimal cloud-init
    cat > user-data <<EOF
#cloud-config
hostname: $HOSTNAME
ssh_pwauth: true
disable_root: false
users:
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    password: $(openssl passwd -6 "$PASSWORD")
chpasswd:
  list: |
    root:$PASSWORD
    $USERNAME:$PASSWORD
  expire: false
EOF

    cat > meta-data <<EOF
instance-id: iid-$VM_NAME
local-hostname: $HOSTNAME
EOF

    cloud-localds "$SEED_FILE" user-data meta-data
    qemu-img create -f qcow2 "$IMG_FILE" "$DISK_SIZE"
    print_status "SUCCESS" "VM $VM_NAME image created"
}

create_vm() {
    print_status "INFO" "Creating new VM..."
    read -p "$(print_status "INPUT" "Enter VM name: ")" VM_NAME
    read -p "$(print_status "INPUT" "Enter hostname: ")" HOSTNAME
    read -p "$(print_status "INPUT" "Enter username: ")" USERNAME
    read -s -p "$(print_status "INPUT" "Enter password: ")" PASSWORD; echo
    read -p "$(print_status "INPUT" "Disk size (e.g., 20G): ")" DISK_SIZE
    read -p "$(print_status "INPUT" "Memory in MB: ")" MEMORY
    read -p "$(print_status "INPUT" "CPU count: ")" CPUS
    read -p "$(print_status "INPUT" "SSH port: ")" SSH_PORT
    read -p "$(print_status "INPUT" "Enable GUI? (y/n): ")" GUI_MODE
    GUI_MODE="${GUI_MODE:-n}"

    CREATED=$(date)
    setup_vm_image
    save_vm_config
}

start_vm() {
    local vm="$1"
    load_vm_config "$vm" || return
    print_status "INFO" "Starting VM $VM_NAME..."
    qemu-system-x86_64 -enable-kvm -m "$MEMORY" -smp "$CPUS" \
        -drive "file=$IMG_FILE,format=qcow2,if=virtio" \
        -drive "file=$SEED_FILE,format=raw,if=virtio" \
        -boot order=c -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22" \
        -device virtio-net-pci,netdev=n0 \
        -nographic
}

delete_vm() {
    local vm="$1"
    load_vm_config "$vm" || return
    rm -f "$IMG_FILE" "$SEED_FILE" "$VM_DIR/$VM_NAME.conf"
    print_status "SUCCESS" "VM $VM_NAME deleted"
}

list_menu() {
    echo -e "${yellow}Available VMs:${reset}"
    list_vms
}

# -------------------------
# 24/7 systemd service setup
# -------------------------
SERVICE_PATH="/etc/systemd/system/zynex-vps.service"
cat <<EOF | sudo tee "$SERVICE_PATH" > /dev/null
[Unit]
Description=ZYNEX VPS Manager 24/7 Service
After=network.target

[Service]
ExecStart=/usr/bin/screen -DmS zynex-vps bash -c '$VM_DIR/main.sh'
Restart=always
RestartSec=5
User=$USER
Environment=HOME=$HOME

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable zynex-vps.service
sudo systemctl start zynex-vps.service

# -------------------------
# Main Menu
# -------------------------
while true; do
    echo
    echo -e "${cyan}=== ZYNEX VPS MANAGER MENU ===${reset}"
    echo "1) Create VM"
    echo "2) Start VM"
    echo "3) Delete VM"
    echo "4) List VMs"
    echo "5) Exit"
    read -p "$(print_status "INPUT" "Choose an option: ")" choice
    case $choice in
        1) create_vm ;;
        2) read -p "$(print_status "INPUT" "Enter VM name to start: ")" vm; start_vm "$vm" ;;
        3) read -p "$(print_status "INPUT" "Enter VM name to delete: ")" vm; delete_vm "$vm" ;;
        4) list_menu ;;
        5) exit 0 ;;
        *) print_status "ERROR" "Invalid choice" ;;
    esac
done
