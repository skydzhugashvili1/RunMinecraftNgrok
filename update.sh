#!/bin/bash

# Function to install a package using apt
install_package() {
    PACKAGE_NAME=$1
    if ! dpkg -l | grep -q "^ii  $PACKAGE_NAME"; then
        echo "Installing $PACKAGE_NAME..."
        sudo apt-get update
        sudo apt-get install -y $PACKAGE_NAME
        if [ $? -ne 0 ]; then
            echo "Failed to install $PACKAGE_NAME. Exiting..."
            exit 1
        fi
    else
        echo "$PACKAGE_NAME is already installed."
    fi
}

# Function to download the latest Paper server JAR
download_paper_jar() {
    PAPER_API_BASE="https://papermc.io/api/v2/projects/paper"
    MINECRAFT_VERSION="1.20.4"

    echo "Fetching latest Paper server version..."
    LATEST_BUILD=$(curl -s "$PAPER_API_BASE/versions/$MINECRAFT_VERSION" | jq -r '.builds[-1]')
    PAPER_SERVER_JAR="paper-$MINECRAFT_VERSION-$LATEST_BUILD.jar"
    PAPER_DOWNLOAD_URL="$PAPER_API_BASE/versions/$MINECRAFT_VERSION/builds/$LATEST_BUILD/downloads/$PAPER_SERVER_JAR"

    echo "Downloading Paper server JAR from $PAPER_DOWNLOAD_URL..."
    curl -o $PAPER_SERVER_JAR $PAPER_DOWNLOAD_URL

    if [ $? -ne 0 ]; then
        echo "Failed to download Paper server JAR. Exiting..."
        exit 1
    fi
}

# Function to setup Minecraft server
setup_minecraft_server() {
    echo "Setting up Minecraft server..."
    echo "eula=true" > eula.txt
    java -Xmx1024M -Xms1024M -jar paper-1.20.4.jar nogui &
    sleep 30
}

# Function to setup SSH keys and Crowbar tunnel
setup_ssh_and_crowbar() {
    echo "Setting up SSH and Crowbar tunnel..."

    # Ensure SSH keys exist and are generated
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
    else
        echo "SSH key pair already exists."
    fi

    # Replace 'your-ssh-server' and 'your-ssh-username' with actual SSH server details
    SSH_SERVER="your-ssh-server"
    SSH_USERNAME="your-ssh-username"

    # Create ~/.ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    # Copy SSH public key to remote server
    echo "Copying SSH public key to $SSH_SERVER..."
    sshpass -p "your-ssh-password" ssh-copy-id -o StrictHostKeyChecking=no $SSH_USERNAME@$SSH_SERVER

    if [ $? -ne 0 ]; then
        echo "Failed to copy SSH public key. Exiting..."
        exit 1
    fi

    # Install Crowbar
    install_package git python3
    git clone https://github.com/q3k/crowbar.git
    cd crowbar
    sudo python3 setup.py install
    cd ..

    # Start Crowbar tunnel
    echo "Starting Crowbar tunnel to SSH server $SSH_SERVER..."
    crowbar -r ssh://$SSH_USERNAME@$SSH_SERVER:22 -L 25565:localhost:25565 > crowbar.log &

    # Wait briefly for Crowbar to establish the tunnel
    sleep 5

    # Extract the SSH tunnel URL from Crowbar log
    CROWBAR_URL=$(grep -o 'ssh://[a-zA-Z0-9./]*' crowbar.log)

    if [ -z "$CROWBAR_URL" ]; then
        echo "Failed to retrieve Crowbar tunnel URL. Check crowbar.log for details."
        exit 1
    fi

    echo "Crowbar tunnel URL: $CROWBAR_URL"
}

# Main script flow
echo "=== Minecraft Server Setup with Crowbar ==="

# Ensure necessary packages are installed
install_package curl
install_package jq
install_package openjdk-11-jre-headless  # OpenJDK 11 for Java runtime
install_package sshpass  # Utility to provide password for ssh

# Download latest Paper server JAR
download_paper_jar

# Setup and start Minecraft server
setup_minecraft_server

# Setup SSH keys and Crowbar tunnel
setup_ssh_and_crowbar

# Keep script running to maintain Minecraft server and Crowbar tunnel
echo "Script is running. Press Ctrl+C to stop."
while true; do
    sleep 3600  # Keep script running indefinitely
done
