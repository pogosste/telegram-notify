#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_header() { 
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     ${BLUE}🔐 TELEGRAM NOTIFY${CYAN}                            ║${NC}"
    echo -e "${CYAN}║        ${YELLOW}Quick Installation${CYAN}                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

if [ "$EUID" -ne 0 ]; then 
    print_error "Please run with sudo"
    exit 1
fi

print_header

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

print_info "Downloading from GitHub..."

REPO_URL="https://raw.githubusercontent.com/pogosste/telegram-notify/main"

curl -fsSL "$REPO_URL/install.sh" -o install.sh
curl -fsSL "$REPO_URL/uninstall.sh" -o uninstall.sh
curl -fsSL "$REPO_URL/menu.sh" -o menu.sh

chmod +x install.sh uninstall.sh menu.sh

print_success "Files downloaded"

print_info "Starting installation..."
echo ""
bash install.sh

if [ -f /etc/security-notify/config.conf ]; then
    print_success "Installation completed!"
    
    print_info "Creating global command..."
    
    cp menu.sh /usr/local/bin/telegram-notify
    chmod +x /usr/local/bin/telegram-notify
    
    mkdir -p /usr/local/share/telegram-notify
    cp install.sh /usr/local/share/telegram-notify/
    cp uninstall.sh /usr/local/share/telegram-notify/
    chmod +x /usr/local/share/telegram-notify/*.sh
    
    print_success "Global command created!"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━��━━━━${NC}"
    echo ""
    echo -e "Use: ${YELLOW}telegram-notify${NC}"
    echo ""
    echo -e "Commands:"
    echo -e "  ${YELLOW}telegram-notify${NC}       - Open menu"
    echo -e "  ${YELLOW}telegram-notify test${NC}  - Test"
    echo -e "  ${YELLOW}telegram-notify logs${NC}  - View logs"
    echo ""
else
    print_error "Installation failed"
    exit 1
fi

cd /
rm -rf "$TEMP_DIR"
