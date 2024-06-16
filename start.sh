#!/bin/bash

# Define the URL for the latest Minecraft server JAR
MC_SERVER_URL="https://launcher.mojang.com/v1/objects/$(wget -qO- https://launchermeta.mojang.com/mc/game/version_manifest.json | grep -oP '(?<=url": ")[^"]+' | xargs wget -qO- | grep -oP '(?<=server": {"sha1": "[^"]+", "size": \d+, "url": ")[^"]+')"

# Define the filename for the Minecraft server JAR
MC_SERVER_JAR="minecraft_server.jar"

# Download the latest Minecraft server JAR
echo "Downloading the latest Minecraft server JAR..."
wget -O $MC_SERVER_JAR $MC_SERVER_URL

# Set ngrok authtoken
NGROK_AUTHTOKEN="2ghdAuc1i91WrLpMtEcqoNWSqr5_7157CeKfY1F2W694NNL17"

# Start ngrok TCP tunnel for port 25565
echo "Starting ngrok TCP tunnel on port 25565..."
./ngrok authtoken $NGROK_AUTHTOKEN
./ngrok tcp 25565 &

# Wait for ngrok to initialize and capture the public URL
sleep 10

# Extract and display ngrok URL
NGROK_URL=$(curl --silent http://127.0.0.1:4040/api/tunnels | grep -oP 'tcp://\K[^"]+')
echo "ngrok is running at: $NGROK_URL"

# Start Minecraft server
echo "Starting Minecraft server..."
java -Xmx1024M -Xms1024M -jar $MC_SERVER_JAR nogui
