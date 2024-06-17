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

# Function to install OpenJDK 17
install_openjdk_17() {
    echo "Installing OpenJDK 17..."

    # Add AdoptOpenJDK repository and install OpenJDK 17
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk

    # Verify installation
    java -version
}

# Function to start Cloudflared tunnel with API token and random subdomain
start_cloudflared_tunnel() {
    echo "Starting Cloudflared tunnel..."

    # Replace with your Cloudflare API token
    CLOUDFLARE_API_TOKEN="93AA4CAo27x6P_LbMdG5zZLyes0sjkWmAlgL8_Ke"
    
    # Generate random subdomain between 1999 and 59999
    RANDOM_SUBDOMAIN=$(( RANDOM % (59999 - 1999 + 1 ) + 1999 ))
    CLOUDFLARED_SUBDOMAIN="$RANDOM_SUBDOMAIN.jcbm-mc.uk"

    # Start the tunnel using the API token for authentication
    cloudflared tunnel --origincert $CLOUDFLARE_API_TOKEN --hostname $CLOUDFLARED_SUBDOMAIN --url http://localhost:25565 > cloudflared.log &

    echo "Cloudflared tunnel started with API token authentication."
    echo "Subdomain: $CLOUDFLARED_SUBDOMAIN"
    echo "Check cloudflared.log for details."
}

# Main script flow
echo "=== Minecraft Server Setup with Cloudflared ==="

# Ensure necessary packages are installed
install_package curl
install_package jq

# Download latest Paper server JAR
download_paper_jar

# Install OpenJDK 17
install_openjdk_17

# Setup and start Minecraft server
setup_minecraft_server

# Start Cloudflared tunnel with API token authentication and random subdomain
start_cloudflared_tunnel

# Keep script running to maintain Minecraft server and Cloudflared tunnel
echo "Script is running. Press Ctrl+C to stop."
while true; do
    sleep 3600  # Keep script running indefinitely
done
