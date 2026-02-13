#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_header() { 
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     ${MAGENTA}🔐 TELEGRAM NOTIFY${CYAN}                            ║${NC}"
    echo -e "${CYAN}║        ${BLUE}Management Menu v2.1${CYAN}                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root: sudo telegram-notify"
        exit 1
    fi
}

check_installation() {
    [ -f /etc/security-notify/config.conf ]
}

get_status_simple() {
    if check_installation; then
        source /etc/security-notify/config.conf
        echo -e "${GREEN}✓ System installed${NC}"
        echo ""
        echo -e "${CYAN}Server:${NC} $(cat /etc/security-notify/server-name.txt 2>/dev/null)"
        echo -e "${CYAN}Chat ID:${NC} ${CHAT_ID}"
        [ "$ENABLE_SSH_SUCCESS" = "true" ] && echo -e "  ${GREEN}✓${NC} SSH Login" || echo -e "  ${RED}✗${NC} SSH Login"
        [ "$ENABLE_SSH_FAIL" = "true" ] && echo -e "  ${GREEN}✓${NC} Fail2Ban" || echo -e "  ${RED}✗${NC} Fail2Ban"
    else
        echo -e "${RED}✗ System NOT installed${NC}"
    fi
}

quick_test() {
    check_installation || { print_error "System not installed"; exit 1; }
    /usr/local/bin/test-security-notify
}

quick_status() {
    get_status_simple
}

quick_logs() {
    check_installation || { print_error "System not installed"; exit 1; }
    if [ "$1" = "-f" ] || [ "$1" = "--follow" ]; then
        tail -f /var/log/security-notify.log
    else
        tail -30 /var/log/security-notify.log
    fi
}

quick_install() {
    if [ -f "$(dirname "$0")/install.sh" ]; then
        bash "$(dirname "$0")/install.sh"
    elif [ -f "/usr/local/share/telegram-notify/install.sh" ]; then
        bash /usr/local/share/telegram-notify/install.sh
    else
        print_error "Installation script not found"
        exit 1
    fi
}

quick_uninstall() {
    if [ -f "$(dirname "$0")/uninstall.sh" ]; then
        bash "$(dirname "$0")/uninstall.sh"
    elif [ -f "/usr/local/share/telegram-notify/uninstall.sh" ]; then
        bash /usr/local/share/telegram-notify/uninstall.sh
    else
        print_error "Uninstall script not found"
        exit 1
    fi
}

show_help() {
    echo "Telegram Notify - Security Notification System"
    echo ""
    echo "Usage: telegram-notify [command]"
    echo ""
    echo "Commands:"
    echo "  (no args)      Open interactive menu"
    echo "  test           Run test notifications"
    echo "  status         Show system status"
    echo "  logs [-f]      View logs (-f for live)"
    echo "  install        Install system"
    echo "  uninstall      Uninstall system"
    echo "  help           Show this help"
    echo ""
}

main_menu() {
    while true; do
        print_header
        echo -e "${CYAN}Status:${NC}"
        get_status_simple
        echo ""
        echo -e "${CYAN}Menu:${NC}"
        echo -e "${YELLOW}1.${NC} 📦 Install"
        echo -e "${YELLOW}2.${NC} 🗑️  Uninstall"
        echo -e "${YELLOW}3.${NC} 🧪 Test"
        echo -e "${YELLOW}4.${NC} 📊 View Logs"
        echo -e "${YELLOW}0.${NC} 🚪 Exit"
        echo ""
        read -p "Choose: " choice
        
        case $choice in
            1) quick_install; read -p "Press Enter..." ;;
            2) quick_uninstall; read -p "Press Enter..." ;;
            3) quick_test; read -p "Press Enter..." ;;
            4) quick_logs; read -p "Press Enter..." ;;
            0) clear; echo "Goodbye!"; exit 0 ;;
            *) print_error "Invalid choice"; sleep 1 ;;
        esac
    done
}

check_root

case "$1" in
    test) quick_test ;;
    status) quick_status ;;
    logs) quick_logs "$2" ;;
    install) quick_install ;;
    uninstall) quick_uninstall ;;
    help|--help|-h) show_help ;;
    "") main_menu ;;
    *) print_error "Unknown: $1"; show_help; exit 1 ;;
esac
