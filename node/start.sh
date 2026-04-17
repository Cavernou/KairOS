#!/bin/bash
# KairOS Node Launcher
# Double-click to start the node server

cd "$(dirname "$0")"

# Check if config file exists
if [ ! -f "config.yaml" ]; then
    echo "Config file not found. Creating from example..."
    cp config.example.yaml config.yaml
    echo "Please edit config.yaml with your settings before starting the node."
    echo "Press Enter to exit..."
    read
    exit 1
fi

# Start the node
echo "Starting KairOS Node..."
./kairos-node -config config.yaml
