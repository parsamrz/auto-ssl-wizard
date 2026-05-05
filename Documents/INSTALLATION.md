# SSL Wizard - Installation & Setup Guide

## System Requirements

- **OS**: Ubuntu 22.04 LTS or Ubuntu 24.04 LTS
- **Architecture**: x86_64 or ARM64
- **Network**: Public-facing server with port 80/443 accessible
- **Permissions**: root or sudo privileges

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/parsamrz/auto-ssl-wizard.git
cd auto-ssl-wizard
chmod +x ssl-wizard.sh
```

### 2. Run the Script

```bash
sudo ./ssl-wizard.sh example.com
```

### 3. For Multiple Domains

```bash
sudo ./ssl-wizard.sh example.com www.example.com api.example.com
```

## Detailed Installation

### Step 1: Prerequisites

Ensure your system is up-to-date:

```bash
sudo apt update
sudo apt upgrade -y
```

### Step 2: Clone & Setup

```bash
git clone https://github.com/parsamrz/auto-ssl-wizard.git
cd auto-ssl-wizard
chmod +x ssl-wizard.sh
```

### Step 3: First Run

The script will automatically detect and install missing dependencies:

```bash
sudo ./ssl-wizard.sh your-domain.com
```

### Step 4: Dependencies Auto-Installation

The script installs the following dependencies if missing:

- **certbot** - Let's Encrypt certificate manager
- **dig** - DNS lookup utility
- **ss/netstat** - Network diagnostics
- **curl** - HTTP client for IP detection

## Manual Dependency Installation

If auto-installation fails, install dependencies manually:

```bash
# Install certbot
sudo apt install -y certbot

# Install DNS utilities
sudo apt install -y dnsutils

# Install network tools
sudo apt install -y net-tools

# Install curl
sudo apt install -y curl
```

## Certificate File Locations

After successful issuance, certificates are stored in:

```
output/
└── example.com/
    ├── live/
    │   ├── privkey.pem        (600 permissions)
    │   ├── cert.pem           (644 permissions)
    │   ├── chain.pem          (644 permissions)
    │   └── fullchain.pem      (644 permissions)
    ├── archive/
    │   └── original_[timestamp]/
    └── logs/
        └── issuance.log
```

Also available in Let's Encrypt:

```
/etc/letsencrypt/live/example.com/
```

## Web Server Integration

### Nginx Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /path/to/ssl-wizard/output/example.com/live/fullchain.pem;
    ssl_certificate_key /path/to/ssl-wizard/output/example.com/live/privkey.pem;
}
```

### Apache Configuration

```apache
<VirtualHost *:443>
    ServerName example.com
    
    SSLEngine on
    SSLCertificateFile /path/to/ssl-wizard/output/example.com/live/cert.pem
    SSLCertificateKeyFile /path/to/ssl-wizard/output/example.com/live/privkey.pem
    SSLCertificateChainFile /path/to/ssl-wizard/output/example.com/live/chain.pem
</VirtualHost>
```

## Troubleshooting

### Port 80/443 Already in Use

If the script detects port conflicts:

1. The script will ask for permission to terminate the process
2. Or you can manually free ports before running the script
3. For HTTP-01 challenge, ensure port 80 is free

### DNS Not Resolving

1. Check your DNS provider's control panel
2. Verify the A record points to your server IP
3. Use `dig example.com` to test DNS resolution
4. Wait 5-10 minutes for DNS propagation

### Certificate Issuance Failed

1. Check the logs: `cat output/example.com/logs/issuance.log`
2. Verify Let's Encrypt status page for service issues
3. Check rate limits (50 certificates per domain per week)

## Automatic Renewal

Set up automatic certificate renewal:

```bash
# Add to crontab
0 3 * * * /usr/bin/certbot renew --quiet
```

## Support

For issues and questions:
1. Check the logs: `cat output/[domain]/logs/issuance.log`
2. Review troubleshooting above
3. Open an issue on GitHub

---

**Version**: 1.0.0  
**License**: MIT
