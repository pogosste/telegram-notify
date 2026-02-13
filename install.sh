#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SILENT_MODE=false

print_success() { [ "$SILENT_MODE" = false ] && echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { [ "$SILENT_MODE" = false ] && echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { [ "$SILENT_MODE" = false ] && echo -e "${BLUE}ℹ $1${NC}"; }
print_header() { [ "$SILENT_MODE" = false ] && echo -e "\n${BLUE}==========================================${NC}\n${BLUE}$1${NC}\n${BLUE}==========================================${NC}"; }

get_ssh_port() {
    local ssh_port=""
    
    # Method 1: From sshd_config
    if [ -f /etc/ssh/sshd_config ]; then
        ssh_port=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')
    fi
    
    # Method 2: From running process (ss)
    if [ -z "$ssh_port" ]; then
        ssh_port=$(ss -tlnp 2>/dev/null | grep sshd | grep -oP ':\K[0-9]+' | head -1)
    fi
    
    # Method 3: From running process (netstat)
    if [ -z "$ssh_port" ]; then
        ssh_port=$(netstat -tlnp 2>/dev/null | grep sshd | grep -oP ':\K[0-9]+' | head -1)
    fi
    
    # Default to 22
    if [ -z "$ssh_port" ]; then
        ssh_port=22
    fi
    
    # Validate port is numeric and in valid range
    if ! [[ "$ssh_port" =~ ^[0-9]+$ ]] || [ "$ssh_port" -lt 1 ] || [ "$ssh_port" -gt 65535 ]; then
        ssh_port=22
    fi
    
    echo "$ssh_port"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --token)
            TELEGRAM_BOT_TOKEN="$2"
            shift 2
            ;;
        --chat-id)
            CHAT_ID="$2"
            shift 2
            ;;
        --topic-id)
            TOPIC_ID="$2"
            shift 2
            ;;
        --silent)
            SILENT_MODE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Usage: $0 [--token TOKEN] [--chat-id ID] [--topic-id ID] [--silent]"
            exit 1
            ;;
    esac
done

if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root: sudo $0"
    exit 1
fi

print_header "Security Notification System - Installation v2.1"

# Проверка старой установки
if [ -d /etc/security-notify ] || [ -f /usr/local/bin/ssh-login-notify ]; then
    print_warning "Previous installation detected!"
    # In non-interactive mode (when credentials are provided), auto-confirm reinstall
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
        print_info "Cleaning previous installation (non-interactive mode)..."
        rm -rf /etc/security-notify /usr/local/lib/security-notify
        rm -f /usr/local/bin/ssh-login-notify /usr/local/bin/fail2ban-notify /usr/local/bin/test-security-notify
    else
        echo ""
        echo "Please uninstall first:"
        echo "  sudo bash ~/uninstall-security-notify.sh"
        echo ""
        read -p "Force reinstall? (yes/no): " FORCE
        if [[ ! "$FORCE" =~ ^[Yy]es$ ]]; then
            exit 1
        fi
        print_info "Cleaning previous installation..."
        rm -rf /etc/security-notify /usr/local/lib/security-notify
        rm -f /usr/local/bin/ssh-login-notify /usr/local/bin/fail2ban-notify /usr/local/bin/test-security-notify
    fi
fi

# Поиск бэкапов
BACKUP_CONF=$(find /tmp -name "security-notify-backup-*" -type d 2>/dev/null | tail -1)
if [ -n "$BACKUP_CONF" ] && [ -f "$BACKUP_CONF/config.conf" ]; then
    print_info "Found backup configuration"
    # Only use backup if credentials weren't provided via arguments
    if [ -z "$TELEGRAM_BOT_TOKEN" ] && [ -z "$CHAT_ID" ]; then
        source "$BACKUP_CONF/config.conf"
        echo ""
        print_success "Loaded credentials from backup"
        echo ""
        read -p "Use these credentials? (yes/no) [yes]: " USE_BACKUP
        USE_BACKUP=${USE_BACKUP:-yes}
        
        if [[ ! "$USE_BACKUP" =~ ^[Yy] ]]; then
            TELEGRAM_BOT_TOKEN=""
            CHAT_ID=""
            TOPIC_ID=""
        fi
    fi
fi

# Запрос конфигурации
print_header "Step 1: Configuration"
echo ""

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    print_info "Get bot token from @BotFather in Telegram"
    read -p "Enter Telegram Bot Token: " TELEGRAM_BOT_TOKEN
    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        print_error "Bot token is required!"
        exit 1
    fi
else
    print_info "Using provided bot token"
fi

if [ -z "$CHAT_ID" ]; then
    print_info "Get Chat ID from @userinfobot (use group ID with -100 prefix)"
    read -p "Enter Chat ID: " CHAT_ID
    if [ -z "$CHAT_ID" ]; then
        print_error "Chat ID is required!"
        exit 1
    fi
else
    print_info "Using provided chat ID"
fi

if [ -z "$TOPIC_ID" ]; then
    # Only prompt if not in non-interactive mode
    if [ "$SILENT_MODE" = false ]; then
        read -p "Enter Topic ID (press Enter to skip): " TOPIC_ID
    fi
else
    print_info "Using provided topic ID"
fi

# Skip interactive prompts for other settings when in silent mode
if [ "$SILENT_MODE" = false ]; then
    read -p "Enter server name [$(hostname)]: " SERVER_NAME
    SERVER_NAME=${SERVER_NAME:-$(hostname)}

    read -p "Enable SSH login notifications? [yes]: " ENABLE_SSH
    ENABLE_SSH=${ENABLE_SSH:-yes}
    [[ "$ENABLE_SSH" =~ ^[Yy] ]] && ENABLE_SSH="true" || ENABLE_SSH="false"

    read -p "Enable Fail2Ban notifications? [yes]: " ENABLE_F2B
    ENABLE_F2B=${ENABLE_F2B:-yes}
    [[ "$ENABLE_F2B" =~ ^[Yy] ]] && ENABLE_F2B="true" || ENABLE_F2B="false"

    read -p "Enable geo-location lookup? [yes]: " ENABLE_GEO
    ENABLE_GEO=${ENABLE_GEO:-yes}
    [[ "$ENABLE_GEO" =~ ^[Yy] ]] && ENABLE_GEO="true" || ENABLE_GEO="false"
else
    # Use defaults in silent mode
    SERVER_NAME=${SERVER_NAME:-$(hostname)}
    ENABLE_SSH=${ENABLE_SSH:-true}
    ENABLE_F2B=${ENABLE_F2B:-true}
    ENABLE_GEO=${ENABLE_GEO:-true}
fi

# Создание директорий
print_header "Step 2: Creating directories"
mkdir -p /etc/security-notify
mkdir -p /usr/local/lib/security-notify
touch /var/log/security-notify.log
chmod 644 /var/log/security-notify.log
print_success "Directories created"

# Конфигурация
print_header "Step 3: Creating configuration"
cat > /etc/security-notify/config.conf << EOFCONF
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
CHAT_ID="$CHAT_ID"
TOPIC_ID="$TOPIC_ID"
ENABLE_SSH_SUCCESS=$ENABLE_SSH
ENABLE_SSH_FAIL=$ENABLE_F2B
ENABLE_SUDO_NOTIFY=false
ENABLE_GEO_LOOKUP=$ENABLE_GEO
WHITELIST_IPS=""
SEND_LOCATION=false
LOG_TO_FILE=true
LOG_FILE="/var/log/security-notify.log"
EOFCONF
chmod 600 /etc/security-notify/config.conf
echo "$SERVER_NAME" > /etc/security-notify/server-name.txt
print_success "Configuration saved"

# Библиотека функций
print_header "Step 4: Installing common library"
cat > /usr/local/lib/security-notify/common.sh << 'EOFLIB'
#!/bin/bash

load_config() {
    [ -f "/etc/security-notify/config.conf" ] && source /etc/security-notify/config.conf || exit 1
}

log_event() {
    [ "$LOG_TO_FILE" = "true" ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

is_whitelisted() {
    [ -z "$WHITELIST_IPS" ] && return 1
    echo "$WHITELIST_IPS" | grep -q "$1"
}

get_geo_info() {
    local ip="$1"
    [ "$ENABLE_GEO_LOOKUP" != "true" ] && echo '{"country":"Unknown","city":"Unknown","isp":"Unknown"}' && return
    [[ "$ip" == "localhost" || "$ip" == "127.0.0.1" || -z "$ip" ]] && echo '{"country":"Local","city":"Console","isp":"N/A"}' && return
    
    local geo=$(curl -s --max-time 3 "http://ip-api.com/json/${ip}?fields=status,country,city,isp" 2>/dev/null)
    if echo "$geo" | grep -q '"status":"success"'; then
        echo "$geo"
    else
        echo '{"country":"Unknown","city":"Unknown","isp":"Unknown"}'
    fi
}

parse_geo() {
    echo "$1" | grep -oP "\"$2\":\"?\K[^,\"}\]]*" | head -1
}

send_telegram() {
    local message="$1"
    load_config
    
    local response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "message_thread_id=${TOPIC_ID}" \
        -d "text=${message}" \
        -d "disable_web_page_preview=true" 2>&1)
    
    if echo "$response" | grep -q '"ok":true'; then
        log_event "Message sent: success"
    else
        log_event "Message sent: failed"
    fi
}

get_server_name() {
    [ -f "/etc/security-notify/server-name.txt" ] && cat /etc/security-notify/server-name.txt || hostname
}
EOFLIB
chmod 644 /usr/local/lib/security-notify/common.sh
print_success "Library installed"

# SSH Login скрипт
print_header "Step 5: Installing SSH notification script"
cat > /usr/local/bin/ssh-login-notify << 'EOFSSH'
#!/bin/bash
source /usr/local/lib/security-notify/common.sh
load_config
[ "$ENABLE_SSH_SUCCESS" != "true" ] && exit 0

# Фильтр: только открытие сессии (не закрытие)
if [ "$PAM_TYPE" != "open_session" ]; then
    exit 0
fi

USER="${PAM_USER:-$USER}"
IP="${PAM_RHOST:-Unknown}"
SERVICE="${PAM_SERVICE:-Unknown}"

[[ "$SERVICE" == "cron" || "$SERVICE" == "systemd" ]] && exit 0
[[ "$IP" == "Unknown" || "$IP" == "" ]] && exit 0
is_whitelisted "$IP" && log_event "SSH from whitelisted: $USER@$IP" && exit 0

GEO=$(get_geo_info "$IP")
COUNTRY=$(parse_geo "$GEO" "country")
CITY=$(parse_geo "$GEO" "city")
ISP=$(parse_geo "$GEO" "isp")

LOGINS=$(last -a -d -i "$USER" 2>/dev/null | grep "$IP" | wc -l)
if [ "$LOGINS" -le 1 ]; then
    HEADER="⚠️ NEW IP ADDRESS ⚠️"
else
    HEADER="✅ SSH LOGIN SUCCESS"
fi

MSG="${HEADER}%0A"
MSG="${MSG}━━━━━━━━━━━━━━━━━━━━%0A"
MSG="${MSG}👤 User: ${USER}%0A"
MSG="${MSG}🌐 IP Address: ${IP}%0A"
MSG="${MSG}📍 Location: ${CITY}, ${COUNTRY}%0A"
MSG="${MSG}🏢 ISP: ${ISP}%0A"
MSG="${MSG}🖥 Server: $(get_server_name)%0A"
MSG="${MSG}🕐 Time: $(date '+%Y-%m-%d %H:%M:%S')%0A"
MSG="${MSG}━━━━━━━━━━━━━━━━━━━━"

log_event "SSH login: $USER from $IP ($CITY, $COUNTRY)"
send_telegram "$MSG" &
exit 0
EOFSSH
chmod +x /usr/local/bin/ssh-login-notify
print_success "SSH notification script installed"

# Fail2Ban скрипт
print_header "Step 6: Installing Fail2Ban notification script"
cat > /usr/local/bin/fail2ban-notify << 'EOFF2B'
#!/bin/bash
source /usr/local/lib/security-notify/common.sh
load_config
[ "$ENABLE_SSH_FAIL" != "true" ] && exit 0

JAIL="$1"
IP="$2"
FAILS="${3:-Unknown}"

GEO=$(get_geo_info "$IP")
COUNTRY=$(parse_geo "$GEO" "country")
CITY=$(parse_geo "$GEO" "city")
ISP=$(parse_geo "$GEO" "isp")

case "$JAIL" in
    "sshd"|"ssh"|"SSH") JAIL_ICON="🔐" ;;
    "recidive") JAIL_ICON="⛔" ;;
    *) JAIL_ICON="🚨" ;;
esac

MSG="🚨 FAIL2BAN ALERT 🚨%0A"
MSG="${MSG}━━━━━━━━━━━━━━━━━━━━%0A"
MSG="${MSG}${JAIL_ICON} Jail: ${JAIL}%0A"
MSG="${MSG}🌐 IP Address: ${IP}%0A"
MSG="${MSG}📍 Location: ${CITY}, ${COUNTRY}%0A"
MSG="${MSG}🏢 ISP: ${ISP}%0A"
MSG="${MSG}❌ Failed Attempts: ${FAILS}%0A"
MSG="${MSG}🖥 Server: $(get_server_name)%0A"
MSG="${MSG}🕐 Time: $(date '+%Y-%m-%d %H:%M:%S')%0A"
MSG="${MSG}━━━━━━━━━━━━━━━━━━━━%0A"
MSG="${MSG}⚠️ IP HAS BEEN BANNED ⚠️"

log_event "Fail2Ban: $IP banned in $JAIL ($FAILS failures)"
send_telegram "$MSG" &
exit 0
EOFF2B
chmod +x /usr/local/bin/fail2ban-notify
print_success "Fail2Ban notification script installed"

# Тестовый скрипт
print_header "Step 7: Installing test script"
cat > /usr/local/bin/test-security-notify << 'EOFTEST'
#!/bin/bash
source /usr/local/lib/security-notify/common.sh
echo "=========================================="
echo "Security Notification System - Test"
echo "=========================================="
load_config
echo "Server: $(get_server_name)"
echo "Chat ID: $CHAT_ID"
echo "Topic ID: $TOPIC_ID"
echo ""

echo "[1] Sending test message..."
MSG="🧪 SYSTEM TEST 🧪%0A"
MSG="${MSG}━━━━━━━━━━━━━━━━━━━━%0A"
MSG="${MSG}✅ Security notification system is working!%0A"
MSG="${MSG}%0A"
MSG="${MSG}🖥 Server: $(get_server_name)%0A"
MSG="${MSG}🕐 Time: $(date '+%Y-%m-%d %H:%M:%S')%0A"
MSG="${MSG}━━━━━━━━━━━━━━━━━━━━%0A"
MSG="${MSG}📊 All systems operational"
send_telegram "$MSG"
sleep 2

echo "[2] Testing Fail2Ban notification..."
/usr/local/bin/fail2ban-notify "TEST-JAIL" "8.8.8.8" "5"
sleep 2

echo "[3] Testing SSH notification..."
PAM_TYPE="open_session" PAM_USER="testuser" PAM_RHOST="1.1.1.1" PAM_SERVICE="sshd" /usr/local/bin/ssh-login-notify
sleep 2

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Tests completed! Check Telegram topic #${TOPIC_ID}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Recent log entries:"
tail -10 /var/log/security-notify.log
EOFTEST
chmod +x /usr/local/bin/test-security-notify
print_success "Test script installed"

# PAM конфигурация
print_header "Step 8: Configuring PAM"
if [ "$ENABLE_SSH" = "true" ]; then
    SSH_PAM="/etc/pam.d/ssh"
    [ ! -f "$SSH_PAM" ] && SSH_PAM="/etc/pam.d/sshd"
    
    if ! grep -q "ssh-login-notify" "$SSH_PAM"; then
        echo "session optional pam_exec.so seteuid /usr/local/bin/ssh-login-notify" >> "$SSH_PAM"
        print_success "PAM configured ($SSH_PAM)"
    else
        print_warning "PAM already configured"
    fi
else
    print_info "SSH notifications disabled - skipping PAM"
fi

# Fail2Ban
if [ "$ENABLE_F2B" = "true" ]; then
    print_header "Step 9: Installing and Configuring Fail2Ban"
    
    if ! command -v fail2ban-client &> /dev/null; then
        print_info "Fail2Ban not found, installing..."
        
        if command -v apt &> /dev/null; then
            print_info "Using apt package manager..."
            export DEBIAN_FRONTEND=noninteractive
            apt update -qq
            apt install -y fail2ban
            INSTALL_RESULT=$?
        elif command -v yum &> /dev/null; then
            print_info "Using yum package manager..."
            yum install -y fail2ban
            INSTALL_RESULT=$?
        elif command -v dnf &> /dev/null; then
            print_info "Using dnf package manager..."
            dnf install -y fail2ban
            INSTALL_RESULT=$?
        else
            print_error "No supported package manager found!"
            INSTALL_RESULT=1
        fi
        
        if [ $INSTALL_RESULT -eq 0 ]; then
            print_success "Fail2Ban installed"
        else
            print_error "Failed to install Fail2Ban"
            ENABLE_F2B="false"
        fi
    else
        print_success "Fail2Ban already installed"
    fi
    
    if [ "$ENABLE_F2B" = "true" ]; then
        # Detect SSH port
        SSH_PORT=$(get_ssh_port)
        print_info "Detected SSH port: $SSH_PORT"
        
        cat > /etc/fail2ban/action.d/telegram-notify.conf << 'EOFACT'
[Definition]
actionstart =
actionstop =
actioncheck =
actionban = /usr/local/bin/fail2ban-notify "<name>" "<ip>" "<failures>"
actionunban =
[Init]
name = default
EOFACT
        print_success "Fail2Ban action created"
        
        if [ ! -f /etc/fail2ban/jail.local ]; then
            # Create new jail.local with detected SSH port
            cat > /etc/fail2ban/jail.local << EOFJAIL
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
action = iptables-multiport[name=SSH, port=$SSH_PORT, protocol=tcp]
         telegram-notify[name=SSH]
EOFJAIL
            print_success "Fail2Ban jail.local created (port: $SSH_PORT)"
        else
            # Update existing jail.local
            if grep -q '^\[sshd\]' /etc/fail2ban/jail.local; then
                # Check if telegram-notify already exists in [sshd] section (read entire section)
                needs_telegram_notify=0
                if ! awk 'BEGIN{in_sshd=0} /^\[sshd\]/{in_sshd=1} /^\[/ && !/^\[sshd\]/{in_sshd=0} in_sshd{print}' /etc/fail2ban/jail.local | grep -q 'telegram-notify'; then
                    needs_telegram_notify=1
                fi
                
                # Create a temporary file for updates
                temp_jail=$(mktemp)
                cp /etc/fail2ban/jail.local "$temp_jail"
                
                # Update port and action in [sshd] section only
                awk -v port="$SSH_PORT" -v needs_telegram="$needs_telegram_notify" '
                BEGIN { in_sshd=0; action_found=0 }
                /^\[sshd\]/ { in_sshd=1 }
                /^\[/ && !/^\[sshd\]/ { in_sshd=0 }
                in_sshd && /^port[[:space:]]*=/ { print "port = " port; next }
                in_sshd && /^action[[:space:]]*=/ {
                    # Update port in action line
                    gsub(/port=ssh/, "port=" port)
                    gsub(/port=[0-9]+/, "port=" port)
                    print
                    # Add telegram-notify after action if needed and not yet added
                    if (needs_telegram == 1 && action_found == 0) {
                        print "         telegram-notify[name=SSH]"
                        action_found = 1
                    }
                    next
                }
                { print }
                ' "$temp_jail" > /etc/fail2ban/jail.local
                
                rm -f "$temp_jail"
                print_success "Updated [sshd] section (port: $SSH_PORT)"
            else
                # Add [sshd] section if it doesn't exist
                cat >> /etc/fail2ban/jail.local << EOFJAIL

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
action = iptables-multiport[name=SSH, port=$SSH_PORT, protocol=tcp]
         telegram-notify[name=SSH]
EOFJAIL
                print_success "Added [sshd] section (port: $SSH_PORT)"
            fi
        fi
        
        systemctl enable fail2ban 2>/dev/null
        systemctl restart fail2ban
        sleep 3
        
        if systemctl is-active --quiet fail2ban; then
            print_success "Fail2Ban is running"
            
            if fail2ban-client status sshd &>/dev/null; then
                print_success "SSH jail is active (monitoring port $SSH_PORT)"
            else
                print_warning "SSH jail may not be active"
            fi
        else
            print_error "Fail2Ban failed to start"
        fi
    fi
else
    print_header "Step 9: Skipping Fail2Ban (disabled)"
fi

# SSH reload
print_header "Step 10: Reloading SSH"
systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null
print_success "SSH reloaded"

# Тесты
print_header "Running Tests"
echo ""
/usr/local/bin/test-security-notify

# Итог
print_header "Installation Complete!"
echo ""
print_success "Security Notification System is ready!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Configuration:"
echo "  File: /etc/security-notify/config.conf"
echo "  Logs: /var/log/security-notify.log"
echo "  Server: $SERVER_NAME"
echo ""
echo "Enabled features:"
echo "  SSH Login: $ENABLE_SSH"
echo "  Fail2Ban: $ENABLE_F2B"
echo "  Geo Lookup: $ENABLE_GEO"
echo ""

if [ "$ENABLE_F2B" = "true" ] && command -v fail2ban-client &> /dev/null; then
    echo "Fail2Ban Status:"
    fail2ban-client status 2>/dev/null | head -5
    echo ""
fi

print_warning "CHECK YOUR TELEGRAM NOW!"
echo "You should see 3 test messages in topic #${TOPIC_ID}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Useful commands:"
echo "  sudo /usr/local/bin/test-security-notify"
echo "  tail -f /var/log/security-notify.log"
echo "  sudo fail2ban-client status sshd"
echo ""
print_success "Happy monitoring! 🚀"
echo ""
