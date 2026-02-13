# 🔐 Telegram Notify - Security Notification System

Система уведомлений о событиях безопасности на VPS серверах через Telegram.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/release/pogosste/telegram-notify.svg)](https://github.com/pogosste/telegram-notify/releases)

## 🚀 Быстрая установка

### Установка одной командой:

```bash
curl -fsSL https://raw.githubusercontent.com/pogosste/telegram-notify/main/quick-install.sh | sudo bash
После установки используйте команду:

bash
telegram-notify
📋 Возможности
✅ SSH Login Alerts - уведомления о входах в систему
🚨 Fail2Ban Alerts - уведомления о блокировке IP
📍 Geo-location - определение местоположения по IP
🎯 Topic Support - отправка в топики Telegram
🆕 New IP Detection - предупреждение о новых IP адресах
📊 Logging - полное логирование событий
🎛️ Interactive Menu - удобное управление через CLI
💻 Использование
Основные команды:
bash
telegram-notify              # Открыть интерактивное меню
telegram-notify test         # Отправить тестовые уведомления
telegram-notify status       # Показать статус системы
telegram-notify logs         # Просмотр логов
telegram-notify logs -f      # Живой просмотр логов
telegram-notify help         # Показать справку
Интерактивное меню:
Code
╔════════════════════════════════════════════════════════╗
║     🔐 SECURITY NOTIFICATION SYSTEM              ║
║        Management Menu v2.1                         ║
╚════════════════════════════════════════════════════════╝

1. 📦 Установить систему
2. 🗑️  Удалить систему
3. ⚙️  Настройки
4. 🧪 Тестировать систему
5. 📊 Просмотр логов
6. ℹ️  Информация
0. 🚪 Выход
📖 Получение учетных данных Telegram
Bot Token
Найдите @BotFather в Telegram
Отправьте /newbot
Следуйте инструкциям
Скопируйте токен
Chat ID
Создайте группу в Telegram
Добавьте вашего бота в группу как администратора
Найдите @userinfobot
Перешлите любое сообщение из группы боту
Скопируйте ID (начинается с -100)
Topic ID (опционально)
Включите топики в настройках группы
Создайте топик (например, "Security Alerts")
Перешлите сообщение из топика @userinfobot
Скопируйте message_thread_id
📦 Альтернативные методы установки
Из исходников:
bash
git clone https://github.com/pogosste/telegram-notify.git
cd telegram-notify
sudo bash install.sh
Wget:
bash
wget -qO- https://raw.githubusercontent.com/pogosste/telegram-notify/main/quick-install.sh | sudo bash
🗑️ Удаление
bash
telegram-notify uninstall
или

bash
sudo bash uninstall.sh
🔧 Конфигурация
Файл конфигурации: /etc/security-notify/config.conf

bash
TELEGRAM_BOT_TOKEN="your_token"
CHAT_ID="your_chat_id"
TOPIC_ID="your_topic_id"
ENABLE_SSH_SUCCESS=true
ENABLE_SSH_FAIL=true
ENABLE_GEO_LOOKUP=true
WHITELIST_IPS="192.168.1.100,10.0.0.50"
Редакт��ровать:

bash
sudo nano /etc/security-notify/config.conf
или через меню:

bash
telegram-notify  # → 3. Настройки
📊 Примеры уведомлений
SSH Login
Code
✅ SSH LOGIN SUCCESS
━━━━━━━━━━━━━━━━━━━━
👤 User: admin
🌐 IP: 95.123.45.67
📍 Location: Moscow, Russia
🏢 ISP: Your ISP
🖥 Server: web-server-1
🕐 Time: 2026-02-13 14:30:15
━━━━━━━━━━━━━━━━━━━━
New IP Warning
Code
⚠️ NEW IP ADDRESS ⚠️
━━━━━━━━━━━━━━━━━━━━
👤 User: admin
🌐 IP: 185.220.101.50
📍 Location: Beijing, China
🏢 ISP: Unknown VPN
🖥 Server: web-server-1
🕐 Time: 2026-02-13 14:35:20
━━━━━━━━━━━━━━━━━━━━
Fail2Ban Alert
Code
🚨 FAIL2BAN ALERT 🚨
━━━━━━━━━━━━━━━━━━━━
🔐 Jail: SSH
🌐 IP: 103.45.67.89
📍 Location: Mumbai, India
🏢 ISP: Hosting Provider
❌ Failed Attempts: 5
🖥 Server: web-server-1
🕐 Time: 2026-02-13 14:40:10
━━━━━━━━━━━━━━━━━━━━
⚠️ IP HAS BEEN BANNED ⚠️
🛠️ Требования
Ubuntu 20.04+ / Debian 10+
Root доступ
curl или wget
systemd
🚨 Устранение неполадок
Команда не найдена
bash
which telegram-notify
# Если не найдена, переустановите:
curl -fsSL https://raw.githubusercontent.com/pogosste/telegram-notify/main/quick-install.sh | sudo bash
Уведомления не приходят
bash
telegram-notify status    # Проверить конфигурацию
telegram-notify test      # Отправить тестовое сообщение
tail -f /var/log/security-notify.log  # Посмотреть логи
Fail2Ban не работает
bash
sudo systemctl status fail2ban
sudo fail2ban-client status sshd
sudo journalctl -u fail2ban -n 50
📝 Документация
Changelog
🤝 Вклад в проект
Contributions are welcome!

Fork the repository
Create your feature branch (git checkout -b feature/AmazingFeature)
Commit your changes (git commit -m 'Add some AmazingFeature')
Push to the branch (git push origin feature/AmazingFeature)
Open a Pull Request
📄 Лицензия
MIT License - см. файл LICENSE

👤 Автор
pogosste

GitHub: @pogosste
⭐ Поддержка проекта
Если проект оказался полезным, поставьте звезду ⭐ на GitHub!

📈 Статистика
![GitHub stars](https://img.shields.io/github/stars/pogosste/telegram-notify?style=social) ![GitHub forks](https://img.shields.io/github/forks/pogosste/telegram-notify?style=social) ![GitHub issues](https://img.shields.io/github/issues/pogosste/telegram-notify)

Made with ❤️ for VPS security
