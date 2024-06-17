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

# Ensure curl and jq are installed
install_package curl
install_package jq

# Ensure gnupg is installed for adding repositories
install_package gnupg

# Install the latest OpenJDK 21
echo "Installing OpenJDK 21..."
install_package openjdk-21-jdk

# Verify Java installation
if ! command -v java &> /dev/null; then
    echo "Java could not be installed. Exiting..."
    exit 1
fi

# Install ngrok
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

# Define the base URL for the Paper API
PAPER_API_BASE="https://api.papermc.io/v2/projects/paper/versions"

# Define the Minecraft version
MINECRAFT_VERSION="1.20.4"

# Fetch the latest build number for the specified Minecraft version
LATEST_BUILD=$(curl -s "$PAPER_API_BASE/$MINECRAFT_VERSION" | jq -r '.builds[-1]')

# Check if the latest build number was retrieved successfully
if [ -z "$LATEST_BUILD" ]; then
    echo "Failed to retrieve the latest build number for Paper $MINECRAFT_VERSION."
    exit 1
fi

# Define the URL to download the latest Paper server jar
PAPER_SERVER_JAR_URL="$PAPER_API_BASE/$MINECRAFT_VERSION/builds/$LATEST_BUILD/downloads/paper-$MINECRAFT_VERSION-$LATEST_BUILD.jar"

# Define the filename for the Paper server jar
PAPER_SERVER_JAR="paper_server.jar"

# Download the latest Paper server jar for version 1.20.4
echo "Downloading the latest Paper server JAR from $PAPER_SERVER_JAR_URL..."
curl -o $PAPER_SERVER_JAR $PAPER_SERVER_JAR_URL

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download the Paper server JAR."
    exit 1
fi

# Create eula.txt file with eula=true
echo "Creating eula.txt file with eula=true..."
echo "eula=true" > eula.txt

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
sleep 10

# Start Paper Minecraft server
echo "Starting Paper Minecraft server..."
java -Xmx1024M -Xms1024M -jar $PAPER_SERVER_JAR nogui
