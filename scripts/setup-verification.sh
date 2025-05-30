#!/bin/bash
# Claude Code Container Setup Verification Script

CONTAINER_NAME="${1:-claude-code-container}"

echo "=== Claude Code Container Setup Verification ==="
echo "Container: $CONTAINER_NAME"
echo "Date: $(date)"
echo ""

# Check if container exists and is running
echo "1. Container Status Check"
if lxc list --format json | jq -r '.[].name' | grep -q "^${CONTAINER_NAME}$"; then
    STATE=$(lxc list $CONTAINER_NAME --format json | jq -r '.[0].state.status')
    echo "   ✓ Container exists (State: $STATE)"
    if [ "$STATE" != "Running" ]; then
        echo "   ⚠ Container is not running. Starting..."
        lxc start $CONTAINER_NAME
        sleep 10
    fi
else
    echo "   ✗ Container does not exist"
    exit 1
fi

# Check essential services
echo ""
echo "2. Essential Services Check"
for service in ssh avahi-daemon docker; do
    if lxc exec $CONTAINER_NAME -- systemctl is-active $service >/dev/null 2>&1; then
        echo "   ✓ $service is active"
    else
        echo "   ✗ $service is not active"
    fi
done

# Check essential commands
echo ""
echo "3. Essential Commands Check"
for cmd in claude git node npm docker gh; do
    if lxc exec $CONTAINER_NAME -- which $cmd >/dev/null 2>&1; then
        VERSION=$(lxc exec $CONTAINER_NAME -- $cmd --version 2>/dev/null | head -1 || echo "version check not supported")
        echo "   ✓ $cmd found: $VERSION"
    else
        echo "   ✗ $cmd not found"
    fi
done

# Check directory structure
echo ""
echo "4. Directory Structure Check"
for dir in /home/ubuntu/workspace /home/ubuntu/projects /home/ubuntu/.ssh; do
    if lxc exec $CONTAINER_NAME -- test -d $dir; then
        OWNER=$(lxc exec $CONTAINER_NAME -- stat -c '%U:%G' $dir)
        echo "   ✓ $dir exists (Owner: $OWNER)"
    else
        echo "   ✗ $dir does not exist"
    fi
done

# Check SSH configuration
echo ""
echo "5. SSH Configuration Check"
SSH_CONFIG=$(lxc exec $CONTAINER_NAME -- grep -E "^(PasswordAuthentication|PubkeyAuthentication|PermitRootLogin)" /etc/ssh/sshd_config 2>/dev/null)
if [ -n "$SSH_CONFIG" ]; then
    echo "   SSH Configuration:"
    echo "$SSH_CONFIG" | sed 's/^/     /'
else
    echo "   ⚠ Could not read SSH configuration"
fi

# Check network connectivity
echo ""
echo "6. Network Connectivity Check"
CONTAINER_IP=$(lxc list $CONTAINER_NAME --format json | jq -r '.[0].state.network.eth0.addresses[] | select(.family=="inet") | .address')
if [ -n "$CONTAINER_IP" ]; then
    echo "   ✓ Container IP: $CONTAINER_IP"
    if ping -c 1 -W 2 $CONTAINER_IP >/dev/null 2>&1; then
        echo "   ✓ Container is reachable via ping"
    else
        echo "   ✗ Container is not reachable via ping"
    fi
else
    echo "   ✗ No IP address found"
fi

# Check mDNS
echo ""
echo "7. mDNS Configuration Check"
HOSTNAME=$(lxc exec $CONTAINER_NAME -- hostname 2>/dev/null)
if [ -n "$HOSTNAME" ]; then
    echo "   ✓ Hostname: $HOSTNAME"
    if avahi-browse -a -t 2>/dev/null | grep -q "$HOSTNAME"; then
        echo "   ✓ mDNS broadcasting as $HOSTNAME.local"
    else
        echo "   ⚠ mDNS not detected (this may be normal if avahi-browse is not installed on host)"
    fi
fi

# Check Claude Code configuration
echo ""
echo "8. Claude Code Configuration Check"
if lxc exec $CONTAINER_NAME -- test -f /home/ubuntu/.claude.json; then
    echo "   ✓ MCP configuration file exists"
    MCP_SERVERS=$(lxc exec $CONTAINER_NAME -- jq -r '.mcpServers | keys[]' /home/ubuntu/.claude.json 2>/dev/null | tr '\n' ' ')
    if [ -n "$MCP_SERVERS" ]; then
        echo "   ✓ MCP servers configured: $MCP_SERVERS"
    fi
else
    echo "   ⚠ MCP configuration file not found"
fi

if lxc exec $CONTAINER_NAME -- test -f /home/ubuntu/.claude/settings.json; then
    echo "   ✓ Permissions configuration file exists"
else
    echo "   ⚠ Permissions configuration file not found"
fi

# Check environment variables
echo ""
echo "9. Environment Variables Check"
ENV_VARS="CLAUDE_CODE_WORKSPACE CLAUDE_CODE_PROJECTS NODE_ENV"
for var in $ENV_VARS; do
    VALUE=$(lxc exec $CONTAINER_NAME -- sudo -u ubuntu bash -c "source ~/.bashrc && echo \$$var" 2>/dev/null)
    if [ -n "$VALUE" ]; then
        echo "   ✓ $var is set: $VALUE"
    else
        echo "   ⚠ $var is not set"
    fi
done

# Summary
echo ""
echo "=== Verification Summary ==="
echo "Container $CONTAINER_NAME is set up and ready for Claude Code development."
echo ""
echo "To connect:"
echo "  SSH: ssh ubuntu@$CONTAINER_IP"
if [ -n "$HOSTNAME" ]; then
    echo "  mDNS: ssh ubuntu@${HOSTNAME}.local"
fi
echo "  VS Code: Use Remote-SSH extension with host 'claude-code-dev'"
echo ""
echo "Next steps for full development environment:"
echo "  1. Run additional tools installation script from container setup guide"
echo "  2. Configure Claude Code with 'claude' command"
echo "  3. Set up MCP servers and permissions"
echo ""
echo "=== Verification Complete ===">