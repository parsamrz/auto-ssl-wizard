# SSL Wizard - Developer Guide

## Architecture Overview

The SSL Wizard is organized into 12 functional sections:

```
SECTION 1: Configuration & Setup
SECTION 2: Logging Infrastructure
SECTION 3: Utility Functions (Formatting & UI)
SECTION 4: System Diagnostics (Tasks 2.1-2.6)
SECTION 5: Dependency Management (Tasks 3.1-3.6)
SECTION 6: DNS Validation (Tasks 4.1-4.7)
SECTION 7: Port Conflict Resolution (Tasks 5.1-5.7)
SECTION 8: DNS Polling & Cache Clearing (Tasks 5a-5c)
SECTION 9: Certificate Issuance (Tasks 6-7)
SECTION 10: File Organization (Tasks 8)
SECTION 11: Error Handling & Cleanup
SECTION 12: Main Workflow & Entry Point
```

## Key Concepts

### Error Handling
- All functions use `log_error`, `log_warn`, `log_info`, `log_debug`
- Errors trapped with `set_traps` and handled by `on_error`
- Cleanup executed on exit (normal or error)

### DNS Cache Management
- Cache cleared before every DNS query via `flush_dns_cache()`
- Tries 4 methods in order: resolvectl, systemctl, nscd, nscd-restart
- Falls back gracefully if all methods fail
- Each flush attempt logged with method and timestamp

### User Interaction
- `prompt_yes_no()` for confirmation
- `section_header()` for visual separation
- `info_box()` for information display
- `error_box()` for error messages

## Function Reference

### DNS Functions

#### `parse_domains(input)`
Parse comma-separated domain input into array
- **Input**: "example.com,www.example.com"
- **Output**: "example.com www.example.com"
- **Uses**: String manipulation with IFS

#### `get_a_record(domain)`
Get A record for domain via dig/nslookup
- **Input**: Domain name
- **Output**: IP address or empty string
- **Fallback**: dig → nslookup
- **Retry**: None (single attempt)

#### `validate_dns_match(domain, expected_ip)`
Verify domain resolves to expected IP
- **Return**: 0 (match), 1 (mismatch), 2 (lookup failed)
- **Logging**: Logs result and mismatch details

#### `poll_dns_record(domain, expected_value, record_type, max_attempts)`
Poll DNS every 5 seconds until record found
- **Defaults**: record_type='A', max_attempts=36 (3 minutes)
- **Cache**: Flushes before each query
- **Output**: Shows elapsed time when found
- **Return**: 0 (found), 1 (timeout)

#### `detect_dns_cache_method()`
Identify which DNS cache service is running
- **Returns**: "systemd-resolved", "nscd", or "none"
- **Checks**: systemctl is-active, pgrep

#### `flush_dns_cache()`
Attempt DNS cache flush with fallback chain
- **Methods**: resolvectl → systemctl → nscd → nscd-restart
- **Returns**: Name of method used or "none"
- **Logging**: Logs each attempt

### Port Functions

#### `find_processes_on_port(port)`
Find all PIDs using specified port
- **Tools**: ss (preferred) → netstat
- **Output**: One PID per line
- **Return**: 0 (found), 1 (not found)

#### `confirm_process_termination(pid1 pid2 ...)`
Ask user before killing processes
- **Display**: Shows command for each PID
- **Return**: 0 (confirmed), 1 (declined)

#### `terminate_process_graceful(pid)`
Send SIGTERM and wait up to 5 seconds
- **Timeout**: 5 seconds
- **Return**: 0 (success), 1 (timeout/failed)

#### `terminate_process_force(pid)`
Send SIGKILL (force kill)
- **Fallback**: Used if graceful fails
- **Return**: 0 (success), 1 (failed)

#### `resolve_port_conflict(port)`
Complete port resolution workflow
- **Steps**: Find → Confirm → Terminate (graceful+force) → Verify
- **Return**: 0 (resolved), 1 (failed)

### Certificate Functions

#### `select_certificate_type()`
Interactive menu for cert type selection
- **Options**: single, multi, wildcard
- **Return**: Selected type or recursive call

#### `select_challenge_type()`
Interactive menu for challenge selection
- **Options**: dns, http, dns-api
- **Return**: Selected type

#### `issue_single_domain_certificate(domain, email, challenge_type)`
Issue certificate for single domain
- **Uses**: certbot certonly with manual/standalone
- **Logging**: Full certbot output to log file
- **Return**: 0 (success), 1 (failure)

#### `issue_multi_domain_certificate(domain1 domain2 ...)`
Issue one cert for multiple domains
- **Method**: Multiple --domain flags
- **Return**: 0 (success), 1 (failure)

#### `organize_certificate_files(domain)`
Copy certs from /etc/letsencrypt to output/
- **Creates**: Directory structure with timestamps
- **Permissions**: 600 privkey, 644 others
- **Backup**: Previous files backed up
- **Return**: 0 (success), 1 (failure)

### Utility Functions

#### `log_info(message)`
Log info message to console and file

#### `log_warn(message)`
Log warning message to console and file

#### `log_error(message)`
Log error message to stderr and file

#### `log_debug(message)`
Log debug message (only if DEBUG_MODE=true)

#### `section_header(title)`
Display formatted section header

#### `info_box(title, content)`
Display information in formatted box

#### `error_box(title, content)`
Display error in formatted box

#### `prompt_yes_no(question, default)`
Prompt user for yes/no, return 0/1

## Configuration Variables

### Timeouts (in seconds)
```bash
DNS_CHECK_TIMEOUT=10
HTTP_CHECK_TIMEOUT=5
CERT_CHECK_TIMEOUT=10
```

### Network
```bash
PUBLIC_IP_SOURCES=(
  "https://api.ipify.org"
  "https://ifconfig.me"
  "https://icanhazip.com"
  "https://checkip.amazonaws.com"
)
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9")
```

### Paths
```bash
OUTPUT_DIR="${SCRIPT_DIR}/output"
TEMP_DIR="${SCRIPT_DIR}/.tmp"
STATE_DIR="${OUTPUT_DIR}/.state"
```

### DNS Polling (in poll_dns_record)
```bash
max_attempts=36        # 3 minutes total
sleep interval=5       # 5 seconds between attempts
```

## Adding New Features

### Add New DNS Provider Instructions

Edit `display_challenge_instructions()`:

```bash
case "$challenge_type" in
  dns)
    echo "New provider: "
    echo "1. Go to provider dashboard"
    echo "2. Add TXT record"
    ;;
esac
```

### Add New DNS Cache Method

Create function:
```bash
flush_dns_cache_newmethod() {
  log_debug "Attempting DNS cache flush via new method"
  if command -v newmethod &> /dev/null; then
    if newmethod-flush 2>/dev/null; then
      log_info "DNS cache flushed via new method"
      return 0
    fi
  fi
  return 1
}
```

Add to fallback chain in `flush_dns_cache()`:
```bash
if flush_dns_cache_newmethod; then
  echo "newmethod"
  return 0
fi
```

### Add Retry Logic

Example for DNS poll:

```bash
local retries=3
local retry_count=0

while [[ $retry_count -lt $retries ]]; do
  if poll_dns_record "$domain" "$value"; then
    return 0
  fi
  ((retry_count++))
  sleep 10  # Wait before retry
done

return 1
```

## Testing During Development

### Syntax Check
```bash
bash -n ssl-wizard.sh
```

### Static Analysis
```bash
shellcheck ssl-wizard.sh
```

### Debug Mode
```bash
DEBUG_MODE=true sudo ./ssl-wizard.sh example.com
```

### Dry Run (no changes)
```bash
# Modify script to add --dry-run to certbot
# Change: issue_single_domain_certificate
cert_command="$cert_command --dry-run"
```

### Test with Staging
```bash
# Edit main() to use staging:
cert_command="$cert_command --staging"
```

## Performance Considerations

### DNS Polling Optimization
- Current: 5-second intervals, 3-minute timeout
- Can adjust in `poll_dns_record()` parameters
- Trade-off: Lower interval = more load on DNS servers

### Parallel Execution
- DNS queries to multiple servers could be parallelized
- Currently sequential for simplicity

### Caching
- Currently no caching (each run is fresh)
- Could cache DNS results between runs (future optimization)

## Known Limitations

1. **No DNS API integration yet** - All DNS changes are manual
2. **Single thread** - Processes domains sequentially
3. **No renewal automation** - Must run manually or via cron
4. **No domain validation** - Doesn't check domain format
5. **Staging not automated** - Must edit config manually

## Future Enhancements (v2.0)

1. DNS provider API integration (Cloudflare, Route53, etc.)
2. Automated renewal with systemd timer
3. Web UI for configuration
4. Batch processing multiple domains in parallel
5. Certificate monitoring and alerts
6. Integration with load balancers

## Code Style Guidelines

1. **Quoting**: Always quote variables: `"$var"`
2. **Functions**: Use descriptive names: `get_a_record()` not `getnamerec()`
3. **Comments**: Explain WHY, not WHAT
4. **Error handling**: Always check return codes
5. **Logging**: Log important operations
6. **Spacing**: Use blank lines for readability

### Example Function Template

```bash
# Task X.Y: Brief description
function_name() {
  local input="$1"
  local optional="${2:-default}"
  
  log_debug "Function description and input"
  
  # Main logic
  if command_fails; then
    log_error "What failed and why"
    return 1
  fi
  
  log_info "Success message"
  echo "output"
  return 0
}
```

## Troubleshooting Development

### Script Hanging
- Check for unquoted variables in loops
- Verify `set -euo pipefail` isn't too strict
- Use timeout: `timeout 10 function_call`

### Function Not Found
- Verify function defined before use
- Check spelling/case sensitivity

### Variable Unexpectedly Empty
- Check if variable is exported
- Verify it's not in subshell

### Color Codes Not Working
- Verify terminal supports ANSI codes
- Test with: `echo -e "${COLOR_GREEN}test${COLOR_RESET}"`

## Contributing

1. Fork repository
2. Create feature branch: `git checkout -b feature/name`
3. Follow code style guidelines
4. Test thoroughly on Ubuntu 22.04 and 24.04
5. Submit pull request with test results

## License

MIT License - See LICENSE file for details

---

**Last Updated**: [Current Date]
**Version**: 1.0.0
**Maintainer**: Parsamrz
