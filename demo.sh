#!/usr/bin/env bash
# Copyright (c) 2024. Jet Propulsion Laboratory. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# This script launches the ROSA demo in Docker

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
    echo "Error: Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Set default headless mode
HEADLESS=${HEADLESS:-false}
DEVELOPMENT=${DEVELOPMENT:-false}

# Initialize X11 related variables
DOCKER_X11_ARGS=""
ENABLE_X11=false

# Check if running on macOS
if [ "$(uname)" = "Darwin" ]; then
    # Check if XQuartz is installed
    if ! command -v xquartz &>/dev/null && ! [ -d "/Applications/XQuartz.app" ]; then
        echo "XQuartz is not installed. Installing with Homebrew..."
        if ! command -v brew &>/dev/null; then
            echo "Homebrew is not installed. Please install Homebrew first."
            exit 1
        fi
        brew install --cask xquartz
        echo "Please log out and log back in for XQuartz settings to take effect."
        exit 1
    fi

    # Start XQuartz if not running
    if ! pgrep -x "Xquartz" >/dev/null; then
        echo "Starting XQuartz..."
        open -a XQuartz
        # Wait for XQuartz to start
        sleep 5
    fi

    # Configure XQuartz for network connections
    defaults write org.xquartz.X11 nolisten_tcp 0
    defaults write org.xquartz.X11 app_to_run /usr/bin/true

    # Restart XQuartz to apply settings if needed
    killall Xquartz 2>/dev/null
    open -a XQuartz
    sleep 3

    # Get IP address
    IP_ADDRESS=$(ipconfig getifaddr en0 || ipconfig getifaddr en1)
    if [ -z "$IP_ADDRESS" ]; then
        echo "Could not determine IP address. Using localhost."
        IP_ADDRESS="127.0.0.1"
    fi

    # Set up X11 forwarding
    ENABLE_X11=true
    xhost + $IP_ADDRESS >/dev/null 2>&1
    DOCKER_X11_ARGS="-e DISPLAY=$IP_ADDRESS:0 -v /tmp/.X11-unix:/tmp/.X11-unix"

    echo "X11 forwarding configured with display $IP_ADDRESS:0"
else
    # Handle other operating systems here
    echo "This script is optimized for macOS. You may need to modify it for your OS."
    exit 1
fi

# Build and run the Docker container
CONTAINER_NAME="rosa-turtlesim-demo"

# Detect Mac architecture
if [ "$(uname -m)" = "arm64" ]; then
    echo "Detected Apple Silicon (ARM64) architecture"
    PLATFORM_ARG="--platform linux/arm64"
else
    echo "Detected Intel (AMD64) architecture"
    PLATFORM_ARG=""
fi

echo "Building the $CONTAINER_NAME Docker image..."
docker build $PLATFORM_ARG --build-arg DEVELOPMENT=$DEVELOPMENT -t $CONTAINER_NAME -f Dockerfile . || {
    echo "Error: Docker build failed"
    exit 1
}

echo "Running the Docker container..."
docker run -it --rm --name $CONTAINER_NAME \
    $DOCKER_X11_ARGS \
    -e HEADLESS=$HEADLESS \
    -e DEVELOPMENT=$DEVELOPMENT \
    -v "$PWD/src":/app/src \
    -v "$PWD/tests":/app/tests \
    $PLATFORM_ARG \
    $CONTAINER_NAME

# Cleanup X11 permissions
if [ "$ENABLE_X11" = true ]; then
    xhost - $IP_ADDRESS >/dev/null 2>&1
fi

exit 0
