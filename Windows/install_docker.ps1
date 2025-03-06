# PowerShell script to install Docker, Docker Compose, enable WSL, and run containers from docker-compose.yml
# Run this script as Administrator

$ErrorActionPreference = "Stop"

# Function to check if a command exists
function Command-Exists {
    param ($command)
    return [bool](Get-Command $command -ErrorAction SilentlyContinue)
}

# Function to check if Docker is installed
function Check-DockerInstalled {
    if (Command-Exists docker) {
        Write-Host "Docker is already installed."
        return $true
    } else {
        return $false
    }
}

# Function to check if Docker Compose is installed
function Check-DockerComposeInstalled {
    if (Command-Exists "docker-compose") {
        Write-Host "Docker Compose is already installed."
        return $true
    } else {
        return $false
    }
}

# Function to check if WSL is installed
function Check-WSLInstalled {
    if (Command-Exists wsl) {
        Write-Host "WSL is already installed."
        return $true
    } else {
        return $false
    }
}

# Function to install WSL if not installed
function Install-WSL {
    Write-Host "Installing Windows Subsystem for Linux (WSL)..."
    wsl --install -d Ubuntu
    wsl --set-default-version 2
    wsl --set-version Ubuntu 2
    Write-Host "Ubuntu installation complete. Please restart your computer."
    Restart-Computer
    exit
}

# Function to install Docker
function Install-Docker {
    Write-Host "Installing Docker Desktop..."
    winget install -e --id Docker.DockerDesktop
    Write-Host "Installation complete. Please restart your computer."
    Restart-Computer
    exit
}

function Install-DockerComposeInUbuntu {
    Write-Host "Installing Docker Compose inside Ubuntu..."
    wsl -d Ubuntu -- sudo apt-get update
    wsl -d Ubuntu -- sudo apt-get install -y docker-compose
    Write-Host "Docker Compose installation complete inside Ubuntu."
}

function Run-Docker-Compose {
    $dockerComposeFilePath = "..\docker-compose.yml"  # Specify the custom path

    if (Test-Path $dockerComposeFilePath) {
        Write-Host "docker-compose.yml found. Pulling images and starting containers..."

        # Ensure Docker Compose is installed inside Ubuntu
        Install-DockerComposeInUbuntu

        # Run docker-compose with the specified file path inside Ubuntu (WSL)
        Write-Host "Running docker-compose inside Ubuntu..."
        wsl -d Ubuntu -- sudo docker-compose -f $dockerComposeFilePath pull
        wsl -d Ubuntu -- sudo docker-compose -f $dockerComposeFilePath up -d
        Write-Host "Containers started successfully."
    } else {
        Write-Host "docker-compose.yml not found at the specified path!"
        exit 1
    }
}


# Function to check if Virtualization is enabled in BIOS (for Hyper-V and Virtual Platform)
function Check-VirtualizationEnabled {
    $virtualization = (Get-WmiObject -Query "Select * from Win32_Processor").VirtualizationFirmwareEnabled
    if ($virtualization) {
        Write-Host "Virtualization is enabled."
        return $true
    } else {
        Write-Host "Virtualization is not enabled. Please enable it in BIOS and restart the system."
        return $false
    }
}

# Function to enable Hyper-V and Virtual Machine Platform (for WSL 2 support)
function Enable-HyperVAndVirtualPlatform {
    Write-Host "Enabling Hyper-V and Virtual Machine Platform..."
    dism.exe /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V-All /LimitAccess
    dism.exe /Online /Enable-Feature /All /FeatureName:VirtualMachinePlatform /LimitAccess
    Write-Host "Hyper-V and Virtual Machine Platform enabled. Restarting the system..."
    Restart-Computer
    exit
}

    
if (-Not (Check-DockerInstalled)) {
    # Main script execution
    $ubuntuInstalled = wsl --list --verbose | Select-String -Pattern "Ubuntu"
    if ($ubuntuInstalled) {
        Write-Host "Ubuntu is installed for WSL."
    } else {
        Install-WSL
    }
    if (-Not (Check-VirtualizationEnabled)) {
        Enable-HyperVAndVirtualPlatform
    }
    Install-Docker
}

# Wait for Docker to start
Write-Host "Waiting for Docker to start..."
Start-Sleep -Seconds 10

# Ensure Docker Compose is installed
if (-Not (Check-DockerComposeInstalled)) {
    Install-DockerComposeInUbuntu
}

# Start the services using docker-compose
Run-Docker-Compose
