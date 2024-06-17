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

# Install Node.js and npm using apt (if needed)
# install_package nodejs npm

# Install the latest OpenJDK 21
echo "Installing OpenJDK 21..."
install_package openjdk-21-jdk

# Verify Java installation
if ! command -v java &> /dev/null; then
    echo "Java could not be installed. Exiting..."
    exit 1
fi

# Install sshuttle
echo "Installing sshuttle..."
install_package sshuttle

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

# Start Paper Minecraft server in the background
echo "Starting Paper Minecraft server..."
java -Xmx1024M -Xms1024M -jar $PAPER_SERVER_JAR nogui &

# Get the process ID of the Minecraft server
MC_SERVER_PID=$!

# Wait for the Minecraft server to initialize (adjust as necessary)
sleep 22

# Check if the Minecraft server is running
if ps -p $MC_SERVER_PID > /dev/null; then
    echo "Minecraft server is running with PID $MC_SERVER_PID"
else
    echo "Minecraft server failed to start. Exiting..."
    exit 1
fi

# Start SSH tunneling with sshuttle (replace user and your-ssh-server with your SSH username and server address)
echo "Starting SSH tunnel with sshuttle..."
sshuttle -r user@your-ssh-server 0/0 -vv

# Replace user@your-ssh-server with your SSH username and server address.
