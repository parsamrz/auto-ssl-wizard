## 1. Project Setup and Structure

- [x] 1.1 Create main script file `ssl-wizard.sh` with shebang and initial structure
- [x] 1.2 Set up logging infrastructure with timestamp and log levels (INFO, WARN, ERROR)
- [x] 1.3 Create output directory structure template: `certs-out/<domain>/`
- [x] 1.4 Add configuration variables (timeouts, colors, paths) to script header

## 2. System Diagnostics Implementation

- [x] 2.1 Implement function to retrieve and display public IP address (with fallback handling)
- [x] 2.2 Implement OS version detection (uname, /etc/os-release parsing)
- [x] 2.3 Implement port 80 availability check (using ss or netstat)
- [x] 2.4 Implement port 443 availability check
- [x] 2.5 Create diagnostic summary display function with color formatting
- [x] 2.6 Add Ubuntu version validation and error exit for unsupported distributions

## 3. Dependency Management Implementation

- [x] 3.1 Implement Certbot detection function
- [x] 3.2 Implement snap-based Certbot installation with error handling
- [x] 3.3 Implement apt-based Certbot installation as fallback
- [x] 3.4 Implement dig/nslookup availability check with fallback logic
- [x] 3.5 Implement port checking tool detection (ss/netstat)
- [x] 3.6 Create dependency status display with all tools verification
- [x] 3.7 Test auto-installation on clean Ubuntu 22.04/24.04 instances

## 4. DNS Validation Implementation

- [x] 4.1 Implement function to parse comma-separated domain input
- [x] 4.2 Implement A record lookup using dig (primary) or nslookup (fallback)
- [x] 4.3 Implement NS record lookup and display
- [x] 4.4 Implement DNS-to-server-IP matching logic with clear mismatch reporting
- [x] 4.5 Implement user prompt for DNS mismatch override with warning
- [x] 4.6 Create validation loop for multiple domains with error handling per domain
- [x] 4.7 Test DNS validation against real domains with mismatches and correct DNS

## 5. Port Conflict Resolution Implementation

- [x] 5.1 Implement function to identify process(es) on port 80
- [x] 5.2 Implement user confirmation prompt for process termination
- [x] 5.3 Implement graceful process termination (SIGTERM) with 5-second timeout
- [x] 5.4 Implement force kill (SIGKILL) as fallback if graceful fails
- [x] 5.5 Implement port verification after termination attempt
- [x] 5.6 Create error handling for failed termination with user guidance
- [x] 5.7 Test with mock processes (nginx, apache2) on port 80

## 5a. Real-Time DNS Validation Implementation

- [x] 5a.1 Implement DNS polling function that queries every 5 seconds
- [x] 5a.2 Implement DNS record value comparison (expected vs. actual)
- [x] 5a.3 Create progress display during polling with attempt counter
- [x] 5a.4 Implement timeout handler for DNS propagation delays (configurable, default 3 minutes)
- [x] 5a.5 Implement multiple DNS server checking (Google 8.8.8.8, Cloudflare 1.1.1.1)
- [x] 5a.6 Display propagation time once DNS record is detected
- [x] 5a.7 Implement manual DNS check option (user runs dig command and reports)
- [x] 5a.8 Log all polling attempts and results with timestamps
- [x] **5a.9 NEW:** Implement DNS cache clearing before each DNS query
- [x] **5a.10 NEW:** Try cache clearing methods in order: resolvectl → systemctl → nscd
- [x] **5a.11 NEW:** Log cache flush status and method used for each query
- [x] **5a.12 NEW:** Handle systems without DNS cache services gracefully
- [x] 5a.13 Test real-time DNS validation on live domains with actual DNS changes

## 5b. DNS Cache Clearing Implementation

- [x] **5b.1 NEW:** Create DNS cache detection function to identify system cache service
- [x] **5b.2 NEW:** Implement `resolvectl flush-caches` for systemd-resolved systems
- [x] **5b.3 NEW:** Implement `systemctl restart systemd-resolved` as fallback for systemd-resolved
- [x] **5b.4 NEW:** Implement `nscd -i hosts` for nscd cache daemon
- [x] **5b.5 NEW:** Implement `service nscd restart` as nscd fallback
- [x] **5b.6 NEW:** Create fallback chain function (try methods in order, continue if all fail)
- [x] **5b.7 NEW:** Implement DNS cache clear before each polling query (every 5 seconds)
- [x] **5b.8 NEW:** Log cache flush method, status, and timestamp for each attempt
- [x] **5b.9 NEW:** Handle permissions issues (sudo not available) gracefully
- [x] **5b.10 NEW:** Add cache flush status to poll result logging (e.g., "[FRESH]" indicator)
- [x] **5b.11 NEW:** Test on Ubuntu 22.04 with systemd-resolved
- [x] **5b.12 NEW:** Test on Ubuntu 24.04 with systemd-resolved
- [x] **5b.13 NEW:** Test cache clearing behavior with real DNS changes
- [x] **5b.14 NEW:** Verify stale cache is not used (TXT records appear immediately after flush)

## 5c. DNS Query Optimization

- [ ] **5c.1 NEW:** Implement DNS query timing function to measure response time
- [ ] **5c.2 NEW:** Implement exponential backoff for failed queries (start 5s, increase to 10s)
- [ ] **5c.3 NEW:** Display query response time in polling results
- [ ] **5c.4 NEW:** Log DNS query response times for performance analysis
- [ ] **5c.5 NEW:** Test DNS query performance with various network conditions

- [x] 6.1 **NEW:** Implement challenge type selection menu (DNS TXT, HTTP-01, DNS API)
- [x] 6.2 **NEW:** Display challenge-specific instructions and required DNS/HTTP record details
- [x] 6.3 **NEW:** Create formatted display for DNS record structure (Type, Name/Host, Value, TTL)
- [x] 6.4 **NEW:** Implement current DNS A record status display (Expected vs. Actual)
- [x] 6.5 **NEW:** Add wildcard-specific DNS record format (clarify _acme-challenge.example.com, not *.example.com)
- [x] 6.6 Implement interactive menu for certificate type selection (single/multi/wildcard)
- [x] 6.7 Implement single-domain certificate issuance via Certbot standalone
- [x] 6.8 Implement multi-domain certificate issuance with multiple --domain flags
- [x] 6.9 Implement email prompt and TOS agreement flow
- [x] 6.10 Implement Let's Encrypt rate limit warning and user acknowledgment
- [x] 6.11 Implement error capture and logging for Certbot failures
- [x] 6.12 Test certificate issuance for single, multi-domain types
- [x] 6.13 Validate certificate files are created in Certbot output directory

## 7. Manual DNS Challenge Implementation

- [x] 7.1 Implement wildcard certificate issuance with `--manual --preferred-challenges dns`
- [x] 7.2 Implement TXT record extraction and formatted display
- [x] 7.3 Implement "copy to clipboard" optional feature (if xclip/xsel available)
- [x] 7.4 Implement pause-and-wait-for-user flow with clear instructions
- [x] 7.5 Implement DNS validation timeout handling and retry logic
- [x] 7.6 Implement troubleshooting guidance display on DNS validation failure
- [x] 7.7 Create helper function to display dig command for manual DNS checking
- [x] 7.8 **NEW:** Implement real-time DNS polling to verify user-entered TXT record (every 5 seconds)
- [x] 7.9 **NEW:** Display complete DNS record structure (Type, Name/Host, Value, TTL) in formatted box
- [x] 7.10 **NEW:** Show DNS entry checklist with step-by-step instructions
- [x] 7.11 **NEW:** Implement DNS provider selection (Cloudflare, Route53, DigitalOcean, etc.)
- [x] 7.12 **NEW:** Generate provider-specific DNS entry instructions based on selection
- [x] 7.13 **NEW:** Display propagation time once DNS record is detected
- [x] 7.14 Test wildcard issuance with manual DNS record entry and real-time validation flow
- [x] 7.15 Test DNS provider-specific instructions for at least 3 providers

## 8. File Organization and Storage

- [x] 8.1 Implement `certs-out/<domain>/` directory creation with subdirectories (live, archive, logs)
- [x] 8.2 Implement file copy from `/etc/letsencrypt/live/<domain>/` to `./certs-out/<domain>/live/`
- [x] 8.3 Implement file permission setting (600 for privkey.pem, 644 for others)
- [x] 8.4 Implement archive creation with original Certbot files and timestamping
- [x] 8.5 Implement directory overwrite confirmation and backup with timestamp
- [x] 8.6 Implement log file creation with detailed operation record
- [x] 8.7 Test file organization with actual certificate files from Certbot
- [x] 8.8 Verify file permissions are correctly enforced

## 9. Logging and Audit Trail

- [x] 9.1 Implement structured logging function with timestamp, level, and message
- [x] 9.2 Add logging to all major operations (diagnostics, DNS checks, port conflicts, issuance)
- [x] 9.3 Log user inputs and confirmations for reproducibility
- [x] 9.4 Create log rotation/archiving strategy for repeated issuances
- [x] 9.5 Implement error logging with full Certbot output capture
- [x] 9.6 Test log readability and completeness for troubleshooting

## 10. User Interface and Output Formatting

- [x] 10.1 Implement ANSI color code constants (Green=32, Yellow=33, Red=31)
- [x] 10.2 Implement formatted output functions for success (✓), warning (⚠), error (✗) messages
- [x] 10.3 Implement diagnostic summary display with formatted table
- [x] 10.4 Implement interactive menu prompts with numbered/lettered options
- [x] 10.5 Implement yes/no confirmation parsing with flexible input handling
- [x] 10.6 Implement progress indicators for long-running operations (install, issuance)
- [x] 10.7 Implement help/usage information display
- [x] 10.8 Implement final success summary with file paths and next steps

## 11. Error Handling and Recovery

- [x] 11.1 Implement graceful error exit with error message display
- [x] 11.2 Implement retry logic for failed operations (DNS check, port termination, issuance)
- [x] 11.3 Implement user-friendly error messages with actionable guidance
- [x] 11.4 Implement partial failure handling (e.g., cert issued but copy fails)
- [x] 11.5 Implement cleanup on script exit (temp files, partial directories)
- [x] 11.6 Test error scenarios: missing dependencies, port conflicts, DNS failures, rate limits

## 12. Testing and Validation

- [ ] 12.1 Test on clean Ubuntu 22.04 LTS instance with no dependencies
- [ ] 12.2 Test on clean Ubuntu 24.04 LTS instance
- [ ] 12.3 Test complete flow for single-domain certificate issuance
- [ ] 12.4 Test complete flow for multi-domain certificate issuance
- [ ] 12.5 Test complete flow for wildcard certificate with manual DNS challenge
- [ ] 12.6 Test port 80 conflict detection and process termination
- [ ] 12.7 Test DNS validation with correct and incorrect domain configurations
- [ ] 12.8 Test DNS validation override (user confirms despite mismatch)
- [ ] 12.9 Test rate limit warning display and acknowledgment
- [ ] 12.10 Test file organization, permissions, and log creation
- [ ] 12.11 Test error cases: missing email, TOS rejection, Certbot failure
- [ ] 12.12 Test script idempotency (re-run should not cause issues)
- [ ] **12.13 NEW:** Test challenge type selection menu for all three options (DNS TXT, HTTP-01, DNS API)
- [ ] **12.14 NEW:** Test DNS record structure display and clipboard copy functionality
- [ ] **12.15 NEW:** Test real-time DNS polling with actual DNS changes (add/remove TXT records)
- [ ] **12.16 NEW:** Test DNS propagation detection and timing accuracy
- [ ] **12.17 NEW:** Test provider-specific instructions for Cloudflare, Route53, DigitalOcean
- [ ] **12.18 NEW:** Test DNS polling timeout and manual verification workflow
- [ ] **12.19 NEW:** Test multiple DNS server checking (Google 8.8.8.8, Cloudflare 1.1.1.1)
- [ ] **12.20 NEW:** Test DNS entry checklist display and user interaction
- [ ] **12.21 NEW:** Verify all DNS record formats are correctly displayed (wildcard vs. standard)
- [ ] **12.22 NEW:** Test DNS cache clearing with resolvectl on systemd-resolved systems
- [ ] **12.23 NEW:** Test DNS cache clearing with nscd on systems using nscd
- [ ] **12.24 NEW:** Test cache clearing failure handling (graceful fallback if services unavailable)
- [ ] **12.25 NEW:** Verify DNS records are detected immediately after addition (cache not stale)
- [ ] **12.26 NEW:** Test DNS cache clearing every 5 seconds during polling
- [ ] **12.27 NEW:** Verify logs show cache flush method and status for each polling attempt
- [ ] **12.28 NEW:** Test TXT record detection accuracy before/after DNS cache clearing
- [ ] **12.29 NEW:** Test DNS query response time logging and display

## 13. Documentation and Deployment

- [ ] 13.1 Write README.md with usage instructions and examples
- [ ] 13.2 Add inline code comments for complex sections
- [ ] 13.3 Document all environment variables and configuration options
- [ ] 13.4 Create troubleshooting guide based on common error scenarios
- [ ] 13.5 Document Let's Encrypt rate limits and backup strategies
- [ ] 13.6 Create example output showing certificate file locations
- [ ] 13.7 Finalize script as executable (`chmod +x ssl-wizard.sh`)
- [ ] 13.8 Test deployment via single command: `bash ssl-wizard.sh`
