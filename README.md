# SSL Wizard - Automated Let's Encrypt Certificate Management

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Ubuntu](https://img.shields.io/badge/ubuntu-22.04%20%7C%2024.04-orange)
![Bash](https://img.shields.io/badge/bash-5.0%2B-green)

**A professional Bash-based wizard for Ubuntu servers that automates the issuance and management of Let's Encrypt SSL/TLS certificates.**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Requirements](#requirements)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage](#-usage)
- [Configuration](#-configuration)
- [Architecture](#-architecture)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#license)
- [Support](#support)

---

## Overview

**SSL Wizard** is a comprehensive solution for automating SSL/TLS certificate provisioning on Ubuntu/Debian servers. It eliminates manual pre-flight checks, DNS validation, and Certbot configuration by providing an interactive wizard that handles everything automatically.

### Why SSL Wizard?

Managing SSL certificates manually is error-prone and time-consuming:
- ❌ Repetitive pre-checks (DNS, ports, dependencies)
- ❌ Manual Certbot command execution
- ❌ Unclear error messages and troubleshooting
- ❌ No organized certificate storage
- ❌ Complex wildcard certificate validation

**SSL Wizard solves all of this:**
- ✅ Automated system diagnostics
- ✅ Intelligent dependency management
- ✅ Real-time DNS validation with automatic cache clearing
- ✅ Interactive challenge type selection
- ✅ Provider-specific DNS instructions
- ✅ Professional color-coded output
- ✅ Comprehensive logging
- ✅ Organized certificate storage

---

## 🎯 Features

### System Diagnostics
- **Public IP Detection** - Retrieves server's public IP with multiple fallback sources
- **OS Validation** - Detects and validates Ubuntu/Debian distribution
- **Port Checking** - Verifies ports 80 and 443 availability
- **DNS Configuration** - Displays configured nameservers
- **Process Identification** - Identifies which process occupies ports

### Dependency Management
- **Certbot Installation** - Auto-installs via snap (primary) or apt (fallback)
- **Tool Validation** - Checks for curl, dig, ss/netstat
- **Smart Installation** - Prompts user for missing dependencies
- **Version Tracking** - Logs all tool versions

### DNS Validation
- **Real-Time Polling** - Checks DNS every 5 seconds
- **Automatic Cache Clearing** - Flushes OS DNS cache before each query
- **Multiple DNS Servers** - Validates against Google (8.8.8.8) and Cloudflare (1.1.1.1)
- **Propagation Tracking** - Measures DNS propagation time
- **DNS Mismatch Handling** - Detects and allows override of mismatches

### Challenge Type Selection
- **DNS TXT Challenge** - For all certificate types (manual entry)
- **HTTP-01 Challenge** - For single/multi-domain certificates
- **ACME DNS API** - For advanced automation

### Certificate Management
- **Single-Domain** - Issue certificates for single domain
- **Multi-Domain** - Cover multiple domains in single certificate
- **Wildcard** - Support for *.example.com with manual DNS challenge
- **Rate Limit Warning** - Alerts about Let's Encrypt limits
- **TOS Acceptance** - Interactive agreement to Terms of Service

### Provider-Specific Guidance
Supports DNS entry instructions for:
- Cloudflare
- Amazon Route 53 (AWS)
- DigitalOcean
- Namecheap
- GoDaddy
- Manual/Other providers

### Output Organization
- **Structured Directories** - `certs-out/<domain>/{live,archive,logs}`
- **Certificate Files** - cert.pem, privkey.pem, chain.pem, fullchain.pem
- **Secure Permissions** - 600 for private keys, 644 for certificates
- **Timestamped Archives** - Backup existing certificates
- **Detailed Logging** - Complete execution logs with timestamps

### Professional UI
- **Color-Coded Output** - Green (success ✓), Yellow (warning ⚠), Red (error ✗)
- **Formatted Sections** - Professional dividers and headers
- **Progress Indicators** - Real-time polling progress display
- **Interactive Prompts** - User-friendly yes/no questions
- **ASCII Art Banner** - Professional greeting display

### Logging & Audit Trail
- **Timestamped Logs** - Every operation recorded with precise timestamp
- **Dual Output** - Logs to both console and file
- **Log Levels** - INFO, WARN, ERROR, DEBUG
- **Complete History** - Full Certbot output capture
- **User Tracking** - Records all user inputs and decisions

### Error Handling
- **Graceful Failures** - Proper error messages and recovery
- **Retry Logic** - Automatic retry for transient failures
- **Cleanup** - Removes temporary files on exit
- **Exit Codes** - Proper status codes for scripting

---

## 📸 Screenshots

### System Diagnostics Output
```
════════════════════════════════════════════════════════════════════════════════
                          SSL Wizard - System Diagnostics
════════════════════════════════════════════════════════════════════════════════

  Public IP Address: 50.7.87.3
  Operating System: Ubuntu 24.04 LTS
  Kernel: 6.1.0-20-generic
  
  Port 80 (HTTP):    ✓ Available
  Port 443 (HTTPS):  ✓ Available
  
  Nameservers: 8.8.8.8, 1.1.1.1, 9.9.9.9
  
════════════════════════════════════════════════════════════════════════════════
                          Dependency Check
════════════════════════════════════════════════════════════════════════════════

  ✓ certbot v2.6.0
  ✓ dig (DNS utilities)
  ✓ ss (network diagnostics)
  ✓ curl (HTTP client)

All dependencies verified!
```

### Challenge Type Selection
```
Select validation challenge method:

[1] DNS TXT Record Challenge (Manual)
    → For all certificate types (single, multi, wildcard)
    → You manually add DNS TXT record
    → Best for: Wildcard certs, full control

[2] HTTP-01 Challenge (Port 80)
    → For single/multi-domain certificates only
    → Requires port 80 to be available
    → Best for: Standard certs, automated flows

[3] ACME DNS API (Advanced)
    → For automation with DNS provider integration
    → Requires API credentials (not yet configured)
    → Best for: Repeated issuances

Enter choice [1-3]:
```

### Real-Time DNS Validation
```
Checking DNS propagation...
[████████░░░░░░░░░░] Attempt 5/36 (50s elapsed)

Expected: aB3xYz9kL2mNoPqRsT1uVwXyZaBcDeF4gHiJk
Current:  Not found (checking again in 5s, fresh query)

✓ DNS Record Verified!
Record: _acme-challenge.example.com
Value:  aB3xYz9kL2mNoPqRsT1uVwXyZaBcDeF4gHiJk
Method: Fresh query (cache cleared)
Time:   7 seconds
```

---

## Requirements

### System Requirements
- **OS**: Ubuntu 22.04 LTS or Ubuntu 24.04 LTS
- **Bash**: 5.0 or higher
- **Sudo**: Root or sudo privileges required
- **Internet**: Connection to Let's Encrypt and DNS servers

### Tools (Auto-Installed)
- **certbot** - Let's Encrypt client
- **curl** - HTTP client
- **dig** - DNS lookup utility
- **ss** or **netstat** - Network diagnostics

### Optional
- **xclip** or **xsel** - For clipboard support (DNS token copy)

---

## 🚀 Installation

### Method 1: Direct Download
```bash
# Navigate to project directory
cd /path/to/your/project

# Download the script
git clone https://github.com/parsamrz/auto-ssl-wizard.git
cd auto-ssl-wizard

# Make executable
chmod +x ssl-wizard.sh
```

### Method 2: Copy to System Path (Optional)
```bash
# Copy to /usr/local/bin for system-wide access
sudo cp ssl-wizard.sh /usr/local/bin/ssl-wizard
sudo chmod +x /usr/local/bin/ssl-wizard

# Now run from anywhere
ssl-wizard example.com
```

### Initial Setup
```bash
# First run will:
# 1. Create output directory structure
# 2. Auto-install missing dependencies
# 3. Display system diagnostics
# 4. Prompt for domain and configuration

./ssl-wizard.sh example.com
```

---

## 🎯 Quick Start

### Issue a Certificate for Single Domain
```bash
./ssl-wizard.sh example.com

# Follow the prompts:
# 1. Review system diagnostics
# 2. Select challenge type (DNS TXT recommended)
# 3. Enter email for notifications
# 4. Accept Let's Encrypt Terms of Service
# 5. Add DNS record (if using DNS challenge)
# 6. Wait for certificate issuance

# Certificates saved to: ./output/example.com/live/
```

### Issue a Multi-Domain Certificate
```bash
./ssl-wizard.sh example.com,www.example.com

# Same flow as above, but validates multiple domains
# Single certificate covers both domains
```

### Issue a Wildcard Certificate
```bash
./ssl-wizard.sh \*.example.com

# 1. Select DNS TXT challenge (required for wildcards)
# 2. Add TXT record to _acme-challenge.example.com
# 3. Real-time monitoring verifies DNS propagation
# 4. Certificate issued for *.example.com
```

---

## 📖 Usage

### Basic Command
```bash
./ssl-wizard.sh <domain> [options]
```

### Examples

**Single domain:**
```bash
./ssl-wizard.sh example.com
```

**Multiple domains:**
```bash
./ssl-wizard.sh example.com,www.example.com,api.example.com
```

**With options:**
```bash
# Enable debug mode
DEBUG_MODE=true ./ssl-wizard.sh example.com

# Quiet mode (logs only, no console output)
QUIET_MODE=true ./ssl-wizard.sh example.com

# Specify custom output directory
OUTPUT_DIR=/var/ssl ./ssl-wizard.sh example.com
```

### Interactive Prompts

The wizard will ask you:

1. **Challenge Type** - Choose how to prove domain ownership
   - DNS TXT (manual)
   - HTTP-01 (automatic)
   - ACME DNS API (advanced)

2. **Email Address** - For Let's Encrypt notifications
   - Recommended for renewal reminders
   - Optional (can skip)

3. **Terms of Service** - Accept Let's Encrypt ToS
   - Required to proceed
   - Yes/No confirmation

4. **DNS Provider** (if using DNS challenge)
   - Select your DNS provider
   - View provider-specific instructions
   - Manually add TXT record

5. **Confirmation** - Verify DNS record is set
   - System automatically polls DNS
   - Displays propagation time
   - Proceeds when record detected

---

## ⚙️ Configuration

### Environment Variables

```bash
# Debug mode - verbose logging
DEBUG_MODE=true ./ssl-wizard.sh example.com

# Quiet mode - suppress console output
QUIET_MODE=true ./ssl-wizard.sh example.com

# Custom output directory
OUTPUT_DIR=/var/ssl ./ssl-wizard.sh example.com

# Custom DNS servers
DNS_SERVERS="8.8.8.8 1.1.1.1" ./ssl-wizard.sh example.com

# DNS polling timeout (seconds)
DNS_POLL_TIMEOUT=300 ./ssl-wizard.sh example.com
```

### Configuration File (Optional)
Create `.ssl-wizard.conf` in the script directory:

```bash
# Enable debug mode
DEBUG_MODE=true

# DNS polling interval (seconds)
DNS_POLL_INTERVAL=5

# DNS polling maximum attempts
DNS_POLL_MAX_ATTEMPTS=36  # 3 minutes total

# Output directory
OUTPUT_DIR="./output"

# Log level (INFO, WARN, ERROR, DEBUG)
LOG_LEVEL="INFO"
```

---

## 🏗️ Architecture

### Directory Structure
```
auto-ssl-wizard/
├── ssl-wizard.sh                    # Main script (637 lines)
│
├── output/                          # Certificate storage
│   └── {domain}/
│       ├── live/                    # Current certificates
│       │   ├── cert.pem             # Certificate
│       │   ├── privkey.pem          # Private key (600 perms)
│       │   ├── chain.pem            # Certificate chain
│       │   └── fullchain.pem        # Certificate + chain
│       ├── archive/                 # Backup of previous certs
│       └── logs/
│           └── issuance.log         # Timestamped execution log
│
├── .tmp/                            # Temporary files (auto-cleaned)
│
├── README.md                        # This file
├── prd/
│   └── prd1.1.md                    # Product Requirements Document
│
├── openspec/
│   └── changes/
│       └── implement-ssl-wizard/    # Implementation specs
│           ├── proposal.md
│           ├── design.md
│           ├── tasks.md
│           └── specs/               # Detailed requirements
│
└── documentation/
    ├── SSL_WIZARD_README.md
    ├── SSL_WIZARD_IMPLEMENTATION.md
    ├── SSL_WIZARD_CHECKLIST.md
    └── SSL_WIZARD_INDEX.md
```

### Script Sections

1. **Configuration** (lines 1-50)
   - Script metadata
   - Directory paths
   - Timeouts and network settings
   - ANSI color constants

2. **Logging** (lines 51-100)
   - Log function definitions
   - File/console output
   - Timestamp formatting

3. **Utilities** (lines 101-200)
   - Formatted output functions
   - User prompt functions
   - Error box displays

4. **System Diagnostics** (lines 201-350)
   - IP detection
   - OS detection
   - Port checking
   - DNS configuration

5. **Dependency Management** (lines 351-500)
   - Certbot installation
   - Tool detection
   - Auto-installation

6. **DNS Validation** (lines 501-800) - *Planned*
   - Domain parsing
   - A record lookup
   - Multi-domain validation

7. **Port Management** (lines 801-1000) - *Planned*
   - Process detection
   - Process termination
   - Port verification

8. **Real-Time DNS Polling** (lines 1001-1200) - *Planned*
   - 5-second polling
   - DNS cache clearing
   - Propagation tracking

9. **Certificate Issuance** (lines 1201-1500) - *Planned*
   - Certbot integration
   - Challenge selection
   - TOS handling

10. **File Organization** (lines 1501-1700) - *Planned*
    - Directory creation
    - File copying
    - Permission setting

### Implementation Phases

**Phase 1: Foundation** ✅ COMPLETE
- Setup, diagnostics, dependencies
- 17/156 tasks (10.9%)

**Phase 2: DNS & Ports** ⏳ NEXT
- DNS validation, real-time polling, cache clearing
- 39 tasks

**Phase 3: Certificates** ⏳ PLANNED
- Challenge selection, issuance
- 28 tasks

**Phase 4: Polish** ⏳ PLANNED
- File organization, logging, error handling
- 20 tasks

**Phase 5: Testing** ⏳ PLANNED
- Comprehensive testing, documentation
- 37 tasks

---

## 🐛 Troubleshooting

### Common Issues

#### "Certbot not found"
```bash
# Solution: Let the script auto-install
# Or manually install:
sudo apt-get update && sudo apt-get install certbot

# Or via snap:
sudo snap install certbot --classic
```

#### "Port 80 is in use"
```bash
# The script will detect and offer to terminate
# If automatic termination fails, manually check:
sudo netstat -tlnp | grep :80

# Or identify process:
sudo lsof -i :80

# Kill the process:
sudo kill -9 <PID>
```

#### "DNS validation timeout"
```bash
# Common causes:
# 1. DNS record not added to your provider
# 2. DNS changes haven't propagated yet (can take 1-5 minutes)
# 3. TTL is too high (set to 300 seconds)

# Check DNS manually:
dig _acme-challenge.example.com TXT
dig _acme-challenge.example.com TXT @8.8.8.8
dig _acme-challenge.example.com TXT @1.1.1.1

# If using Cloudflare, ensure:
# - "Proxy status" is set to "DNS only" (not "Proxied")
# - TTL is set to minimum (1 minute)
```

#### "Rate limit exceeded"
```bash
# Let's Encrypt limits:
# - 50 certificates per domain per 3 hours
# - 168-hour (7 day) lockout after exceeding

# Solution: Wait 3 hours before retrying
# Or use a different domain/subdomain for testing

# Check rate limit status:
dig _acme-challenge.example.com TXT +short
```

#### "DNS cache still shows old record"
```bash
# Solution: System automatically clears DNS cache
# If issues persist, manually clear:

# On Ubuntu with systemd-resolved:
sudo systemctl restart systemd-resolved

# Or:
resolvectl flush-caches

# On systems with nscd:
sudo nscd -i hosts

# Verify cache cleared:
dig example.com A +nocmd +noall +answer
```

#### "Permission denied on private key"
```bash
# Script sets permissions automatically (600)
# If issues occur, manually fix:

ls -la output/example.com/live/privkey.pem
# Should show: -rw------- (600 permissions)

# Fix if needed:
chmod 600 output/example.com/live/privkey.pem

# Verify:
ls -la output/example.com/live/
# cert.pem: -rw-r--r-- (644)
# privkey.pem: -rw------- (600)
```

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
DEBUG_MODE=true ./ssl-wizard.sh example.com

# This will:
# 1. Show all DNS queries and results
# 2. Display cache clearing operations
# 3. Log all system calls
# 4. Show network diagnostics
# 5. Print full Certbot output
```

### Check Logs

Execution logs saved to: `output/{domain}/logs/issuance.log`

```bash
# View logs
cat output/example.com/logs/issuance.log

# View last 50 lines
tail -50 output/example.com/logs/issuance.log

# Monitor in real-time
tail -f output/example.com/logs/issuance.log
```

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/parsamrz/auto-ssl-wizard.git
cd auto-ssl-wizard

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
nano ssl-wizard.sh

# Test your changes
bash ssl-wizard.sh test.example.com

# Validate bash syntax
bash -n ssl-wizard.sh

# Check with shellcheck (if installed)
shellcheck ssl-wizard.sh
```

### Commit Guidelines

```bash
# Use clear commit messages
git commit -m "feat: add DNS cache clearing for real-time validation"

# Or:
git commit -m "fix: handle systems without DNS cache service"
git commit -m "docs: update README with troubleshooting section"
git commit -m "test: add validation for Cloudflare provider instructions"
```

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commits
4. Test thoroughly
5. Update documentation
6. Submit pull request with description

### Code Guidelines

- Use `set -euo pipefail` at script start
- Use readonly for constants
- Quote all variables
- Comment complex logic
- Follow existing style
- Test on Ubuntu 22.04 and 24.04

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

MIT License Summary:
- ✅ Use for any purpose
- ✅ Modify and distribute
- ✅ Private use
- ⚠️ Include license and copyright notice
- ❌ Hold liable

---

## 📞 Support

### Getting Help

1. **Check Documentation**
   - [README.md](README.md) (this file)
   - [SSL_WIZARD_README.md](SSL_WIZARD_README.md)
   - [SSL_WIZARD_IMPLEMENTATION.md](SSL_WIZARD_IMPLEMENTATION.md)

2. **Enable Debug Mode**
   ```bash
   DEBUG_MODE=true ./ssl-wizard.sh example.com
   ```

3. **Check Logs**
   ```bash
   tail -50 output/example.com/logs/issuance.log
   ```

4. **Report Issues**
   - Check existing issues first
   - Provide: OS version, error message, logs
   - Include: steps to reproduce

### Community

- 🐦 Twitter: [@parsamrz](https://twitter.com/parsamrz)
- 🌐 Website: [parsamrz.com](https://parsamrz.com)
- 📧 Email: contact@parsamrz.com

---

## 🎓 Learning Resources

### Let's Encrypt & SSL/TLS
- [Let's Encrypt Getting Started](https://letsencrypt.org/getting-started/)
- [SSL/TLS Concepts](https://en.wikipedia.org/wiki/Secure_Sockets_Layer)
- [DNS Validation](https://tools.ietf.org/html/rfc8555#section-8.4)

### Bash Scripting
- [Bash Guide for Beginners](https://www.gnu.org/software/bash/manual/)
- [ShellCheck](https://www.shellcheck.net/) - Bash linter
- [Google Bash Style Guide](https://google.github.io/styleguide/shellstyle.html)

### DNS & Networking
- [DNS Fundamentals](https://www.cloudflare.com/learning/dns/what-is-dns/)
- [TXT Records](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)
- [ACME Protocol](https://tools.ietf.org/html/rfc8555)

---

## 🗺️ Roadmap

### Planned Features (v1.1+)

- **Automated Renewal** - Cron job setup for auto-renewal
- **Web UI** - Browser-based certificate management
- **Multi-Server** - Manage certificates across servers
- **Docker Support** - Container deployment
- **Additional Providers** - DNS API integrations
- **Metrics & Monitoring** - Certificate expiry tracking
- **Backup & Recovery** - Automated certificate backups

---

## 📊 Project Status

```
Phase 1: Foundation      [████████████████████] 100% COMPLETE
Phase 2: DNS & Ports     [░░░░░░░░░░░░░░░░░░░░]   0% planned
Phase 3: Certificates   [░░░░░░░░░░░░░░░░░░░░]   0% planned
Phase 4: Polish         [░░░░░░░░░░░░░░░░░░░░]   0% planned
Phase 5: Testing        [░░░░░░░░░░░░░░░░░░░░]   0% planned

Overall: 17/156 tasks complete (10.9%)
```

---

## 🙏 Acknowledgments

- **Let's Encrypt** - Free, automated, and open certificate authority
- **Certbot** - Official Let's Encrypt client
- **Bash Community** - Excellent scripting resources
- **Ubuntu/Debian** - Reliable Linux distributions

---

## 📝 Changelog

### v1.0.0 (2026-05-05)
- ✅ Initial release
- ✅ System diagnostics
- ✅ Dependency management
- ✅ Professional logging
- ✅ Color-coded output
- ✅ Error handling

### v0.9.0 (2026-05-05)
- 🎯 Foundation and planning complete
- 📋 156 tasks identified and tracked
- 📚 OpenSpec documentation created

---

<div align="center">

**Made with ❤️ by [Parsamrz](https://github.com/parsamrz)**

[⬆ Back to top](#ssl-wizard---automated-lets-encrypt-certificate-management)

</div>