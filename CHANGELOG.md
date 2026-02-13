# Changelog

All notable changes to this project will be documented in this file.

## [2.1.0] - 2026-02-13

### Added
- Global `telegram-notify` command
- Quick installation via curl
- Command-line arguments support (test, status, logs, etc.)
- Interactive management menu
- Telegram Topics support
- Emoji formatting for better readability
- New IP address detection with warning
- PAM_TYPE filtering to prevent duplicate notifications
- Silent mode for install/uninstall scripts

### Fixed
- Double notification issue on SSH login
- Notification on SSH session close
- Geo-location API fallback
- Fail2Ban installation detection

### Changed
- Improved message formatting with emojis
- Better error handling in scripts
- Enhanced logging system
- Restructured codebase for better maintainability

## [2.0.0] - 2026-02-12

### Added
- Initial public release
- SSH login notifications
- Fail2Ban integration
- Geo-location support
- Whitelist IP functionality
- Installation and uninstallation scripts
- Comprehensive logging

### Features
- Telegram notifications
- PAM integration
- Customizable configuration
- Multiple server support
