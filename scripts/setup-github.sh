#!/bin/bash

# n8n GitHub Integration Setup Script
# This script sets up SSH authentication for GitHub access in n8n containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GIT_CONFIG_DIR="./git-config"
SSH_DIR="$GIT_CONFIG_DIR/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
GIT_CONFIG_FILE="$GIT_CONFIG_DIR/.gitconfig"
GIT_REPOS_DIR="./git-repos"

echo -e "${BLUE}🔧 n8n GitHub Integration Setup${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Create directories if they don't exist
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "$SSH_DIR" "$GIT_REPOS_DIR"
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Check if SSH key already exists
if [ -f "$SSH_KEY" ]; then
    echo -e "${YELLOW}SSH key already exists at $SSH_KEY${NC}"
    read -p "Do you want to regenerate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Using existing SSH key${NC}"
    else
        echo -e "${YELLOW}Backing up existing key...${NC}"
        mv "$SSH_KEY" "$SSH_KEY.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$SSH_KEY.pub" "$SSH_KEY.pub.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
        
        echo -e "${YELLOW}Generating new SSH key...${NC}"
        ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "n8n-github-integration"
        echo -e "${GREEN}✓ New SSH key generated${NC}"
    fi
else
    echo -e "${YELLOW}Generating SSH key...${NC}"
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "n8n-github-integration"
    echo -e "${GREEN}✓ SSH key generated${NC}"
fi

# Set proper permissions
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_KEY"
chmod 644 "$SSH_KEY.pub"
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Configure Git if not already configured
if [ ! -f "$GIT_CONFIG_FILE" ]; then
    echo -e "${YELLOW}Configuring Git...${NC}"
    
    # Ask for git user name
    read -p "Enter your Git user name: " git_user_name
    while [ -z "$git_user_name" ]; do
        echo -e "${RED}Git user name cannot be empty${NC}"
        read -p "Enter your Git user name: " git_user_name
    done
    
    # Ask for git user email
    read -p "Enter your Git user email: " git_user_email
    while [ -z "$git_user_email" ]; do
        echo -e "${RED}Git user email cannot be empty${NC}"
        read -p "Enter your Git user email: " git_user_email
    done
    
    # Create git config file
    cat > "$GIT_CONFIG_FILE" <<EOF
[user]
    name = $git_user_name
    email = $git_user_email
[core]
    autocrlf = input
    editor = nano
[pull]
    rebase = false
[init]
    defaultBranch = main
EOF
    
    echo -e "${GREEN}✓ Git configured${NC}"
else
    echo -e "${GREEN}✓ Git config already exists${NC}"
fi
echo ""

# Add GitHub to known hosts if not already added
if ! grep -q "github.com" "$SSH_DIR/known_hosts" 2>/dev/null; then
    echo -e "${YELLOW}Adding GitHub to known hosts...${NC}"
    ssh-keyscan -t ed25519 github.com >> "$SSH_DIR/known_hosts" 2>/dev/null
    ssh-keyscan -t rsa github.com >> "$SSH_DIR/known_hosts" 2>/dev/null
    chmod 644 "$SSH_DIR/known_hosts"
    echo -e "${GREEN}✓ GitHub added to known hosts${NC}"
else
    echo -e "${GREEN}✓ GitHub already in known hosts${NC}"
fi
echo ""

# Create SSH config file for GitHub
echo -e "${YELLOW}Creating SSH config...${NC}"
cat > "$SSH_DIR/config" <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
    AddKeysToAgent yes
EOF
chmod 644 "$SSH_DIR/config"
echo -e "${GREEN}✓ SSH config created${NC}"
echo ""

# Display the public key
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📋 Your SSH Public Key${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Copy the following SSH public key and add it to your GitHub account:${NC}"
echo -e "${YELLOW}(Settings → SSH and GPG keys → New SSH key)${NC}"
echo ""
echo -e "${GREEN}$(cat "$SSH_KEY.pub")${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo ""

# Instructions
echo -e "${BLUE}📝 Next Steps:${NC}"
echo ""
echo -e "1. Copy the SSH public key above"
echo -e "2. Go to ${YELLOW}https://github.com/settings/keys${NC}"
echo -e "3. Click '${YELLOW}New SSH key${NC}'"
echo -e "4. Give it a title (e.g., '${YELLOW}n8n-deployment${NC}')"
echo -e "5. Paste the key and click '${YELLOW}Add SSH key${NC}'"
echo ""
echo -e "6. After adding the key to GitHub, test the connection with:"
echo -e "   ${YELLOW}just github-test${NC}"
echo ""
echo -e "${GREEN}✓ GitHub setup complete!${NC}"
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo -e "  ${YELLOW}just github-test${NC}     - Test GitHub connectivity"
echo -e "  ${YELLOW}just github-key${NC}      - Display SSH public key again"
echo -e "  ${YELLOW}just github-clone${NC}    - Clone a repository"
echo -e "  ${YELLOW}just github-repos${NC}    - List cloned repositories"