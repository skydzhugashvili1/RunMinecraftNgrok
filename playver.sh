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

# Function to install Playit.GG
install_playit_gg() {
    echo "Installing Playit.GG..."
    curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | sudo tee /etc/apt/sources.list.d/playit-cloud.list
    sudo apt update
    sudo apt install -y playit

    # Verify installation
    playit --version
}

# Function to setup Minecraft server
setup_minecraft_server() {
    echo "Setting up Minecraft server..."
    echo "eula=true" > eula.txt
    java -Xmx1024M -Xms1024M -jar paper-1.20.4.jar nogui &
    sleep 30  # Wait for Minecraft server to start
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

# Function to install OpenJDK 17
install_openjdk_17() {
    echo "Installing OpenJDK 17..."

    # Add AdoptOpenJDK repository and install OpenJDK 17
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk

    # Verify installation
    java -version
}

# Function to run Playit.GG setup and wait for 60 seconds
run_playit_setup() {
    echo "Running Playit.GG setup..."
    playit setup

    echo "Waiting for 60 seconds..."
    sleep 60
}

# Main script flow
echo "=== Minecraft Server Setup with Playit.GG ==="

# Ensure necessary packages are installed
install_package curl
install_package jq

# Install Playit.GG
install_playit_gg

# Download latest Paper server JAR
download_paper_jar

# Install OpenJDK 17
install_openjdk_17

# Setup and start Minecraft server
setup_minecraft_server

# Run Playit.GG setup and wait for 60 seconds after Minecraft server starts
run_playit_setup

# End of script
