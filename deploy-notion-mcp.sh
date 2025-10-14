#!/bin/bash
# Notion MCP Server Deployment Script
# This will help you deploy to Railway, Fly.io, or run locally

set -e

echo "🚀 Notion MCP Server Deployment Helper"
echo "========================================"
echo ""
echo "Choose your deployment method:"
echo "1) Railway (easiest, free tier, 1-click)"
echo "2) Fly.io (flexible, good free tier)"
echo "3) Local testing with ngrok (for development)"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
  1)
    echo ""
    echo "📦 RAILWAY DEPLOYMENT"
    echo "===================="
    echo ""
    echo "Step 1: Go to https://railway.app and sign up/login"
    echo "Step 2: Click 'New Project' → 'Deploy from GitHub repo'"
    echo "Step 3: If you haven't already, fork this repo:"
    echo "        https://github.com/modelcontextprotocol/servers"
    echo ""
    echo "Step 4: Select your forked 'servers' repository"
    echo ""
    echo "Step 5: Configure the deployment:"
    echo "        Root Directory: src/notion"
    echo ""
    echo "Step 6: Add Environment Variables:"
    echo "        NOTION_API_KEY = <YOUR_NOTION_TOKEN_HERE>"
    echo "        PORT = 8080"
    echo ""
    echo "Step 7: Click 'Deploy' and wait ~2 minutes"
    echo ""
    echo "Step 8: Once deployed, Railway will show you a URL like:"
    echo "        https://notion-mcp-production-xyz.up.railway.app"
    echo ""
    echo "✨ Your Server URL will be:"
    echo "   https://your-railway-url.up.railway.app/sse"
    echo ""
    echo "📱 In the OpenResponses app, enter:"
    echo "   Server URL: https://your-railway-url.up.railway.app/sse"
    echo "   Token: <YOUR_NOTION_TOKEN_HERE>"
    echo ""
    ;;
    
  2)
    echo ""
    echo "✈️  FLY.IO DEPLOYMENT"
    echo "===================="
    echo ""
    echo "Installing flyctl if needed..."
    if ! command -v flyctl &> /dev/null; then
      curl -L https://fly.io/install.sh | sh
      export FLYCTL_INSTALL="/Users/$USER/.fly"
      export PATH="$FLYCTL_INSTALL/bin:$PATH"
    fi
    
    echo "Cloning Notion MCP server..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://github.com/modelcontextprotocol/servers.git
    cd servers/src/notion
    
    echo "Creating fly.toml..."
    cat > fly.toml << 'EOF'
app = "notion-mcp-openresponses"

[build]

[env]
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0

[[vm]]
  memory = '256mb'
  cpu_kind = 'shared'
  cpus = 1
EOF
    
    echo ""
    echo "🔐 Logging into Fly.io..."
    flyctl auth login
    
    echo ""
    echo "🚀 Launching app..."
    flyctl launch --no-deploy --copy-config --name notion-mcp-openresponses
    
    echo ""
    echo "🔑 Setting Notion API key..."
    read -p "Enter your Notion API token: " NOTION_TOKEN
    flyctl secrets set NOTION_API_KEY=$NOTION_TOKEN
    
    echo ""
    echo "📦 Deploying..."
    flyctl deploy
    
    echo ""
    echo "✅ Deployment complete!"
    echo ""
    echo "Your server URL is:"
    flyctl info | grep Hostname | awk '{print "https://"$2"/sse"}'
    echo ""
    echo "📱 In the OpenResponses app, enter:"
    echo "   Server URL: (the URL shown above)"
    echo "   Token: <YOUR_NOTION_TOKEN_HERE>"
    echo ""
    ;;
    
  3)
    echo ""
    echo "💻 LOCAL TESTING WITH NGROK"
    echo "==========================="
    echo ""
    echo "Installing dependencies..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://github.com/modelcontextprotocol/servers.git
    cd servers/src/notion
    
    echo "Installing Node.js dependencies..."
    npm install
    
    echo ""
    echo "🚀 Starting local server..."
    echo "   (Press Ctrl+C to stop)"
    echo ""
    
    read -p "Enter your Notion API token: " NOTION_TOKEN
    
    # Start server in background
    NOTION_API_KEY=$NOTION_TOKEN npm start &
    SERVER_PID=$!
    
    echo "Server started (PID: $SERVER_PID)"
    sleep 3
    
    echo ""
    echo "📡 Setting up ngrok tunnel..."
    
    # Check if ngrok is installed
    if ! command -v ngrok &> /dev/null; then
      echo "ngrok not found. Install it from: https://ngrok.com/download"
      echo ""
      echo "After installing, run:"
      echo "  ngrok http 8080"
      echo ""
      echo "Then use the HTTPS URL shown (e.g., https://abc123.ngrok-free.app/sse)"
      kill $SERVER_PID
      exit 1
    fi
    
    echo "Starting ngrok..."
    ngrok http 8080 &
    NGROK_PID=$!
    
    sleep 2
    
    echo ""
    echo "✅ Server is running!"
    echo ""
    echo "🌐 Visit http://localhost:4040 to see your ngrok URL"
    echo ""
    echo "Your server URL will be something like:"
    echo "   https://abc123.ngrok-free.app/sse"
    echo ""
    echo "📱 In the OpenResponses app, enter:"
    echo "   Server URL: (the HTTPS URL from ngrok)/sse"
    echo "   Token: <YOUR_NOTION_TOKEN_HERE>"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""
    
    # Wait for user interrupt
    trap "kill $SERVER_PID $NGROK_PID 2>/dev/null; exit" INT TERM
    wait
    ;;
    
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "🎉 Next Steps:"
echo "1. Open OpenResponses app"
echo "2. Go to Settings → MCP Connectors"
echo "3. Tap 'Connect Your Apps'"
echo "4. Tap Notion (look for orange server badge 🖥️)"
echo "5. Enter your Server URL and Token"
echo "6. Test with: 'List my Notion databases'"
echo ""
