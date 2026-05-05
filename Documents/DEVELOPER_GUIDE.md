# SSL Wizard - Developer Guide

## Architecture Overview

The SSL Wizard is organized into 12 functional sections:

```
SECTION 1: Configuration & Setup
SECTION 2: Logging Infrastructure
SECTION 3: Utility Functions (Formatting & UI)
SECTION 4: System Diagnostics
SECTION 5: Dependency Management
SECTION 6: DNS Validation
SECTION 7: Port Conflict Resolution
SECTION 8: DNS Polling & Cache Clearing
SECTION 9: Certificate Issuance
SECTION 10: File Organization
SECTION 11: Error Handling & Cleanup
SECTION 12: Main Workflow
```

## Key Functions

### DNS Functions (15)
- `parse_domains()` - Parse comma-separated domains
- `get_a_record()` - Retrieve A records via dig/nslookup
- `get_ns_records()` - Retrieve nameserver records
- `validate_dns_match()` - Verify domain DNS settings
- `poll_dns_record()` - Real-time polling (5-sec intervals)
- `flush_dns_cache()` - 4-method fallback cache clearing
- `check_dns_on_multiple_servers()` - Query multiple resolvers

### Port Functions (6)
- `find_processes_on_port()` - Identify process on port
- `terminate_process_graceful()` - SIGTERM with 5s timeout
- `terminate_process_force()` - SIGKILL fallback
- `resolve_port_conflict()` - Complete resolution workflow

### Certificate Functions (15)
- `select_certificate_type()` - Menu (single/multi/wildcard)
- `select_challenge_type()` - Menu (DNS/HTTP/API)
- `issue_single_domain_certificate()` - Issue single cert
- `issue_multi_domain_certificate()` - Issue SAN cert
- `organize_certificate_files()` - Copy and organize files
- `create_issuance_summary()` - Generate summary

### Utility Functions (7)
- `log_info()`, `log_warn()`, `log_error()`, `log_debug()`
- `section_header()` - Formatted section header
- `info_box()` - Formatted info display
- `prompt_yes_no()` - User confirmation

## Configuration

### Timeout Values (seconds)
```bash
DNS_CHECK_TIMEOUT=10
HTTP_CHECK_TIMEOUT=5
CERT_CHECK_TIMEOUT=10
```

### Network Configuration
```bash
PUBLIC_IP_SOURCES=(
  "https://api.ipify.org"
  "https://ifconfig.me"
  "https://icanhazip.com"
  "https://checkip.amazonaws.com"
)
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9")
```

## Adding New Features

### Add New DNS Provider Instructions

Edit `display_challenge_instructions()` to add provider-specific steps.

### Add DNS Cache Method

1. Create function: `flush_dns_cache_newmethod()`
2. Add to fallback chain in `flush_dns_cache()`

### Testing During Development

```bash
# Syntax check
bash -n ssl-wizard.sh

# Debug mode
DEBUG_MODE=true sudo ./ssl-wizard.sh example.com

# Staging environment
# Edit main() to add --staging flag to Certbot
```

## Code Style Guidelines

1. Always quote variables: `"$var"`
2. Use descriptive function names
3. Log important operations
4. Check return codes
5. Comment WHY, not WHAT

## Known Limitations & Future Work

### Current Limitations
- No DNS API integration (v1.0)
- Single-threaded processing
- No built-in renewal automation
- Staging environment not automated

### v2.0 Roadmap
- DNS provider API integration
- Parallel domain processing
- Automated renewal with systemd
- Web UI dashboard
- Certificate monitoring

---

**Version**: 1.0.0  
**License**: MIT
