# GitHub MCP Integration Guide

This document explains how to set up GitHub integration in OpenResponses using the Model Context Protocol (MCP).

## Overview

OpenResponses supports GitHub integration through two MCP server configurations:

1. **Local Docker Server** (Recommended) - Runs locally using Docker for maximum compatibility
2. **Remote Server** (Deprecated) - GitHub's hosted MCP endpoint (currently has OpenAI API compatibility issues)

## Quick Start

### Option 1: Local Docker Server (Recommended)

This is the most reliable option as it runs GitHub's official MCP server locally via Docker.

#### Prerequisites

- Docker Desktop installed and running
- GitHub Personal Access Token (classic)

#### Setup Steps

1. **Run the automated setup script:**

   ```bash
   ./docker-github-mcp-setup.sh YOUR_GITHUB_TOKEN
   ```

2. **Manual setup (alternative):**

   ```bash
   # Pull the image
   docker pull ghcr.io/github/github-mcp-server:latest
   
   # Run the server
   docker run -d \
     --name github-mcp-server \
     -p 8080:8080 \
     -e GITHUB_PERSONAL_ACCESS_TOKEN="YOUR_TOKEN" \
     ghcr.io/github/github-mcp-server:latest
   ```

3. **Configure in OpenResponses:**
   - Open Settings
   - Find "github_local" in MCP servers
   - Enable the server
   - Set authentication to your GitHub token
   - Ensure the URL is set to `http://localhost:8080`

#### Available Tools

- Repository browsing and file access
- Issue management
- Pull request operations
- Code search and analysis
- Organization and user information

### Option 2: Remote Server (Not Recommended)

⚠️ **Warning**: The remote GitHub MCP server currently has compatibility issues with OpenAI's API and may return 400 Bad Request errors.

This option connects directly to GitHub's hosted MCP endpoint but is currently experiencing technical issues.

## Creating a GitHub Personal Access Token

1. Go to [GitHub Token Settings](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Set expiration (recommend 90 days or longer)
4. Select these scopes:
   - `repo` - Full control of private repositories
   - `read:org` - Read org and team membership, read org projects
   - `user:email` - Access user email addresses
5. Click "Generate token"
6. Copy the token (starts with `ghp_`)

⚠️ **Important**: Store this token securely - you won't be able to see it again.

## Troubleshooting

### Docker Server Issues

**Server won't start:**
```bash
# Check Docker status
docker info

# Check container logs
docker logs github-mcp-server

# Restart the container
docker restart github-mcp-server
```

**Port conflicts:**
If port 8080 is already in use, modify the port mapping:
```bash
docker run -p 8081:8080 ...  # Use port 8081 instead
```
Then update the server URL in OpenResponses settings to `http://localhost:8081`.

**Container management:**
```bash
# Stop the server
docker stop github-mcp-server

# Remove the container
docker rm github-mcp-server

# View all containers
docker ps -a
```

### Authentication Issues

**Token format errors:**

- Ensure your token starts with `ghp_` (classic tokens)
- Don't include "Bearer " prefix in OpenResponses - it's added automatically
- Copy the entire token without spaces or newlines

**Permission errors:**

- Verify your token has the required scopes
- Check that your token hasn't expired
- Ensure you have access to the repositories you're trying to access

### App Configuration Issues

**Server not appearing:**

- Restart the OpenResponses app
- Check that the server URL is exactly `http://localhost:8080`
- Ensure the server is enabled in settings

**No tools available:**

- Verify the Docker container is running: `docker ps`
- Check the container logs for errors: `docker logs github-mcp-server`
- Test server connectivity: `curl http://localhost:8080/health`

## Advanced Configuration

### Read-Only Mode

For enhanced security, you can run the server in read-only mode:

```bash
docker run -d \
  --name github-mcp-server \
  -p 8080:8080 \
  -e GITHUB_PERSONAL_ACCESS_TOKEN="YOUR_TOKEN" \
  -e MCP_SERVER_READ_ONLY="true" \
  ghcr.io/github/github-mcp-server:latest
```

### Custom Tool Selection

To limit which tools are available:

```bash
docker run -d \
  --name github-mcp-server \
  -p 8080:8080 \
  -e GITHUB_PERSONAL_ACCESS_TOKEN="YOUR_TOKEN" \
  -e MCP_SERVER_TOOLS="search_repositories,get_file_contents" \
  ghcr.io/github/github-mcp-server:latest
```

### Persistent Data

To persist server data across container restarts:

```bash
docker run -d \
  --name github-mcp-server \
  -p 8080:8080 \
  -e GITHUB_PERSONAL_ACCESS_TOKEN="YOUR_TOKEN" \
  -v github-mcp-data:/app/data \
  ghcr.io/github/github-mcp-server:latest
```

## Security Considerations

- **Token Storage**: OpenResponses stores your GitHub token securely in the iOS Keychain
- **Local Server**: Your token is only shared with the local Docker container
- **Network Security**: The Docker server runs locally and doesn't expose your token to external services
- **Scope Limitation**: Only request the minimum required token scopes for your use case

## Example Usage

Once configured, you can use GitHub tools in your conversations:

"Search my repositories for files containing authentication logic"

"Show me the latest pull requests in my main project"

"Create an issue in my iOS app repository about the MCP integration"

"What files were changed in the last commit to the main branch?"

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Docker container logs: `docker logs github-mcp-server`
3. Verify your GitHub token has the required permissions
4. Ensure Docker Desktop is running and up to date
5. Test the server directly: `curl http://localhost:8080/health`

For additional help, consult the [GitHub MCP Server repository](https://github.com/github/github-mcp-server).