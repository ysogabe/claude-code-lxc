#!/bin/bash

# Claude Code LXC Container Automated Setup Script
# This script automates the container creation process up to section 2 of claude_code_container_setup.md

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default configuration
DEFAULT_CONTAINER_NAME="claude-code-container"
DEFAULT_PROFILE_NAME="claude-code-dev"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse command line arguments
show_usage() {
    echo "Usage: $0 [CONTAINER_NAME] [PROFILE_NAME] [--external]"
    echo ""
    echo "Arguments:"
    echo "  CONTAINER_NAME  Name of the LXC container to create (default: $DEFAULT_CONTAINER_NAME)"
    echo "  PROFILE_NAME    Name of the LXC profile to use (default: $DEFAULT_PROFILE_NAME)"
    echo "  --external      Enable external SSH access on port 2222"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use default names"
    echo "  $0 my-claude-container               # Custom container name, default profile"
    echo "  $0 my-container claude-code-minimal  # Custom container and profile names"
    echo "  $0 my-container claude-code-dev --external  # With external access"
    echo ""
    exit 1
}

# Initialize variables
ENABLE_EXTERNAL=false
CONTAINER_NAME=""
PROFILE_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            ;;
        --external)
            ENABLE_EXTERNAL=true
            shift
            ;;
        *)
            if [ -z "$CONTAINER_NAME" ]; then
                CONTAINER_NAME="$1"
            elif [ -z "$PROFILE_NAME" ]; then
                PROFILE_NAME="$1"
            fi
            shift
            ;;
    esac
done

# Set defaults if not provided
CONTAINER_NAME="${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}"
PROFILE_NAME="${PROFILE_NAME:-$DEFAULT_PROFILE_NAME}"

# SSH alias name (derived from container name)
SSH_ALIAS="$(echo $CONTAINER_NAME | sed 's/_/-/g')"

# Check if running as proper user
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root"
   exit 1
fi

# Check if LXD is available
if ! command -v lxc &> /dev/null; then
    error "LXC/LXD is not installed or not in PATH"
    exit 1
fi

log "Starting Claude Code LXC Container Setup..."

# Function to check if container exists
container_exists() {
    lxc list --format csv | grep -q "^$CONTAINER_NAME,"
}

# Function to check if profile exists
profile_exists() {
    lxc profile list --format csv | grep -q "^$PROFILE_NAME,"
}

# Function to cleanup existing container
cleanup_existing_container() {
    if container_exists; then
        warning "Container '$CONTAINER_NAME' already exists"
        read -p "Do you want to delete it and recreate? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Stopping and deleting existing container..."
            lxc stop $CONTAINER_NAME --force 2>/dev/null || true
            lxc delete $CONTAINER_NAME --force 2>/dev/null || true
            success "Existing container removed"
        else
            error "Cannot proceed with existing container. Exiting."
            exit 1
        fi
    fi
}

# Check and setup profile
setup_profile() {
    if ! profile_exists; then
        error "Profile '$PROFILE_NAME' does not exist"
        error "Please run the profile creation commands from the documentation first"
        exit 1
    else
        success "Profile '$PROFILE_NAME' found"
    fi
}

# Create and configure container
create_container() {
    log "Creating Claude Code container with profile '$PROFILE_NAME'..."
    
    # Launch container
    lxc launch ubuntu:22.04 $CONTAINER_NAME --profile $PROFILE_NAME
    
    success "Container '$CONTAINER_NAME' created"
    
    # Wait for container to start
    log "Waiting for container to start..."
    sleep 30
    
    # Wait for cloud-init to complete (with timeout)
    log "Waiting for cloud-init to complete..."
    timeout 600 lxc exec $CONTAINER_NAME -- cloud-init status --wait || {
        warning "Cloud-init timeout, continuing anyway..."
    }
    
    # Verify basic packages
    log "Verifying basic packages..."
    if ! lxc exec $CONTAINER_NAME -- bash -c 'which ssh && which git && which python3'; then
        warning "Basic packages not ready. Waiting additional 10 seconds..."
        sleep 10
        # Try again
        if ! lxc exec $CONTAINER_NAME -- bash -c 'which ssh && which git && which python3'; then
            error "Basic packages installation failed"
            return 1
        fi
    fi
    
    # Ensure claude_code user exists
    log "Ensuring claude_code user exists..."
    lxc exec $CONTAINER_NAME -- bash -c '
        if ! id claude_code &>/dev/null; then
            useradd -m -s /bin/bash claude_code
            usermod -aG sudo claude_code
            echo "claude_code ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/claude_code
            chown -R claude_code:claude_code /home/claude_code
        fi
    '
    
    success "Basic packages verified and claude_code user ensured"
}

# Setup SSH access
setup_ssh_access() {
    log "Setting up SSH access..."
    
    # Generate SSH key if it doesn't exist
    if [ ! -f ~/.ssh/id_rsa ]; then
        log "Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
        success "SSH key generated"
    fi
    
    # Ensure SSH directory exists in container and copy public key
    log "Setting up SSH directory and copying public key..."
    lxc exec $CONTAINER_NAME -- bash << 'EOF'
# Ensure SSH directory exists with proper permissions
mkdir -p /home/claude_code/.ssh
chmod 700 /home/claude_code/.ssh
chown claude_code:claude_code /home/claude_code/.ssh

# Configure SSH for key-based authentication
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart ssh
EOF
    
    # Copy public key to container
    log "Copying SSH public key to container..."
    lxc file push ~/.ssh/id_rsa.pub $CONTAINER_NAME/home/claude_code/.ssh/authorized_keys
    
    # Set proper permissions for authorized_keys
    lxc exec $CONTAINER_NAME -- bash << 'EOF'
chmod 600 /home/claude_code/.ssh/authorized_keys
chown claude_code:claude_code /home/claude_code/.ssh/authorized_keys
EOF
    
    success "SSH key authentication configured"
}

# Get container IP and setup SSH config
setup_ssh_config() {
    log "Getting container IP address..."
    
    # Wait a moment for network to be ready
    sleep 5
    
    CONTAINER_IP=$(lxc list $CONTAINER_NAME --format json | jq -r '.[0].state.network.eth0.addresses[] | select(.family=="inet") | .address')
    
    if [ -z "$CONTAINER_IP" ] || [ "$CONTAINER_IP" = "null" ]; then
        error "Could not get container IP address"
        return 1
    fi
    
    log "Container IP: $CONTAINER_IP"
    
    # Test SSH connection
    log "Testing SSH connection..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 claude_code@$CONTAINER_IP "echo 'SSH connection successful!'"; then
        success "SSH connection test passed"
    else
        error "SSH connection test failed"
        return 1
    fi
    
    # Update SSH config
    log "Updating SSH config..."
    
    # Remove existing entry if present
    if grep -q "^Host $SSH_ALIAS" ~/.ssh/config 2>/dev/null; then
        # Remove the existing entry (from Host line to next Host line or end of file)
        sed -i "/^Host $SSH_ALIAS/,/^Host\|^$/d" ~/.ssh/config
    fi
    
    # Add new SSH config entry
    cat >> ~/.ssh/config << EOF

# Claude Code Container (Key Authentication)
Host $SSH_ALIAS
    HostName $CONTAINER_IP
    User claude_code
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
    
    success "SSH config updated. You can now connect with: ssh $SSH_ALIAS"
}

# Setup additional tools script placement
setup_additional_tools_script() {
    log "Setting up additional tools script..."
    
    # Copy the additional tools script to container
    if [ -f "$BASE_DIR/scripts/setup-additional-tools.sh" ]; then
        lxc file push "$BASE_DIR/scripts/setup-additional-tools.sh" $CONTAINER_NAME/home/claude_code/setup-additional-tools.sh
        lxc exec $CONTAINER_NAME -- chown claude_code:claude_code /home/claude_code/setup-additional-tools.sh
        lxc exec $CONTAINER_NAME -- chmod +x /home/claude_code/setup-additional-tools.sh
        success "Additional tools script placed in container"
    else
        warning "Additional tools script not found at $BASE_DIR/scripts/setup-additional-tools.sh"
    fi
}

# Setup external access
setup_external_access() {
    if [ "$ENABLE_EXTERNAL" != "true" ]; then
        return 0
    fi
    
    log "Setting up external SSH access..."
    
    # Add LXD proxy device
    log "Adding LXD proxy device for port 2222..."
    lxc config device add $CONTAINER_NAME ssh-proxy proxy \
        listen=tcp:0.0.0.0:2222 \
        connect=tcp:127.0.0.1:22 || {
        error "Failed to add proxy device"
        return 1
    }
    
    # Install and configure security tools
    log "Installing security tools (fail2ban, ufw)..."
    lxc exec $CONTAINER_NAME -- bash << 'EOF'
# Update package list and install security tools
apt-get update
apt-get install -y fail2ban ufw

# Configure UFW
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow from 10.119.132.0/24  # LXD bridge network

# Configure fail2ban
cat > /etc/fail2ban/jail.local << 'F2B_CONFIG'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
F2B_CONFIG

# Start fail2ban
systemctl enable fail2ban
systemctl restart fail2ban

# Enhanced SSH security
cat >> /etc/ssh/sshd_config << 'SSH_SEC'

# Enhanced Security Settings
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2
PermitEmptyPasswords no
X11Forwarding yes
AllowUsers claude_code
SSH_SEC

systemctl restart ssh
EOF
    
    success "External access configured on port 2222"
    log "External SSH access: ssh -p 2222 claude_code@<host-external-ip>"
}

# Copy claude-config files
copy_claude_config() {
    log "Copying claude-config files to container..."
    
    if [ -d "$BASE_DIR/claude-config" ]; then
        # Create claude-config directory in container
        lxc exec $CONTAINER_NAME -- sudo -u claude_code mkdir -p /home/claude_code/claude-config
        
        # Copy all files from claude-config directory
        for file in "$BASE_DIR/claude-config"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                lxc file push "$file" $CONTAINER_NAME/home/claude_code/claude-config/"$filename"
                lxc exec $CONTAINER_NAME -- chown claude_code:claude_code /home/claude_code/claude-config/"$filename"
            fi
        done
        
        success "claude-config files copied to container"
    else
        warning "claude-config directory not found at $BASE_DIR/claude-config"
    fi
}

# Main execution
main() {
    log "=== Claude Code LXC Container Automated Setup ==="
    
    # Cleanup existing container if needed
    cleanup_existing_container
    
    # Setup profile
    setup_profile
    
    # Create container
    if ! create_container; then
        error "Container creation failed"
        exit 1
    fi
    
    # Setup SSH access
    if ! setup_ssh_access; then
        error "SSH setup failed"
        exit 1
    fi
    
    # Setup SSH config
    if ! setup_ssh_config; then
        error "SSH config setup failed"
        exit 1
    fi
    
    # Setup additional tools script
    setup_additional_tools_script
    
    # Copy claude-config files
    copy_claude_config
    
    # Setup external access if requested
    if [ "$ENABLE_EXTERNAL" = "true" ]; then
        if ! setup_external_access; then
            warning "External access setup failed, but container is ready for internal use"
        fi
    fi
    
    success "=== Claude Code Container Setup Completed Successfully ==="
    echo
    log "Next steps:"
    echo "  1. Connect to container: ssh $SSH_ALIAS"
    echo "  2. Run additional tools setup: ./setup-additional-tools.sh"
    echo "  3. Configure Claude Code as needed"
    echo
    log "Container details:"
    echo "  - Name: $CONTAINER_NAME"
    echo "  - Profile: $PROFILE_NAME"
    echo "  - SSH alias: $SSH_ALIAS"
    echo "  - User: claude_code"
    echo "  - Authentication: SSH key-based"
    
    if [ "$ENABLE_EXTERNAL" = "true" ]; then
        echo ""
        log "External access enabled:"
        echo "  - External port: 2222"
        echo "  - Security: fail2ban + ufw enabled"
        echo "  - Connect: ssh -p 2222 claude_code@<host-external-ip>"
    fi
    echo
    warning "Note: The container and profile will be kept for your verification."
    warning "To remove them later, use:"
    echo "  lxc stop $CONTAINER_NAME && lxc delete $CONTAINER_NAME"
    echo "  lxc profile delete $PROFILE_NAME"
}

# Execute main function
main "$@"