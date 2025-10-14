#!/bin/bash
# Setup Notion MCP Server for Raspberry Pi 4B
# Run this script to set everything up

set -e

echo "🍓 Notion MCP Server - Raspberry Pi Setup"
echo "=========================================="
echo ""

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  Warning: This doesn't appear to be a Raspberry Pi"
    echo "   Continuing anyway..."
    echo ""
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first:"
    echo "   curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "   sudo sh get-docker.sh"
    echo "   sudo usermod -aG docker $USER"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y docker-compose
fi

echo "✅ Docker is installed"
echo ""

# Create directory for the MCP server source
echo "📦 Downloading Notion MCP server source..."
mkdir -p notion-mcp-src
cd notion-mcp-src

# Clone only the notion server directory
if [ ! -d "servers" ]; then
    git clone --depth 1 --filter=blob:none --sparse https://github.com/modelcontextprotocol/servers.git
    cd servers
    git sparse-checkout set src/notion
    cd ..
fi

# Copy the notion source to our directory
cp -r servers/src/notion/* .
rm -rf servers

cd ..

echo "✅ Source code ready"
echo ""

# Get Raspberry Pi's local IP address
PI_IP=$(hostname -I | awk '{print $1}')

echo "🚀 Starting Notion MCP server with Docker Compose..."
docker-compose up -d

echo ""
echo "⏳ Waiting for server to start (15 seconds)..."
sleep 15

# Test if server is responding
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo ""
    echo "✅ Server is running!"
else
    echo ""
    echo "⚠️  Server might still be starting. Check with:"
    echo "   docker-compose logs -f"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 NOTION MCP SERVER IS READY!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 IN YOUR iOS APP (OpenResponses):"
echo ""
echo "   Server Label: My Notion Pi"
echo ""
echo "   Server URL: http://${PI_IP}:8080/sse"
echo ""
echo "   Token: <YOUR_NOTION_TOKEN_HERE>"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  IMPORTANT: Your iPhone must be on the same WiFi network"
echo "   as your Raspberry Pi for this to work!"
echo ""
echo "🔍 Useful commands:"
echo "   docker-compose logs -f     # View server logs"
echo "   docker-compose restart     # Restart server"
echo "   docker-compose stop        # Stop server"
echo "   docker-compose down        # Stop and remove containers"
echo ""
echo "🌐 Your Raspberry Pi IP: ${PI_IP}"
echo "   (If this changes, update the Server URL in the app)"
echo ""
