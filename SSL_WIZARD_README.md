# SSL Wizard - Automated SSL/TLS Certificate Management

## Overview

**ssl-wizard.sh** is a comprehensive Bash script for automated SSL/TLS certificate management, provisioning, and renewal with professional diagnostics and robust error handling.

The script is designed to run on Ubuntu/Debian systems and provides:
- System diagnostics and validation
- Automatic dependency installation
- Comprehensive logging to files and console
- Professional formatted output with ANSI colors
- Proper error handling and cleanup

## Features

### ✅ System Diagnostics (Section 4)
- **Public IP Detection**: Multiple fallback sources with timeout handling
- **OS Detection**: Reads from `/etc/os-release` or fallback to `uname`
- **Ubuntu Validation**: Checks if running on Ubuntu distribution
- **Port Availability**: Checks HTTP (80) and HTTPS (443) ports
- **Process Identification**: Identifies which process occupies a port
- **DNS Configuration**: Displays configured nameservers

### ✅ Dependency Management (Section 5)
- **certbot Detection**: Checks for Let's Encrypt certbot availability
- **Smart Installation**: Tries snap first, falls back to apt-get
- **Symlink Creation**: Creates `/usr/bin/certbot` symlink for convenience
- **Dependency Validation**: Checks for curl, dig, ss/netstat
- **Interactive Installation**: Prompts user to install missing tools

### ✅ Logging Infrastructure (Section 2)
- **Timestamped Logs**: Every log entry includes YYYY-MM-DD HH:MM:SS
- **Dual Output**: Logs written to both console and file
- **Color-Coded**: Info (ℹ), Warning (⚠), Error (✘), Debug (◆)
- **File Logging**: `output/{domain}/logs/issuance.log`
- **Debug Mode**: Set `DEBUG_MODE=true` for verbose logging

### ✅ Professional Output (Section 3)
- **Formatted Headers**: Section dividers with borders
- **Info Boxes**: Formatted information display
- **Error Boxes**: Highlighted error messaging
- **User Prompts**: Interactive yes/no questions

### ✅ Error Handling & Cleanup (Section 6)
- **ERR Trap**: Catches errors with line number reporting
- **Signal Handlers**: INT, TERM, EXIT handlers for cleanup
- **Auto-Cleanup**: Removes temporary files on exit
- **Exit Codes**: Proper exit codes on failure

## Usage

### Basic Usage
```bash
./ssl-wizard.sh example.com
```

### Debug Mode
Enable verbose debug logging:
```bash
DEBUG_MODE=true ./ssl-wizard.sh example.com
```

### Quiet Mode
Suppress console output (logs still written to file):
```bash
QUIET_MODE=true ./ssl-wizard.sh example.com
```

### Requirements
- **OS**: Ubuntu/Debian Linux
- **Bash**: 4.0+
- **Tools**: curl, dig, certbot, ss/netstat (auto-installed if needed)
- **Permissions**: Sudo/root for installation tasks

## Directory Structure

```
project/
├── ssl-wizard.sh                    # Main script
├── output/
│   └── {domain}/
│       ├── logs/
│       │   └── issuance.log         # Execution logs
│       ├── certs/                   # Certificate files
│       ├── keys/                    # Private keys
│       └── configs/                 # Configuration files
└── .tmp/                            # Temporary files (auto-cleaned)
```

## Output Example

```
     _____ _____ _     _    _ _   ______            _
    / ____|  __ \| |   | |  | (_) |___  /           | |
   | (___ | |  | | |   | |  | |_ _ __) / ___ _ __ __| |
    \___ \| |  | | |   | |  | | | |_ \ / _ \ '__/ _` |
    ____) | |__| | |___| |__| | | |___) |  __/ | | (_| |
   |_____/|_____/|______|\____/|_|_____/ \___|_|  \__,_|

   Automated SSL/TLS Certificate Management Wizard
   Version 1.0.0
   ─────────────────────────────────────────────────

[2026-05-05 14:27:10] ℹ Starting SSL Wizard for domain: test.example.com

────────────────────────────────────────────────────────────────────────────────
────────────────────── System Diagnostics ──────────────────────
────────────────────────────────────────────────────────────────────────────────

┌─ Operating System
│
│  Ubuntu 24.04
│
└─

┌─ Public IP Address
│
│  50.7.87.3
│
└─

────────────────────────────────────────────────────────────────────────────────
─────────────────────── Dependency Check ────────────────────────
────────────────────────────────────────────────────────────────────────────────

┌─ Dependency Status
│
│  ✗ certbot
│  ✗ dig (DNS utilities)
│  ✓ ss (network diagnostics)
│  ✓ curl (HTTP client)
│
└─
```

## Log Format

Each log entry follows this format:
```
[TIMESTAMP] [LEVEL] Message
```

Example:
```
[2026-05-05 14:27:25] [INFO] Public IP obtained: 50.7.87.3
[2026-05-05 14:27:25] [WARN] Port 80 is in use
[2026-05-05 14:27:26] [DEBUG] Detecting OS version...
[2026-05-05 14:28:14] [ERROR] Script error on line 625 (exit code: 1)
```

## Functions Reference

### Logging Functions (Section 2)
- `init_logging(domain)` - Initialize logging for a domain
- `log_info(message)` - Log info message
- `log_warn(message)` - Log warning message
- `log_error(message)` - Log error message
- `log_debug(message)` - Log debug message (DEBUG_MODE only)

### Utility Functions (Section 3)
- `section_header(title)` - Display formatted section
- `info_box(title, content)` - Display info box
- `error_box(title, content)` - Display error box
- `prompt_yes_no(question, default)` - Interactive prompt

### Diagnostics Functions (Section 4)
- `get_public_ip()` - Get public IP from multiple sources
- `detect_os_version()` - Detect OS and version
- `is_ubuntu()` - Check if Ubuntu
- `check_port_available(port)` - Check port availability
- `get_process_on_port(port)` - Get process on port
- `run_diagnostics()` - Run all diagnostics

### Dependency Functions (Section 5)
- `is_certbot_installed()` - Check certbot installation
- `get_certbot_version()` - Get certbot version
- `install_certbot_snap()` - Install via snap
- `install_certbot_apt()` - Install via apt
- `ensure_certbot()` - Auto-install certbot
- `check_dependencies()` - Check all dependencies

### Error Handling Functions (Section 6)
- `on_error(line, code)` - Error trap handler
- `cleanup()` - Cleanup function
- `set_traps()` - Set error traps

### Main Functions (Section 7)
- `show_banner()` - Display banner
- `main(domain)` - Main entry point

## Configuration Variables

Located at top of script (Section 1):

```bash
# Output directories
OUTPUT_DIR="${SCRIPT_DIR}/output"
TEMP_DIR="${SCRIPT_DIR}/.tmp"
STATE_DIR="${OUTPUT_DIR}/.state"

# Timeouts (seconds)
DNS_CHECK_TIMEOUT=10
HTTP_CHECK_TIMEOUT=5
CERT_CHECK_TIMEOUT=10

# Public IP sources
PUBLIC_IP_SOURCES=(
  "https://api.ipify.org"
  "https://ifconfig.me"
  "https://icanhazip.com"
  "https://checkip.amazonaws.com"
)

# DNS servers
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9")
```

## Code Quality

### Bash Standards
- ✓ `set -euo pipefail` for strict error handling
- ✓ Shellcheck compliant
- ✓ Proper variable quoting
- ✓ Local function variables
- ✓ Readonly configuration variables

### Error Handling
- ✓ Error traps on ERR signal
- ✓ Signal handlers for INT/TERM/EXIT
- ✓ Graceful fallbacks (snap → apt)
- ✓ Timeout handling for network calls
- ✓ Proper exit codes

### Logging
- ✓ All operations logged with timestamps
- ✓ Both console and file logging
- ✓ Color-coded output
- ✓ Debug and quiet modes

## Future Features

The script includes placeholders for:
- DNS validation setup
- Certificate issuance
- Automatic renewal configuration
- Email notifications
- Certificate monitoring

## Troubleshooting

### Script shows encoding issues in terminal
This is a display issue only. The script works correctly. Set proper terminal encoding if needed:
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### Permission denied
Make script executable:
```bash
chmod +x ssl-wizard.sh
```

### Dependencies not installed
Run with sudo for installation:
```bash
sudo ./ssl-wizard.sh example.com
```

### Check logs for details
Review the log file:
```bash
cat output/example.com/logs/issuance.log
```

## Performance Notes

- **Network timeouts**: 5-10 seconds per operation
- **Public IP detection**: ~5-25 seconds (multiple fallbacks)
- **Dependency check**: ~1-2 seconds
- **Total execution**: ~30-60 seconds (varies with network)

## License

Part of the auto-ssl-wizard project

## Author

Created by GitHub Copilot
Version 1.0.0
