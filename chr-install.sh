#!/usr/bin/env bash

set -euo pipefail

# Default CHR version
DEFAULT_CHR_VERSION="6.49.13"
MOUNT_POINT="/mnt/chr"
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"
COLOR_RESET="\e[0m"

show_loading() {
    local pid=$!
    local spinstr='|/-\'
    local delay=0.1
    echo -n " "
    while ps -p $pid &> /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo " "
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${COLOR_RED}This script must be run as root${COLOR_RESET}"
        exit 1
    fi
}

ask_chr_version() {
    echo -ne "${COLOR_YELLOW}Enter CHR version to install [default: ${DEFAULT_CHR_VERSION}]: ${COLOR_RESET}"
    read -r input_version
    CHR_VERSION="${input_version:-$DEFAULT_CHR_VERSION}"
    CHR_IMAGE="chr-${CHR_VERSION}.img"
    CHR_ZIP="chr-${CHR_VERSION}.img.zip"
}

show_system_details() {
    echo -e "${COLOR_BLUE}Gathering system details...${COLOR_RESET}"
    IP=$(curl -s http://checkip.amazonaws.com || echo "N/A")
    RAM=$(free -m | awk '/Mem:/ { print $2 }')
    CPU=$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)
    STORAGE=$(df -h / | awk 'NR==2 {print $2}')
    echo -e "${COLOR_GREEN}System Details:\nIP: $IP\nRAM: ${RAM}MB\nCPU: $CPU\nStorage: $STORAGE${COLOR_RESET}"
}

show_banner() {
    echo -e "${COLOR_YELLOW}"
    cat << "EOF"
   _____   _    _   _____                         _           
  / ____| | |  | | |  __ \        /\             | |          
 | |      | |__| | | |__) |      /  \     _   _  | |_    ___  
 | |      |  __  | |  _  /      / /\ \   | | | | | __|  / _ \ 
 | |____  | |  | | | | \ \     / ____ \  | |_| | | |_  | (_) |
  \_____| |_|  |_| |_|  \_\   /_/    \_\  \__,_|  \__|  \___/ 
                                                             
                            === By Mostech ===                 
EOF
    echo -e "${COLOR_RESET}"
}

prepare_environment() {
    echo -e "${COLOR_BLUE}Installing required packages...${COLOR_RESET}"
    apt update -y > /dev/null 2>&1 && apt install unzip curl wget -y > /dev/null 2>&1 &
    show_loading
}

download_and_extract_image() {
    echo -e "${COLOR_BLUE}Downloading CHR image version ${CHR_VERSION}...${COLOR_RESET}"
    wget -qO "$CHR_ZIP" "https://download.mikrotik.com/routeros/$CHR_VERSION/$CHR_ZIP" || {
        echo -e "${COLOR_RED}Download failed. Please check the version and try again.${COLOR_RESET}"
        exit 1
    }
    echo -e "${COLOR_BLUE}Extracting image...${COLOR_RESET}"
    unzip -o "$CHR_ZIP" > /dev/null 2>&1 && rm -f "$CHR_ZIP"
}

mount_image_and_configure() {
    mkdir -p "$MOUNT_POINT"
    echo -e "${COLOR_BLUE}Mounting image...${COLOR_RESET}"
    mount -o loop,offset=512 "$CHR_IMAGE" "$MOUNT_POINT" > /dev/null 2>&1 &
    show_loading

    INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
    INTERFACE_IP=$(ip -4 addr show "$INTERFACE" | grep inet | awk '{print $2}' | head -n1)
    INTERFACE_GATEWAY=$(ip route show default | awk '{print $3}')

    if [[ -z "$INTERFACE_IP" || -z "$INTERFACE_GATEWAY" ]]; then
        echo -e "${COLOR_RED}Failed to detect IP or gateway. Aborting.${COLOR_RESET}"
        exit 1
    fi

    cat <<EOF > "$MOUNT_POINT/rw/autorun.scr"
/ip address add address=${INTERFACE_IP} interface=[/interface ethernet find where name=ether1]
/ip route add gateway=${INTERFACE_GATEWAY}
EOF

    umount "$MOUNT_POINT" > /dev/null 2>&1
    rm -rf "$MOUNT_POINT"
}

write_image_to_disk() {
    DISK=$(lsblk -dno NAME,TYPE | awk '$2=="disk"{print $1; exit}')
    if [[ -z "$DISK" ]]; then
        echo -e "${COLOR_RED}No disk found to write CHR image.${COLOR_RESET}"
        exit 1
    fi

    echo -e "${COLOR_BLUE}Writing image to /dev/${DISK}...${COLOR_RESET}"
    sync && echo u > /proc/sysrq-trigger
    dd if="$CHR_IMAGE" of="/dev/${DISK}" bs=1M status=progress conv=fsync &
    show_loading
}

cleanup() {
    rm -f "$CHR_IMAGE"
}

main() {
    check_root
    show_banner
    ask_chr_version
    show_system_details
    prepare_environment
    download_and_extract_image
    mount_image_and_configure
    write_image_to_disk
    cleanup

    echo -e "${COLOR_GREEN}Installation complete. Reboot your server and configure CHR via Winbox.${COLOR_RESET}"
}

main