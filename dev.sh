#!/bin/bash

# Script to easily start the development server using Docker Compose

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose is not installed."
    exit 1
fi

# Check if docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Default command is 'up'
COMMAND=${1:-up}

case "$COMMAND" in
    up)
        echo "Starting development server..."
        docker-compose -f docker-compose.dev.yml up
        ;;
    down)
        echo "Stopping development server..."
        docker-compose -f docker-compose.dev.yml down
        ;;
    logs)
        echo "Showing logs..."
        docker-compose -f docker-compose.dev.yml logs -f
        ;;
    detach|background)
        echo "Starting development server in detached mode..."
        docker-compose -f docker-compose.dev.yml up -d
        ;;
    *)
        echo "Usage: $0 [up|down|logs|detach]"
        echo ""
        echo "Commands:"
        echo "  up      - Start the development server (default)"
        echo "  down    - Stop the development server"
        echo "  logs    - View the logs"
        echo "  detach  - Start in detached mode (background)"
        ;;
esac
