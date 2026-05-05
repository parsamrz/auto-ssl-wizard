## Why

SSL certificate issuance is a critical but error-prone manual process that DevOps engineers repeat frequently. Current workflow involves fragmented Certbot commands, manual system pre-checks (DNS, port availability, dependencies), and often results in failed challenges or service conflicts. This wizard automates the entire process into a single interactive command that ensures the server is fully prepared before requesting a certificate, guaranteeing successful issuance every time.

## What Changes

- **New Bash-based interactive wizard** providing a step-by-step UI for certificate issuance
- **Automated system diagnostics** displaying OS version, public IP, and port status
- **Dependency auto-resolution** detecting and installing Certbot and required tools
- **DNS validation** checking that domain records point to the current server
- **Port conflict detection and resolution** automatically killing processes occupying Port 80
- **Multi-certificate support** enabling single domain, multi-domain, and wildcard certificate issuance
- **Structured file organization** saving certificates, keys, chains, and logs in a predictable local folder structure
- **Comprehensive logging** recording every step for troubleshooting

## Capabilities

### New Capabilities

- `system-diagnostics`: Display server public IP, OS version, and availability of ports 80/443
- `dependency-management`: Check for Certbot and related tools; auto-install via snap or apt if missing
- `dns-validation`: Verify that provided domains' DNS records point to the server's current IP address
- `port-conflict-resolution`: Detect processes occupying Port 80 and prompt user to terminate them before standalone mode
- `certificate-issuance`: Support issuance of single, multi-domain, and wildcard SSL certificates via Certbot
- `file-organization`: Organize and save certificate, private key, chain, and logs to `./certs-out/<domain>/` structure
- `manual-dns-challenge`: Support manual DNS TXT record entry for wildcard certificate validation
- `wizard-ui`: Interactive CLI with color-coded output (green/yellow/red) for clear status messaging

### Modified Capabilities

<!-- None - this is a new project -->

## Impact

- **Systems**: Linux/Ubuntu (22.04/24.04 LTS) systems with sudo access
- **Dependencies**: Requires Certbot, curl, dig/nslookup, netstat/ss, and standard Unix utilities
- **Integration**: Wraps Certbot CLI; integrates with Let's Encrypt ACME protocol
- **File I/O**: Creates and manages certificate storage directories within script root
- **Rate Limiting**: Subject to Let's Encrypt rate limits (168-hour lockout per domain after threshold)
- **User Workflows**: Targets DevOps engineers and system administrators managing manual certificate deployments
