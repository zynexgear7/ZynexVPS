#!/bin/bash
set -euo pipefail

# ───────────────────────────────
#   🚀 ZYNEX VPS MANAGER 24/7
# ───────────────────────────────

# -------------------------
# Colors & symbols
# -------------------------
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RED="\033[1;31m"
MAGENTA="\033[1;35m"
RESET="\033[0m"

# -------------------------
# VM Directory
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
        INFO) echo -e "${CYAN}[INFO]${RESET} $msg" ;;
        WARN) echo -e "${YELLOW}[WARN]${RESET} $msg" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${RESET} $msg" ;;
        ERROR) echo -e "${RED}[ERROR]${RESET} $msg" ;;
        INPUT) echo -e "${MAGENTA}[INPUT]${RESET} $msg" ;;
        *) echo "[$type] $msg" ;;
    esac
}

check_package_manager() {
    if command -v apt-get &>/dev/null; then
        PM="apt-get"
    elif command -v dnf &>/dev/null; then
        PM="dnf"
    elif command -v yum &>/dev/null; then
        PM="yum"
    else
        print_status "ERROR" "Unsupported OS"
        exit 1
    fi
}

update_system() {
    print_status "INFO" "Updating system packages..."
    sudo $PM update -y
    sudo $PM upgrade -y
    print_status "SUCCESS" "System updated"
}

install_dependencies() {
    print_status "INFO" "Installing required tools..."
    sudo $PM install -y sudo curl wget unzip git qemu-kvm cloud-utils net-tools screen openssh-client
    print_status "SUCCESS" "Dependencies installed"
}

list_vms() {
    find "$VM_DIR" -maxdepth 1 -name "*.conf" -exec basename {} .conf \; 2>/dev/null
}

save_vm_config() {
    local cfg="$VM_DIR/$VM_NAME.conf"
    cat > "$cfg" <<EOF
VM_NAME="$VM_NAME"
OS="$OS"
IMG_URL="$IMG_URL"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
GUI="$GUI"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$CREATED"
EOF
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

setup_cloud_init() {
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
}

create_vm() {
    echo -e "1) Debian\n2) Ubuntu"
    read -p "$(print_status "INPUT" "Select OS (1-2): ")" OS_CHOICE
    case $OS_CHOICE in
        1) OS="Debian"; IMG_URL="https://cloud-images.debian.org/debian-11/current/debian-11.qcow2" ;;
        2) OS="Ubuntu"; IMG_URL="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img" ;;
        *) print_status "ERROR" "Invalid OS choice"; return ;;
    esac

    read -p "$(print_status "INPUT" "Enter VM name: ")" VM_NAME
    read -p "$(print_status "INPUT" "Enter hostname: ")" HOSTNAME
    read -p "$(print_status "INPUT" "Enter username: ")" USERNAME
    read -s -p "$(print_status "INPUT" "Enter password: ")" PASSWORD; echo
    read -p "$(print_status "INPUT" "Disk size (e.g., 20G): ")" DISK_SIZE
    read -p "$(print_status "INPUT" "Memory in MB: ")" MEMORY
    read -p "$(print_status "INPUT" "CPU count: ")" CPUS
    read -p "$(print_status "INPUT" "SSH port: ")" SSH_PORT
    read -p "$(print_status "INPUT" "Enable GUI? (y/n): ")" GUI
    GUI="${GUI:-n}"

    CREATED=$(date)
    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"

    # Download image if missing
    if [[ ! -f "$IMG_FILE" ]]; then
        print_status "INFO" "Downloading $OS image..."
        wget -q --show-progress "$IMG_URL" -O "$IMG_FILE"
    fi

    setup_cloud_init
    qemu-img resize "$IMG_FILE" "$DISK_SIZE"
    save_vm_config
    print_status "SUCCESS" "VM $VM_NAME created"
}

start_vm() {
    read -p "$(print_status "INPUT" "Enter VM name to start: ")" VM_NAME
    load_vm_config "$VM_NAME" || return
    print_status "INFO" "Starting VM $VM_NAME..."
    qemu-system-x86_64 -enable-kvm -m "$MEMORY" -smp "$CPUS" \
        -drive "file=$IMG_FILE,format=qcow2,if=virtio" \
        -drive "file=$SEED_FILE,format=raw,if=virtio" \
        -boot order=c -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22" \
        -device virtio-net-pci,netdev=n0 \
        $( [[ "$GUI" == "y" ]] && echo "-vga virtio -display gtk" || echo "-nographic" )
}

delete_vm() {
    read -p "$(print_status "INPUT" "Enter VM name to delete: ")" VM_NAME
    load_vm_config "$VM_NAME" || return
    rm -f "$IMG_FILE" "$SEED_FILE" "$VM_DIR/$VM_NAME.conf"
    print_status "SUCCESS" "VM $VM_NAME deleted"
}

list_vms_menu() {
    echo -e "${YELLOW}Available VMs:${RESET}"
    list_vms
}

# -------------------------
# Menu
# -------------------------
check_package_manager
update_system
install_dependencies

while true; do
    echo
    echo -e "${CYAN}=== ZYNEX VPS MANAGER MENU ===${RESET}"
    echo "1) Create VM"
    echo "2) Start VM"
    echo "3) Delete VM"
    echo "4) List VMs"
    echo "5) Exit"
    read -p "$(print_status "INPUT" "Choose an option: ")" CHOICE
    case $CHOICE in
        1) create_vm ;;
        2) start_vm ;;
        3) delete_vm ;;
        4) list_vms_menu ;;
        5) print_status "INFO" "Exiting..."; exit 0 ;;
        *) print_status "ERROR" "Invalid choice" ;;
    esac
done
