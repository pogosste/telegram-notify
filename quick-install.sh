#!/bin/bash

# Quick Install Script for Telegram Notify - Security Notification System
# Usage: curl -fsSL https://raw.githubusercontent.com/pogosste/telegram-notify/main/quick-install.sh | sudo bash

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

# Проверка root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run with sudo"
    exit 1
fi

print_header

# Определяем временную директорию
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

print_info "Downloading files from GitHub..."

# GitHub репозиторий
REPO_URL="https://raw.githubusercontent.com/pogosste/telegram-notify/main"

# Скачиваем необходимые файлы
curl -fsSL "$REPO_URL/install.sh" -o install.sh
curl -fsSL "$REPO_URL/uninstall.sh" -o uninstall.sh
curl -fsSL "$REPO_URL/menu.sh" -o menu.sh

chmod +x install.sh uninstall.sh menu.sh

print_success "Files downloaded"

# Запускаем установку
print_info "Starting installation..."
echo ""
bash install.sh

# Проверяем успешность установки
if [ -f /etc/security-notify/config.conf ]; then
    print_success "Installation completed successfully!"
    
    # Создаём символические ссылки для глобальной команды
    print_info "Creating global command 'telegram-notify'..."
    
    # Копируем menu.sh в /usr/local/bin
    cp menu.sh /usr/local/bin/telegram-notify
    chmod +x /usr/local/bin/telegram-notify
    
    # Также создаём копии install/uninstall скриптов
    mkdir -p /usr/local/share/telegram-notify
    cp install.sh /usr/local/share/telegram-notify/install.sh
    cp uninstall.sh /usr/local/share/telegram-notify/uninstall.sh
    chmod +x /usr/local/share/telegram-notify/*.sh
    
    print_success "Global command created!"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "You can now use: ${YELLOW}telegram-notify${NC}"
    echo ""
    echo -e "Commands:"
    echo -e "  ${YELLOW}telegram-notify${NC}           - Open management menu"
    echo -e "  ${YELLOW}telegram-notify test${NC}      - Run test notifications"
    echo -e "  ${YELLOW}telegram-notify status${NC}    - Show system status"
    echo -e "  ${YELLOW}telegram-notify logs${NC}      - View logs"
    echo ""
    
else
    print_error "Installation failed"
    exit 1
fi

# Очистка
cd /
rm -rf "$TEMP_DIR"
