#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SILENT_MODE=false
if [[ "$1" == "--silent" ]]; then
    SILENT_MODE=true
fi

print_success() { [ "$SILENT_MODE" = false ] && echo -e "${GREEN}✓ $1${NC}"; }
print_error() { [ "$SILENT_MODE" = false ] && echo -e "${RED}✗ $1${NC}"; }
print_warning() { [ "$SILENT_MODE" = false ] && echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { [ "$SILENT_MODE" = false ] && echo -e "${BLUE}ℹ $1${NC}"; }
print_header() { [ "$SILENT_MODE" = false ] && echo -e "\n${BLUE}==========================================${NC}\n${BLUE}$1${NC}\n${BLUE}==========================================${NC}"; }

if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root: sudo $0"
    exit 1
fi

if [ "$SILENT_MODE" = false ]; then
    print_header "Security Notification System - UNINSTALL"
    echo ""
    print_warning "This will remove all security notification components"
    read -p "Continue? (yes/no): " CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Yy]es$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

print_header "Step 1: Stopping services"
systemctl stop fail2ban 2>/dev/null
print_success "Services stopped"

print_header "Step 2: Creating backups"
BACKUP_DIR="/tmp/security-notify-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f /etc/security-notify/config.conf ]; then
    cp /etc/security-notify/config.conf "$BACKUP_DIR/"
    print_success "Config backed up to $BACKUP_DIR"
fi

if [ -f /var/log/security-notify.log ]; then
    cp /var/log/security-notify.log "$BACKUP_DIR/"
    print_success "Logs backed up"
fi

if [ -f /etc/fail2ban/jail.local ]; then
    cp /etc/fail2ban/jail.local "$BACKUP_DIR/"
    print_success "Fail2Ban config backed up"
fi

print_header "Step 3: Removing scripts"
rm -f /usr/local/bin/ssh-login-notify
rm -f /usr/local/bin/fail2ban-notify
rm -f /usr/local/bin/test-security-notify
rm -f /usr/local/bin/telegram-notify
print_success "Scripts removed"

print_header "Step 4: Removing libraries"
rm -rf /usr/local/lib/security-notify
rm -rf /usr/local/share/telegram-notify
print_success "Libraries removed"

print_header "Step 5: Removing configuration"
rm -rf /etc/security-notify
print_success "Configuration removed"

print_header "Step 6: Cleaning PAM configuration"
if [ -f /etc/pam.d/ssh ]; then
    sed -i.bak '/ssh-login-notify/d' /etc/pam.d/ssh
    print_success "PAM cleaned (/etc/pam.d/ssh)"
fi
if [ -f /etc/pam.d/sshd ]; then
    sed -i.bak '/ssh-login-notify/d' /etc/pam.d/sshd
    print_success "PAM cleaned (/etc/pam.d/sshd)"
fi

print_header "Step 7: Removing Fail2Ban action"
rm -f /etc/fail2ban/action.d/telegram-notify.conf
print_success "Fail2Ban action removed"

print_header "Step 8: Cleaning Fail2Ban jail"
if [ -f /etc/fail2ban/jail.local ]; then
    sed -i.bak '/telegram-notify/d' /etc/fail2ban/jail.local
    print_success "jail.local cleaned"
fi

print_header "Step 9: Removing logs"
rm -f /var/log/security-notify.log
print_success "Logs removed"

print_header "Step 10: Cleaning temp files"
rm -f /tmp/ssh-notify-*.lock
print_success "Temp files removed"

print_header "Step 11: Restarting services"
systemctl restart fail2ban 2>/dev/null
systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null
print_success "Services restarted"

if [ "$SILENT_MODE" = false ]; then
    print_header "Uninstall Complete!"
    echo ""
    print_success "Security Notification System has been uninstalled"
    echo ""
    echo "Backups saved to: $BACKUP_DIR"
    echo ""
fi
