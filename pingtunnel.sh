#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   sleep 1
   exit 1
fi

# Function to press any key to continue
press_key() {
    read -p "Press any key to continue..."
}

    purple="\033[35m"
    green="\033[32m"
    orange="\033[33m"
    blue="\033[34m"
    red="\033[31m"
    cyan="\033[36m"
    white="\033[37m"
    reset="\033[0m"

# Define a function to colorize text
colorize() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"
    
    # Define ANSI color codes
    local purple="\033[35m"
    local green="\033[32m"
    local orange="\033[33m"
    local blue="\033[34m"
    local red="\033[31m"
    local cyan="\033[36m"
    local white="\033[37m"
    local reset="\033[0m"
    
    # Define ANSI style codes
    local normal="\033[0m"
    local bold="\033[1m"
    local underline="\033[4m"
    
    # Select color code
    local color_code
    case $color in
        purple) color_code=$purple ;;
        green) color_code=$green ;;
        orange) color_code=$orange ;;
        blue) color_code=$blue ;;
        red) color_code=$red ;;
        cyan) color_code=$cyan ;;
        white) color_code=$white ;;
        *) color_code=$reset ;;
    esac
    
    # Select style code
    local style_code
    case $style in
        bold) style_code=$bold ;;
        underline) style_code=$underline ;;
        normal | *) style_code=$normal ;;
    esac

    # Print the colored and styled text
    echo -e "${style_code}${color_code}${text}${reset}"
}

# Function to install unzip if not already installed
install_unzip() {
    if ! command -v unzip &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            colorize orange "unzip is not installed. Installing..." bold
            sleep 1
            sudo apt-get update
            sudo apt-get install -y unzip
        else
            colorize red "Error: Unsupported package manager. Please install unzip manually." bold
            press_key
            exit 1
        fi
    fi
}

# Install unzip
install_unzip

# Function to install curl if not already installed
install_curl() {
    if ! command -v curl &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            colorize orange "curl is not installed. Installing..." bold
            sleep 1
            sudo apt-get update
            sudo apt-get install -y curl
        else
            colorize red "Error: Unsupported package manager. Please install curl manually." bold
            press_key
            exit 1
        fi
    fi
}

# Install curl
install_curl

# Define configuration directory
config_dir="/root/pingtunnel-core"
service_dir="/etc/systemd/system"

# Function to download and extract PingTunnel
download_and_extract_pingtunnel() {
    if [[ -f "${config_dir}/pingtunnel" ]]; then
        return 0
    fi

    # Check operating system and architecture
    if [[ $(uname) == "Linux" ]]; then
        ARCH=$(uname -m)
        case $ARCH in
            x86_64) DOWNLOAD_URL="https://github.com/jenaze/pingtunnel/raw/refs/heads/main/pingtunnel_linux_amd64.zip" ;;
            arm*) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_arm.zip" ;;
            aarch64) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_arm64.zip" ;;
            mips) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_mips.zip" ;;
            mipsel) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_mipsle.zip" ;;
            mips64) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_mips64.zip" ;;
            mips64el) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_mips64le.zip" ;;
            ppc64) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_ppc64.zip" ;;
            ppc64le) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_ppc64le.zip" ;;
            riscv64) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_riscv64.zip" ;;
            s390x) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_s390x.zip" ;;
            i386 | i686) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_386.zip" ;;
            loong64) DOWNLOAD_URL="http://89.44.241.48/pingtunnel/2.8/pingtunnel_linux_loong64.zip" ;;
            *) colorize red "Unsupported architecture: $ARCH" bold; sleep 1; exit 1 ;;
        esac
    else
        colorize red "Unsupported operating system." bold
        sleep 1
        exit 1
    fi

    if [ -z "$DOWNLOAD_URL" ]; then
        colorize red "Failed to determine download URL." bold
        sleep 1
        exit 1
    fi

    DOWNLOAD_DIR=$(mktemp -d)
    colorize blue "Downloading PingTunnel from $DOWNLOAD_URL..." bold
    sleep 1
    curl -sSL -o "$DOWNLOAD_DIR/pingtunnel.zip" "$DOWNLOAD_URL"
    colorize blue "Extracting PingTunnel..." bold
    sleep 1
    mkdir -p "$config_dir"
    unzip -q "$DOWNLOAD_DIR/pingtunnel.zip" -d "$config_dir"
    chmod +x "${config_dir}/pingtunnel"
    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
    colorize green "PingTunnel installation completed." bold
    rm -rf "$DOWNLOAD_DIR"
}

# Function to display ASCII logo
display_logo() {
    echo -e "${purple}"
    cat << "EOF"
______ _____ _   _ _____   _____ _   _ _   _  _   _  _____ _     
| ___ \_   _| \ | |  __ \ |_   _| | | | \ | || \ | ||  ___| |    
| |_/ / | | |  \| | |  \/   | | | | | |  \| ||  \| || |__ | |    
|  __/  | | | . ` | | __    | | | | | | . ` || . ` ||  __|| |    
| |    _| |_| |\  | |_\ \   | | | |_| | |\  || |\  || |___| |____
\_|    \___/\_| \_/\____/   \_/  \___/\_| \_/\_| \_/\____/\_____/
EOF
    colorize green "Version: ${orange}v1.0${reset}" bold
    colorize green "Github: ${orange}github.com/ppouria/ping-tunnel${reset}" bold
    colorize green "Telegram Channel: ${orange}@MarzHelp${reset}" bold
}

# Function to display server location and IP
display_server_info() {
    SERVER_IP=$(hostname -I | awk '{print $1}')
    SERVER_COUNTRY=$(curl --max-time 3 -sS "http://ipwhois.app/json/$SERVER_IP" | jq -r '.country' 2>/dev/null || echo "Unknown")
    SERVER_ISP=$(curl --max-time 3 -sS "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp' 2>/dev/null || echo "Unknown")
    colorize cyan "═════════════════════════════════════════════"
    colorize cyan "Location: ${green}${SERVER_COUNTRY}${cyan}"
    colorize cyan "Datacenter: ${green}${SERVER_ISP}${cyan}"
}

display_pingtunnel_status() {
    if [[ -f "${config_dir}/pingtunnel" ]]; then
        colorize cyan "PingTunnel Core: ${green}Installed${cyan}"
    else
        colorize cyan "PingTunnel Core: ${red}Not installed${cyan}"
    fi
    colorize cyan "═════════════════════════════════════════════"
}

# Function to check if a port is valid and available
check_port() {
    local port=$1
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -gt 1024 ] && [ "$port" -le 65535 ]; then
        if ss -tln | grep -q ":$port "; then
            colorize red "Port $port is already in use." bold
            return 1
        else
            return 0
        fi
    else
        colorize red "Invalid port. Please enter a number between 1025 and 65535." bold
        return 1
    fi
}

# Function to configure tunnel
configure_tunnel() {
    if [[ ! -f "${config_dir}/pingtunnel" ]]; then
        colorize red "PingTunnel is not installed. Please install it first." bold
        press_key
        return 1
    fi

    clear
    colorize blue "Configure PingTunnel" bold
    echo
    colorize green "1) Configure for Iran server" bold
    colorize green "2) Configure for Kharej server" bold
    echo
    read -p "Enter your choice [1-2]: " choice
    case $choice in
        1) iran_server_configuration ;;
        2) kharej_server_configuration ;;
        *) colorize red "Invalid option!" bold; sleep 1; return 1 ;;
    esac
    press_key
}

# Function to configure Iran server
iran_server_configuration() {
    clear
    colorize blue "Configuring Iran Server" bold
    echo

    # Prompt for Kharej server IP
    while true; do
        read -p "[*] Enter Kharej server IP: " kharej_ip
        if [[ "$kharej_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            break
        else
            colorize red "Invalid IP address. Please enter a valid IPv4 address." bold
        fi
    done

    # Prompt for port
    while true; do
        read -p "[*] Enter tunnel port: " tunnel_port
        if check_port "$tunnel_port"; then
            break
        fi
    done

    # Create systemd service file
    cat << EOF > "${service_dir}/pingtunnel-iran${tunnel_port}.service"
[Unit]
Description=PingTunnel Iran Client (Port $tunnel_port)
After=network.target

[Service]
Type=simple
ExecStart=${config_dir}/pingtunnel -type client -l :${tunnel_port} -s ${kharej_ip} -t 127.0.0.1:${tunnel_port} -tcp 1
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and start service
    systemctl daemon-reload >/dev/null 2>&1
    if systemctl enable --now "pingtunnel-iran${tunnel_port}.service" >/dev/null 2>&1; then
        colorize green "Iran tunnel service on port $tunnel_port started and enabled." bold
    else
        colorize red "Failed to start Iran tunnel service on port $tunnel_port." bold
        return 1
    fi

    colorize green "Iran server configuration completed successfully." bold
}

# Function to configure Kharej server
kharej_server_configuration() {
    clear
    colorize blue "Configuring Kharej Server" bold
    echo

    # Create systemd service file
    cat << EOF > "${service_dir}/pingtunnel-kharej.service"
[Unit]
Description=PingTunnel Kharej Server
After=network.target

[Service]
Type=simple
ExecStart=${config_dir}/pingtunnel -type server
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and start service
    systemctl daemon-reload >/dev/null 2>&1
    if systemctl enable --now "pingtunnel-kharej.service" >/dev/null 2>&1; then
        colorize green "Kharej server service started and enabled." bold
    else
        colorize red "Failed to start Kharej server service." bold
        return 1
    fi

    colorize green "Kharej server configuration completed successfully." bold
}

# Function to check tunnel status
check_tunnel_status() {
    clear
    colorize blue "Checking Tunnel Status" bold
    echo

    local found=0
    for service in $(systemctl list-units --type=service | grep pingtunnel | awk '{print $1}'); do
        found=1
        if systemctl is-active --quiet "$service"; then
            colorize green "$service is running" bold
        else
            colorize red "$service is not running" bold
        fi
    done

    if [ $found -eq 0 ]; then
        colorize red "No PingTunnel services found." bold
    fi

    press_key
}

# Function to manage tunnels
tunnel_management() {
    clear
    colorize blue "Tunnel Management Menu" bold
    echo

    local index=1
    declare -a services

    for service in $(systemctl list-units --type=service | grep pingtunnel | awk '{print $1}'); do
        services+=("$service")
        echo -e "${cyan}${index}${reset}) ${green}${service}${reset}"
        ((index++))
    done

    if [ ${#services[@]} -eq 0 ]; then
        colorize red "No PingTunnel services found." bold
        press_key
        return 1
    fi

    echo
    read -p "Select a service (0 to return): " choice
    if [ "$choice" == "0" ]; then
        return
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#services[@]} ]; then
        colorize red "Invalid choice." bold
        sleep 1
        return 1
    fi

    selected_service="${services[$((choice - 1))]}"
    clear
    colorize blue "Manage $selected_service" bold
    echo
    colorize green "1) Restart service" bold
    colorize red "2) Stop service" bold
    colorize red "3) Delete service" bold
    colorize cyan "4) View service logs" bold
    colorize cyan "5) View service status" bold
    echo
    read -p "Enter your choice [0-5]: " action
    case $action in
        1) systemctl restart "$selected_service"; colorize green "Service restarted." bold ;;
        2) systemctl stop "$selected_service"; colorize red "Service stopped." bold ;;
        3) systemctl disable --now "$selected_service" >/dev/null 2>&1; rm -f "${service_dir}/${selected_service}"; systemctl daemon-reload; colorize red "Service deleted." bold ;;
        4) journalctl -eu "$selected_service";;
        5) systemctl status "$selected_service";;
        0) return ;;
        *) colorize red "Invalid option!" bold; sleep 1 ;;
    esac
    press_key
}

# Function to display menu
display_menu() {
    clear
    display_logo
    display_server_info
    display_pingtunnel_status
    echo
    colorize green "1. Configure a new tunnel" bold
    colorize red "2. Tunnel management menu" bold
    colorize cyan "3. Check tunnels status" bold
    colorize orange "4. Install PingTunnel core" bold
    colorize red "5. Remove PingTunnel core" bold
    colorize white "0. Exit" bold
    echo
    echo "-------------------------------"
}

# Function to read user input
read_option() {
    read -p "Enter your choice [0-5]: " choice
    case $choice in
        1) configure_tunnel ;;
        2) tunnel_management ;;
        3) check_tunnel_status ;;
        4) download_and_extract_pingtunnel "sleep" ;;
        5) remove_core ;;
        0) exit 0 ;;
        *) colorize red "Invalid option!" bold; sleep 1 ;;
    esac
}

# Function to remove PingTunnel core
remove_core() {
    clear
    colorize blue "Remove PingTunnel Core" bold
    echo

    if find "$service_dir" -type f -name "pingtunnel-*.service" | grep -q .; then
        colorize red "Active services found. Please delete all services before removing PingTunnel core." bold
        press_key
        return 1
    fi

    read -p "Are you sure you want to remove PingTunnel core? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        if [[ -d "$config_dir" ]]; then
            rm -rf "$config_dir"
            colorize green "PingTunnel core removed successfully." bold
        else
            colorize red "PingTunnel core directory not found." bold
        fi
    else
        colorize orange "PingTunnel core removal canceled." bold
    fi
    press_key
}

# Install PingTunnel core automatically on script start
download_and_extract_pingtunnel

# Main script loop
while true; do
    display_menu
    read_option
done
