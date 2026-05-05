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

## Configuration

### Environment Variables

You can customize the script behavior with environment variables:

```bash
# Enable debug mode
DEBUG_MODE=true sudo ./ssl-wizard.sh example.com

# Enable quiet mode (minimal output)
QUIET_MODE=true sudo ./ssl-wizard.sh example.com

# Set custom output directory
OUTPUT_DIR=/opt/ssl-certs sudo ./ssl-wizard.sh example.com
```

### Timeout Configuration

Edit `ssl-wizard.sh` to adjust timeouts (in seconds):

```bash
DNS_CHECK_TIMEOUT=10      # DNS lookup timeout
HTTP_CHECK_TIMEOUT=5      # HTTP request timeout
CERT_CHECK_TIMEOUT=10     # Certificate check timeout
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
4. Review error messages for specific issues

### Let's Encrypt Rate Limits

If you hit rate limits:

```
Error: (TooManyRequests) :: There were too many requests of this type 
```

Wait until the next rate limit window or use the staging environment:

```bash
# Add to /etc/letsencrypt/renewal/example.com.conf
staging = true

# Then run renewal
sudo certbot renew --dry-run
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
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
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

## Automatic Renewal

Set up automatic certificate renewal:

```bash
# Add to crontab
0 3 * * * /usr/bin/certbot renew --quiet

# Or use systemd timer (if using snap certbot)
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

## Advanced Topics

### Using Let's Encrypt Staging Environment

For testing without rate limit concerns:

```bash
# Edit /etc/letsencrypt/cli.ini
# Add: server = https://acme-staging-v02.api.letsencrypt.org/directory
```

### DNS API Integration (Future)

Support for automated DNS updates via provider APIs is planned for version 2.0

### Custom Certbot Options

Edit the `issue_single_domain_certificate()` function to add custom options:

```bash
cert_command="$cert_command --rsa-key-size 4096"
cert_command="$cert_command --preferred-chain 'ISRG Root X1'"
```

## Security Best Practices

1. **Protect Private Keys**: The script sets permissions to 600 (read-only by owner)
2. **Use HTTPS**: Always use fullchain.pem with privkey.pem in production
3. **Monitor Renewal**: Set up alerts for certificate expiration
4. **Backup Certificates**: Keep backups of issued certificates
5. **Run as Root**: The script requires root to modify system files

## Support & Issues

For issues, questions, or feature requests:

1. Check the logs: `cat output/[domain]/logs/issuance.log`
2. Review troubleshooting section above
3. Open an issue on GitHub: https://github.com/parsamrz/auto-ssl-wizard/issues
4. Include relevant logs and error messages

## License

This project is licensed under the MIT License.

## Version History

- **1.0.0** (Current) - Full SSL/TLS certificate management
  - Phase 1: Diagnostics & Dependencies
  - Phase 2: DNS & Port Management
  - Phase 3: Certificate Issuance
  - Phase 4: File Organization
  - Phase 5: Testing & Documentation
