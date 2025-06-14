# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **BREAKING**: Upgraded base LXC image from Ubuntu 22.04 to Ubuntu 24.04.2 LTS
- Improved cloud-init waiting mechanism with 60-second timeout before fallback
- Enhanced error handling in setup scripts with better timeout management

### Fixed
- Fixed cloud-init status --wait hanging in LXC containers
- Implemented hybrid approach for cloud-init waiting with automatic fallback to polling
- UFW firewall configuration now uses dynamic LXC network detection instead of hardcoded wildcards
- Fixed Python package installation errors in Ubuntu 24.04 due to PEP 668 externally-managed-environment
- Replaced legacy Python package management (pip, pipenv, poetry) with modern uv package manager

### Added
- Ubuntu 24.04.2 LTS support with Linux kernel 6.8/6.11 (HWE)
- Extended LTS support until 2034 (previously 2032)
- Improved security with latest package versions
- Smaller container image size (258MiB vs 434MiB, ~40% reduction)

### Security
- Updated to latest OpenSSH 9.6p1 with enhanced security features
- fail2ban 1.0.2 with improved Python 3 compatibility
- UFW 0.36.2 with enhanced firewall management
- Latest security patches and ESM Apps availability

## [0.1.0] - 2025-05-30

### Added
- Initial GitHub public release
- LXC container management tools for development environments
- Automated container setup script with progress tracking
- Dynamic port allocation for external SSH access (port range 2222-2299)
- Multiple profile support: claude-code-dev, claude-code-minimal, claude-code-external
- Cloud-init optimization for faster deployment (setup time reduced to ~2 minutes)
- Comprehensive MCP (Model Context Protocol) server configuration
- GitHub Actions self-hosted runner configuration
- mDNS support for easy container access via .local domains
- Hybrid authentication support (SSH key and password)
- Automatic security hardening with fail2ban and UFW
- Resource allocation customization (CPU, RAM, storage)
- English and Japanese documentation

### Changed
- Documentation structure reorganized from reports/ to docs/
- Sensitive information replaced with generic placeholders
- Setup time reduced by 66% (from 6+ minutes to ~2 minutes)
- Package installation optimized for minimal redundancy

### Fixed
- Cloud-init YAML formatting errors
- Package duplication issues in cloud-init configuration
- SSH key generation and permission issues
- OVS network configuration errors
- mDNS name resolution problems
- Non-interactive environment warnings in scripts
- Heredoc syntax errors in shell scripts
- Timeout handling in automated scripts

### Security
- Internal test results and implementation plans moved to private reports/
- Container configuration sanitized for public sharing
- SSH security enhanced with MaxAuthTries and AllowUsers settings
- Firewall rules properly configured for container isolation
- Sensitive paths and IP addresses replaced with generic examples

### Performance
- 100% success rate for basic container creation
- Sub-2ms network latency between host and containers
- Minimal resource overhead with optimized profiles
- Concurrent container deployment support

### Documentation
- Comprehensive setup guides for LXC containers
- External SSH access design documentation
- Profile improvement plans and best practices
- GitHub publish checklist for open-source preparation
- Migration guides for existing environments