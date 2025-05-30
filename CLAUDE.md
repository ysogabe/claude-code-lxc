# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains configuration and setup documentation for Claude Code development environments:
- **docs/claude-code-microservices-config.md**: Comprehensive guide for microservices development with Claude Code
- **docs/claude_code_container_setup.md**: LXC container setup instructions for isolated Claude Code environments

## Common Commands

### LXC Container Management
```bash
# Create and start Claude Code container
lxc launch ubuntu:22.04 claude-code-container --profile claude-code-dev

# Container operations
lxc start claude-code-container
lxc stop claude-code-container
lxc snapshot claude-code-container claude-code-clean-install
lxc restore claude-code-container claude-code-clean-install

# Access container
lxc exec claude-code-container -- sudo -u ubuntu bash
ssh claude-code-dev
```

### Claude Code Operations
```bash
# Inside Claude Code session
/mcp                    # Check MCP server status
/allowed-tools          # List permitted tools
/init                   # Initialize project
claude --mcp-debug      # Debug MCP connections
```

### Custom Commands (defined in .claude/commands/)
```bash
/microservice-deploy <service-name>:<version>
/service-health-check <service-name>
/api-test-suite <arguments>
/troubleshoot-service <arguments>
/setup-new-service <service-name>
/service-monitoring <service-name>
```

## Architecture and Configuration Structure

### Configuration Hierarchy (Priority Order)
1. **Enterprise Policy Settings**: `/etc/claude-code/policies.json`
2. **User Settings**: `~/.claude/settings.json`
3. **Project Settings**: `.claude/settings.json`
4. **Local Project Settings**: `.claude/settings.local.json`
5. **MCP Configuration**: `~/.claude.json` (global), `.claude.json` (project)

### MCP Server Architecture
The setup utilizes multiple MCP (Model Context Protocol) servers:

- **filesystem**: Provides access to directories outside the current project
- **firecrawl-mcp**: Web scraping with retry logic and credit monitoring
- **github**: GitHub API integration
- **postgres/redis**: Database connections
- **docker/kubernetes**: Container orchestration
- **puppeteer/playwright**: Browser automation for E2E testing

### Permission System
Permissions use pattern matching:
- `Bash(command:*)` - Allow specific commands
- `Edit`, `Read`, `WebFetch` - File and web operations
- Deny patterns prevent dangerous operations

### Container Environment
- **Base**: Ubuntu 22.04 LTS in LXC
- **Resources**: 4 CPU, 16GB RAM, 80GB storage
- **Network**: Bridge via lxdbr0
- **Access**: SSH key-based authentication
- **Pre-installed**: Node.js, Python, Rust, Docker, development tools