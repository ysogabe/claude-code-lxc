#!/bin/bash
# Additional Tools Installation Script
# This script should be run inside the Claude Code container

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

log "=== Additional Tools Installation ==="

# Node.js環境セットアップ（NodeSourceから最新LTS）
install_nodejs() {
    log "Installing Node.js..."
    
    # Skip if Node.js is already installed
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        log "Node.js already installed: $node_version"
    else
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Install global packages
    sudo npm install -g yarn pnpm
    success "Node.js installed successfully"
}

# Python環境セットアップ
setup_python() {
    log "Setting up Python environment..."
    
    # Ensure pip is installed
    if ! command -v pip3 &> /dev/null; then
        log "Installing pip3..."
        sudo apt-get update
        sudo apt-get install -y python3-pip python3-venv python3-dev
    fi
    
    # Upgrade pip and install tools
    python3 -m pip install --upgrade pip --user
    python3 -m pip install pipenv poetry virtualenv --user
    success "Python environment setup completed"
}

# Rust環境セットアップ (claude_codeユーザー)
setup_rust() {
    log "Setting up Rust environment..."
    sudo -u claude_code bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
    sudo -u claude_code bash -c 'echo "source ~/.cargo/env" >> ~/.bashrc'
    success "Rust environment setup completed"
}

# GitHub CLIの設定
install_github_cli() {
    log "Installing GitHub CLI..."
    
    # Skip if already installed
    if command -v gh &> /dev/null; then
        local gh_version=$(gh --version | head -n1)
        log "GitHub CLI already installed: $gh_version"
    else
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install gh -y
    fi
    success "GitHub CLI installed successfully"
}

# Claude Code インストール
install_claude_code() {
    log "Installing Claude Code..."
    
    # Install via npm
    if command -v npm &> /dev/null; then
        sudo bash -c 'npm install -g @anthropic-ai/claude-code'
        if [ $? -eq 0 ]; then
            success "Claude Code installed via npm"
        else
            error "Claude Code installation failed via npm"
            return 1
        fi
    else
        error "npm not found. Cannot install Claude Code."
        return 1
    fi
}

# 開発用ディレクトリ作成
create_directories() {
    log "Creating development directories..."
    sudo -u claude_code mkdir -p /home/claude_code/workspace/{python,rust,nodejs,docker}
    sudo -u claude_code mkdir -p /home/claude_code/projects
    sudo -u claude_code mkdir -p /home/claude_code/.claude
    
    # claude-config directory should already exist from main setup script
    if [ ! -d "/home/claude_code/claude-config" ]; then
        sudo -u claude_code mkdir -p /home/claude_code/claude-config
    fi
    
    success "Development directories created"
}

# Claude Code環境設定
setup_claude_environment() {
    log "Setting up Claude Code environment..."
    sudo -u claude_code bash << 'EOF'
# Create npm global directory first
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

# bashrc環境変数の設定
cat >> ~/.bashrc << 'BASHRC_EOF'

# Claude Code環境変数
export CLAUDE_CODE_WORKSPACE="/home/claude_code/workspace"
export CLAUDE_CODE_PROJECTS="/home/claude_code/projects"

# Python環境
export PATH="$HOME/.local/bin:$PATH"

# Node.js環境 (must be before PATH export)
export PATH="$HOME/.npm-global/bin:$PATH"

# Rust環境
if [ -f ~/.cargo/env ]; then
    source ~/.cargo/env
fi

# 便利なエイリアス
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias workspace='cd $CLAUDE_CODE_WORKSPACE'
alias projects='cd $CLAUDE_CODE_PROJECTS'
BASHRC_EOF

# Also add to .profile for non-interactive shells
cat >> ~/.profile << 'PROFILE_EOF'

# Claude Code and development tools PATH
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

# Rust environment
if [ -f ~/.cargo/env ]; then
    source ~/.cargo/env
fi
PROFILE_EOF
EOF
    
    success "Claude Code environment configured"
}

# mDNS設定
configure_mdns() {
    log "Configuring mDNS..."
    if ! grep -q "mdns" /etc/nsswitch.conf; then
        sudo sed -i 's/hosts:.*/hosts:          files mdns4_minimal [NOTFOUND=return] dns mdns4/' /etc/nsswitch.conf
        success "mDNS configuration updated"
    else
        warning "mDNS already configured"
    fi
}

# Main execution
main() {
    # Check if running inside container (more flexible detection)
    local is_container=false
    
    if [ -f /.dockerenv ] || [ -f /run/.containerenv ] || grep -q lxc /proc/1/cgroup 2>/dev/null; then
        is_container=true
    fi
    
    # Also check hostname and environment
    if [[ "$(hostname)" == *"claude-code"* ]] || [[ "$USER" == "claude_code" ]]; then
        is_container=true
    fi
    
    if [ "$is_container" = false ]; then
        warning "This script should be run inside the LXC container"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Exiting"
            exit 1
        fi
    fi
    
    # Run installation steps
    install_nodejs
    setup_python
    setup_rust
    install_github_cli
    install_claude_code
    create_directories
    setup_claude_environment
    configure_mdns
    
    success "=== Additional Tools Installation Completed ==="
    log "Please run 'source ~/.bashrc' to load the new environment variables"
    log "Or logout and login again to apply all changes"
}

# Execute main function
main "$@"