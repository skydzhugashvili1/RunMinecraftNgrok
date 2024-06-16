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

# Ensure curl is installed
install_package curl

# Ensure jq is installed
install_package jq

# Install ngrok using apt
echo "Installing ngrok..."
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list \
    && sudo apt update \
    && sudo apt install -y ngrok

# Check if ngrok was installed successfully
if ! command -v ngrok &> /dev/null; then
    echo "ngrok could not be installed, please check your network connection and try again."
    exit 1
fi

# Define the URL for the version manifest
VERSION_MANIFEST_URL="https://launchermeta.mojang.com/mc/game/version_manifest.json"

# Fetch the latest version manifest and extract the URL for the latest release
MC_SERVER_URL=$(curl -s $VERSION_MANIFEST_URL | jq -r '.latest.release as $version | .versions[] | select(.id == $version) | .url')

# Fetch the download URL for the server JAR from the extracted URL
MC_SERVER_JAR_URL=$(curl -s $MC_SERVER_URL | jq -r '.downloads.server.url')

# Define the filename for the Minecraft server JAR
MC_SERVER_JAR="minecraft_server.jar"

# Download the latest Minecraft server JAR
echo "Downloading the latest Minecraft server JAR from $MC_SERVER_JAR_URL..."
curl -o $MC_SERVER_JAR $MC_SERVER_JAR_URL

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download the Minecraft server JAR."
    exit 1
fi

# Set ngrok authtoken
NGROK_AUTHTOKEN="2ghdAuc1i91WrLpMtEcqoNWSqr5_7157CeKfY1F2W694NNL17"

# Start ngrok TCP tunnel for port 25565
echo "Starting ngrok TCP tunnel on port 25565..."
ngrok authtoken $NGROK_AUTHTOKEN
ngrok tcp 25565 &

# Wait for ngrok to initialize and capture the public URL
sleep 10

# Extract and display ngrok URL
NGROK_URL=$(curl --silent http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto == "tcp") | .public_url' | sed 's/tcp:\/\///')
echo "ngrok is running at: $NGROK_URL"

# Start Minecraft server
echo "Starting Minecraft server..."
java -Xmx1024M -Xms1024M -jar $MC_SERVER_JAR nogui
