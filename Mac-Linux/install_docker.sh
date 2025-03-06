#!/bin/bash

set -e  # Exit on error

# Detect OS
OS=$(uname -s)

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker on Linux
install_docker_linux() {
    echo "Installing Docker on Linux..."
    if command_exists docker; then
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

# Install Docker on macOS
install_docker_macos() {
    echo "Installing Docker on macOS..."
    if command_exists docker; then
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

# Install Docker Compose (Linux/macOS)
install_docker_compose() {
    echo "Installing Docker Compose..."
    if command_exists docker-compose; then
        echo "Docker Compose is already installed."
    else
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed successfully."
    fi
}

# Main execution based on OS
case "$OS" in
    "Linux")
        install_docker_linux
        install_docker_compose
        ;;
    "Darwin")
        install_docker_macos
        install_docker_compose
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Docker and Docker Compose setup completed successfully!"
