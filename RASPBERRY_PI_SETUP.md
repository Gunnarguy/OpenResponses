# 🍓 Official Notion MCP on Your Raspberry Pi 4B

## The Absolute Simplest Way (One Command!)

### On Your Raspberry Pi:

```bash
docker run -d \
  --name notion-mcp \
  --restart unless-stopped \
  -p 8080:3000 \
  -e NOTION_TOKEN=<YOUR_NOTION_TOKEN_HERE> \
  mcp/notion \
  npx @notionhq/notion-mcp-server --transport http --port 3000
```

**That's it!** The **official Notion MCP server** is now running with:
- ✅ Official Docker Hub image (`mcp/notion`)
- ✅ Built-in HTTP transport 
- ✅ Optimized for AI agents
- ✅ Latest features from Notion team

---

## Finding Your Raspberry Pi's IP Address

On your Pi, run:
```bash
hostname -I
```

You'll see something like: `192.168.1.100` (your local IP)

---

## 📱 In Your iOS App (OpenResponses)

1. **Open OpenResponses**
2. **Settings** → **MCP Connectors** → **"Connect Your Apps"**
3. **Tap Notion** (orange 🖥️ badge)
4. **Enter**:

   **Server Label:**
   ```
   My Notion Pi
   ```

   **Server URL:** (replace `192.168.1.100` with YOUR Pi's IP)
   ```
   http://192.168.1.100:8080/mcp
   ```

   **Authorization Token:** (Get from Pi logs)
   ```
   docker logs notion-mcp | grep "Bearer"
   ```

   **Require Approval:**
   ```
   always (recommended)
   ```

5. **Tap Save**

---

## ✅ Testing

In the chat, type:
```
List my Notion databases
```

You should see your databases!

---

## 🔧 Useful Commands

**Check if server is running:**
```bash
docker ps | grep notion-mcp
```

**View server logs:**
```bash
docker logs -f notion-mcp
```

**Restart server:**
```bash
docker restart notion-mcp
```

**Stop server:**
```bash
docker stop notion-mcp
```

**Remove server:**
```bash
docker rm -f notion-mcp
```

---

## ⚠️ Important Notes

1. **Same Network Required**: Your iPhone and Raspberry Pi must be on the same WiFi network
2. **HTTP vs HTTPS**: Since it's local, we use `http://` not `https://`
3. **IP Address Changes**: If your Pi's IP changes, update the Server URL in the app
4. **Make IP Static** (optional but recommended):
   - In your router settings, assign a static IP to your Pi
   - Or use `raspberrypi.local:8080/sse` as the URL (if mDNS works on your network)

---

## 🚀 Alternative: Using the Setup Script

If you want a more managed setup with docker-compose:

1. **Copy files to your Pi:**
   ```bash
   # On your Mac (from the OpenResponses directory):
   scp docker-compose.yml setup-pi-mcp.sh pi@raspberrypi.local:~/notion-mcp/
   ```

2. **On your Pi:**
   ```bash
   cd ~/notion-mcp
   chmod +x setup-pi-mcp.sh
   ./setup-pi-mcp.sh
   ```

   This will:
   - Check Docker installation
   - Download the Notion MCP server
   - Start it with docker-compose
   - Give you the exact URL to use

---

## 🎯 Why This is Better Than Cloud

✅ **Full Control**: Your data stays on your network
✅ **No Monthly Costs**: Free forever
✅ **Always Available**: As long as your Pi is on
✅ **Fast**: No internet latency
✅ **Private**: Never leaves your network

---

## 📊 Checking It Works

**On your Pi, test locally:**
```bash
curl http://localhost:8080
```

You should see some server info.

**From your Mac (on same network), test remotely:**
```bash
curl http://192.168.1.100:8080
```
(Replace with your Pi's IP)

If both work, your iPhone will work too!

---

## 🐛 Troubleshooting

### "Connection refused" in app
- Check Pi is on and Docker container is running: `docker ps`
- Verify iPhone and Pi are on same WiFi
- Try `http://raspberrypi.local:8080/sse` instead of IP

### "Server not responding"
- Check logs: `docker logs notion-mcp`
- Restart: `docker restart notion-mcp`
- Check firewall isn't blocking port 8080

### "Authentication failed"
- Make sure you shared Notion pages with your integration
- Verify token is correct
- Token must start with `secret_` or `ntn_`

### Can't find Pi's IP
```bash
# On Pi:
hostname -I

# Or on Mac (scan network):
arp -a | grep raspberry
```

---

## 🔄 Making It Permanent

The container will automatically restart when:
- You reboot the Pi
- Docker restarts
- The container crashes

To make it survive Pi reboots, ensure Docker starts on boot:
```bash
sudo systemctl enable docker
```

---

## 💡 Pro Tip: Use mDNS

If your network supports mDNS (most do), you can use:
```
http://raspberrypi.local:8080/sse
```

Instead of the IP address. This way it works even if the IP changes!

Try it in your browser first to see if it resolves.

---

## 🎉 You're Done!

Your Notion MCP server is running on your Raspberry Pi, accessible from your iPhone on your local network. Query your Notion workspace through natural language in your iOS app! 🚀
