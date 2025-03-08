#!/bin/bash

set -e  # Exit on error

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if Docker is installed
check_docker_installed() {
    if command_exists docker; then
        echo "Docker is already installed."
        return 0
    else
        return 1
    fi
}

# Function to check if Docker Compose is installed
check_docker_compose_installed() {
    if command_exists docker-compose; then
        echo "Docker Compose is already installed."
        return 0
    else
        return 1
    fi
}

# Function to install Docker on Linux
install_docker_linux() {
    echo "Installing Docker on Linux..."
    sudo apt install -y curl
    if check_docker_installed; then
        echo "Docker is already installed."
    else
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y docker.io
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y docker
        elif [ -f /etc/arch-release ]; then
            sudo pacman -S --noconfirm docker
        else
            echo "Unsupported Linux distribution. Install Docker manually."
            exit 1
        fi
        sudo systemctl enable --now docker
        echo "Docker installed successfully on Linux."
    fi
}

# Function to install Docker on macOS
install_docker_macos() {
    echo "Installing Docker on macOS..."
    if check_docker_installed; then
        echo "Docker is already installed."
    else
        if command_exists brew; then
            brew install --cask docker
        else
            echo "Homebrew not found. Please install Homebrew first: https://brew.sh/"
            exit 1
        fi
        echo "Docker installed successfully on macOS."
    fi
}

# Function to install Docker Compose on Linux
install_docker_compose_linux() {
    echo "Installing Docker Compose on Linux..."
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully on Linux."
}

# Function to install Docker Compose on macOS
install_docker_compose_mac() {
    echo "Installing Docker Compose on macOS..."
    brew install docker-compose
    echo "Docker Compose installed successfully on macOS."
}

# Function to run QEMU user-static setup
setup_qemu_user_static() {
    echo "Setting up QEMU user-static..."
    sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    echo "QEMU user-static setup completed."
}

# Function to find the IP address of the dnsmasq container
get_dnsmasq_ip() {
    echo "Finding IP address of dnsmasq container..."
    DNSMASQ_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dnsmasq)
    if [ -z "$DNSMASQ_IP" ]; then
        echo "Failed to find IP address of dnsmasq container."
        exit 1
    fi
    echo "dnsmasq container IP address: $DNSMASQ_IP"
}

# Uncomment the next section if you are doing this to one device instead of the router

# # Function to update /etc/resolv.conf with the dnsmasq container IP on Linux
# update_resolv_conf_linux() {
#     echo "Updating /etc/resolv.conf with dnsmasq container IP..."
#     sudo sh -c "echo '' > /etc/resolv.conf"  # Clear the file first
#     sudo sh -c "echo 'nameserver $DNSMASQ_IP' >> /etc/resolv.conf"  # Append the new nameserver entry
#     echo "/etc/resolv.conf updated successfully."
# }

# # Function to update DNS settings on macOS
# update_dns_macos() {
#     echo "Updating DNS settings on macOS with dnsmasq container IP..."
#     networksetup -setdnsservers Wi-Fi $DNSMASQ_IP
#     echo "DNS settings updated successfully on macOS."
# }

# Detect OS
OS=$(uname -s)

# Main execution based on OS
case "$OS" in
    "Linux")
        install_docker_linux
        install_docker_compose_linux
        setup_qemu_user_static
        sudo systemctl restart docker
        ;;
    "Darwin")
        install_docker_macos
        install_docker_compose_mac
        setup_qemu_user_static
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# # Find the IP address of the dnsmasq container and update DNS settings
# get_dnsmasq_ip
# if [[ "$OS" == "Linux" ]]; then
#     update_resolv_conf_linux
# elif [[ "$OS" == "Darwin" ]]; then
#     update_dns_macos
# fi

echo "Docker and Docker Compose setup completed successfully!"
docker-compose -f ../docker-compose.yml up -d