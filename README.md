# Claude Code LXC Container Setup

Configuration guides and tools for running Claude Code in LXC container environments.

## Overview

This repository contains the following key documents and tools:

1. **docs/claude_code_container_setup.md** - LXC container setup procedures for running Claude Code via SSH from VS Code
2. **docs/claude-code-microservices-config.md** - Detailed configuration guide for Claude Code specialized in microservices development
3. **docs/external-access-design.md** - Design document for enabling SSH connections from external networks
4. **profiles/** - Reusable LXC profile templates
5. **claude-config/** - Claude Code configuration templates
6. **docs/** - Public documentation and design materials

## Features

- 🐳 **Containerized Development Environment** - Isolated and secure execution environment using LXC containers
- 🔧 **Microservices Ready** - Configuration for Docker, Kubernetes, and various MCP servers
- 🔒 **Security Focused** - Detailed permission settings and SSH security hardening
- 📦 **MCP (Model Context Protocol) Support** - Integration with filesystem, GitHub, PostgreSQL, Docker, etc.
- 💻 **VS Code Integration** - Comfortable development experience with Remote-SSH extension
- 🔗 **GitHub CLI (gh) Integration** - Direct GitHub operations from command line
- 🌐 **mDNS Support** - Easy container access via `.local` domains
- 🌍 **External SSH Connection Support** - Dynamic port allocation (2222-2299) with port conflict avoidance
- ⚡ **Fast Setup** - Container construction completed in ~2 minutes with cloud-init optimization
- 🔐 **Flexible Authentication** - Support for SSH key, password, and hybrid authentication

## Quick Start

### Prerequisites

- Ubuntu 22.04 or later host system
- LXD/LXC installed
- Sufficient system resources (Recommended: 4 CPU cores, 16GB RAM, 80GB storage)

### Basic Setup

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/claude_code_lxc.git
cd claude_code_lxc

# 2. Apply profiles and create container
cd profiles
./apply-profile.sh -n claude-code-dev  # Standard profile
# or
./apply-profile.sh -n claude-code-external  # External SSH access profile

# 3. Create container
lxc launch ubuntu:22.04 claude-code-container --profile claude-code-dev

# 4. Install additional tools (optional)
lxc exec claude-code-container -- bash < setup-scripts/additional-tools.sh

# 5. Apply Claude Code configuration (optional)
lxc exec claude-code-container -- bash
cd /home/ubuntu
git clone https://github.com/yourusername/claude_code_lxc.git
cd claude_code_lxc/claude-config
./apply-config.sh microservices-full
```

## Documentation Structure

### profiles/
LXC profile definitions and helper scripts:
- `claude-code-dev.yaml` - Standard development environment profile (4 CPU, 16GB RAM)
- `claude-code-dev-auto.yaml` - Profile with automatic MCP/permission configuration
- `claude-code-minimal.yaml` - Minimal configuration profile (2 CPU, 8GB RAM)
- `claude-code-external.yaml` - External SSH access profile (includes LXD Proxy Device configuration)
- `apply-profile.sh` - Profile application helper script
- `README.md` - Detailed profile documentation

### claude-config/
Claude Code configuration templates and helper scripts:
- `microservices-full.json` - Full-featured configuration for microservices development
- `web-development.json` - Standard configuration for web development
- `data-science.json` - Configuration for data science
- `minimal.json` - Minimal configuration
- `apply-config.sh` - Configuration application helper script
- `README.md` - Detailed configuration template documentation

### Key Documents

#### docs/claude_code_container_setup.md
Comprehensive guide from LXC container construction to operation:
- LXC profile creation and configuration
- Container initial setup and SSH configuration (key auth, password auth, hybrid auth)
- Claude Code environment setup
- VS Code Remote-SSH connection configuration
- Development tools installation
- Profile modification and update procedures
- Troubleshooting

#### docs/external-access-design.md
Design for achieving SSH connections from external networks:
- Port forwarding configuration using LXD Proxy Device
- Security configuration (fail2ban, UFW)
- VS Code Remote-SSH configuration examples

#### docs/claude-code-microservices-config.md
Detailed configuration required for microservices development:
- Configuration file hierarchy
- Detailed permission settings
- MCP server configuration and utilization
- Custom command creation
- Environment variables and alias configuration
- FireCrawl MCP server configuration

### docs/
Public documentation:
- `external-access-design-considerations.md` - External access design considerations
- `profile-improvement-plan.md` - Profile improvement plan
- `github-publish-checklist.md` - GitHub publish checklist
- `README.md` - Documentation overview

## Key Features

### MCP Server Integration
- **filesystem** - Access to files outside the project
- **github** - GitHub API integration
- **postgres/redis** - Database connections
- **docker/kubernetes** - Container orchestration
- **puppeteer/playwright** - Browser automation

### Security Features
- Granular permission control
- SSH key authentication
- Firewall configuration
- Dangerous command blocking

### Development Support Features
- Custom commands (deploy, health check, etc.)
- Convenient alias settings
- Automatic backup and snapshots
- Resource monitoring

## Usage Examples

### Microservice Deployment
```bash
claude
> /microservice-deploy user-service:v1.2.3
```

### Health Check Execution
```bash
claude
> /service-health-check payment-service
```

### New Service Creation
```bash
claude
> /setup-new-service notification-service
```

## Troubleshooting

If you encounter issues, please check the following:

1. **SSH Connection Issues** - Refer to Section 10 of `docs/claude_code_container_setup.md`
2. **External SSH Connection Issues** - Refer to `docs/external-access-design.md` and `profiles/claude-code-external.yaml`
3. **MCP Connection Errors** - Refer to Section 8 of `docs/claude-code-microservices-config.md`
4. **Permission Errors** - Check configuration file permission settings
5. **cloud-init Related Issues** - Check cloud-init configuration in profile files
6. **GitHub CLI Authentication Issues** - Refer to Section 11 of `docs/claude_code_container_setup.md`

## Contributing

Pull requests and improvement suggestions are welcome. For major changes, please create an issue first for discussion.

## Latest Updates

- Added external SSH connection support profile (`claude-code-external.yaml`)
- Implemented secure external access using LXD Proxy Device
- Expanded SSH authentication options (key auth, password auth, hybrid)
- Optimized cloud-init configuration for reduced build time (~2 minutes)
- Integrated GitHub CLI and mDNS support
- Organized documentation and moved public documents to docs folder

## Changelog

For project change history, see [CHANGELOG.md](./CHANGELOG.md).

## License

This project is released under the [MIT License](./LICENSE).

## Author

Yoshio

## Related Links

- [Claude Code Official Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [LXD Official Documentation](https://documentation.ubuntu.com/lxd/)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)