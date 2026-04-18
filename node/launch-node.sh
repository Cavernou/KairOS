#!/bin/bash

# KairOS Node Launcher
# Double-click this script to start the KairOS Node

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the node directory
cd "$SCRIPT_DIR"

# Check if config file exists
if [ ! -f "config.yaml" ]; then
    echo "Error: config.yaml not found in $SCRIPT_DIR"
    echo "Please copy config.example.yaml to config.yaml and configure it"
    echo ""
    echo "You can do this with:"
    echo "  cp config.example.yaml config.yaml"
    exit 1
fi

# Check if node binary exists
if [ ! -f "kairos-node" ]; then
    echo "Error: kairos-node binary not found in $SCRIPT_DIR"
    echo "Please build the node first with:"
    echo "  go build ./cmd/kairos-node"
    exit 1
fi

# Start the node
echo "Starting KairOS Node..."
echo "Press Ctrl+C to stop"
echo ""

./kairos-node -config config.yaml
