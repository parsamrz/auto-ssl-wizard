# SSL Wizard - Test Plan & Validation

## Test Execution Summary

This document outlines all test cases for the SSL Wizard project across Ubuntu 22.04 and 24.04.

## Pre-Test Requirements

1. Two clean Ubuntu instances:
   - One Ubuntu 22.04 LTS
   - One Ubuntu 24.04 LTS
2. Public domain name with registrar access
3. Let's Encrypt account (can be created during wizard)
4. SSH access to both instances

## Phase 1: System Diagnostics & Dependency Tests

### Test 1.1: OS Detection
- **Objective**: Verify correct OS detection and version reporting
- **Steps**:
  1. Run on Ubuntu 22.04: `sudo ./ssl-wizard.sh test.example.com`
  2. Run on Ubuntu 24.04: `sudo ./ssl-wizard.sh test.example.com`
- **Expected**: Script displays correct OS version for each system

### Test 1.2: Public IP Detection
- **Objective**: Verify public IP retrieval with fallback sources
- **Steps**:
  1. Run script and observe IP detection
  2. Simulate network issues by blocking DNS temporarily
- **Expected**: IP obtained from first available source or fallback

### Test 1.3: Dependency Detection
- **Objective**: Verify detection of all required dependencies
- **Steps**:
  1. Run script on clean system
  2. Verify certbot, dig, ss, curl detection
  3. Allow auto-installation
- **Expected**: All dependencies installed successfully

### Test 1.4: Port Availability Check
- **Objective**: Verify port 80/443 availability detection
- **Steps**:
  1. Run script with ports free
  2. Start a service on port 80, run script again
- **Expected**: Script correctly detects available/occupied ports

## Phase 2: DNS & Port Conflict Tests

### Test 2.1: DNS A Record Lookup
- **Objective**: Verify A record resolution for domains
- **Steps**:
  1. Run: `sudo ./ssl-wizard.sh example.com`
  2. Observe DNS validation
- **Expected**: A record displayed correctly

### Test 2.2: DNS Mismatch Detection
- **Objective**: Verify detection when domain doesn't point to server
- **Steps**:
  1. Provide domain not pointing to server IP
  2. Allow script to detect mismatch
  3. Choose override option
- **Expected**: Warning displayed, user can override or cancel

### Test 2.3: Port Conflict Resolution
- **Objective**: Verify port conflict detection and resolution
- **Steps**:
  1. Start nginx/apache on port 80
  2. Run script
  3. Allow termination of conflicting process
- **Expected**: Process terminated, port freed, script proceeds

### Test 2.4: DNS Cache Clearing
- **Objective**: Verify DNS cache cleared before queries
- **Steps**:
  1. Add DNS record manually
  2. Run script DNS polling
  3. Observe cache method used
- **Expected**: Cache cleared, new records detected immediately

### Test 2.5: Multiple DNS Server Checking
- **Objective**: Verify querying multiple DNS servers
- **Steps**:
  1. Run DNS polling
  2. Observe queries to 8.8.8.8, 1.1.1.1, 9.9.9.9
- **Expected**: All servers queried, results logged

## Phase 3: Certificate Issuance Tests

### Test 3.1: Single Domain Certificate
- **Objective**: Issue certificate for single domain
- **Steps**:
  1. Run: `sudo ./ssl-wizard.sh example.com`
  2. Select: Single domain, DNS-01 challenge, manual email/TOS
  3. Complete DNS record addition
- **Expected**: Certificate issued in ~5-10 minutes

### Test 3.2: Multi-Domain Certificate (SAN)
- **Objective**: Issue certificate for multiple domains in one cert
- **Steps**:
  1. Run: `sudo ./ssl-wizard.sh example.com www.example.com api.example.com`
  2. Select: Multi-domain certificate
  3. Add DNS records for all domains
- **Expected**: One certificate covering all domains

### Test 3.3: Wildcard Certificate
- **Objective**: Issue wildcard certificate for all subdomains
- **Steps**:
  1. Run: `sudo ./ssl-wizard.sh example.com`
  2. Select: Wildcard certificate
  3. Add DNS record for `_acme-challenge.example.com`
- **Expected**: Wildcard certificate for `*.example.com` issued

### Test 3.4: Challenge Type Selection
- **Objective**: Verify menu for DNS-01 vs HTTP-01
- **Steps**:
  1. Run script
  2. Try DNS-01 (manual), then HTTP-01
- **Expected**: Appropriate instructions for each type

### Test 3.5: Email & TOS Agreement
- **Objective**: Verify email collection and TOS acceptance
- **Steps**:
  1. Run script
  2. Provide email, agree to TOS
- **Expected**: Email stored with certificate, TOS verified

### Test 3.6: Rate Limit Warning
- **Objective**: Verify rate limit information displayed
- **Steps**:
  1. Run script
  2. Observe rate limit warning before issuance
- **Expected**: Warning displayed with limits and actions

### Test 3.7: Error Handling
- **Objective**: Verify graceful handling of Certbot errors
- **Steps**:
  1. Reject TOS or use invalid email
  2. Observe error handling
- **Expected**: Clear error messages, no crashes

## Phase 4: File Organization Tests

### Test 4.1: Directory Structure Creation
- **Objective**: Verify output directory structure created
- **Steps**:
  1. Complete certificate issuance
  2. Check directory tree: `tree output/example.com/`
- **Expected**: Structure: live/, archive/, logs/ all created

### Test 4.2: File Permissions
- **Objective**: Verify correct file permissions set
- **Steps**:
  1. Complete issuance
  2. Run: `ls -la output/example.com/live/`
- **Expected**: privkey.pem=600, others=644

### Test 4.3: Backup & Archiving
- **Objective**: Verify backup on overwrite
- **Steps**:
  1. Complete first issuance
  2. Run again for same domain
  3. Check archive directory
- **Expected**: Previous files backed up with timestamp

### Test 4.4: Certificate File Integrity
- **Objective**: Verify all certificate files valid
- **Steps**:
  1. Run: `openssl x509 -in output/example.com/live/cert.pem -text`
  2. Verify domain name matches
- **Expected**: Valid certificate with correct domain

## Phase 5: Logging & Output Tests

### Test 5.1: Log File Creation
- **Objective**: Verify logs recorded
- **Steps**:
  1. Complete issuance
  2. Check: `cat output/example.com/logs/issuance.log`
- **Expected**: Detailed log with all operations timestamped

### Test 5.2: Error Logging
- **Objective**: Verify errors logged with details
- **Steps**:
  1. Trigger an error (e.g., invalid email)
  2. Check logs for error details
- **Expected**: Full error information in logs

### Test 5.3: ANSI Formatting
- **Objective**: Verify colored output displays correctly
- **Steps**:
  1. Run script in terminal
  2. Observe colored output
- **Expected**: Colors display correctly, no ANSI codes visible

### Test 5.4: Progress Indicators
- **Objective**: Verify progress shown during long operations
- **Steps**:
  1. Run DNS polling
  2. Observe progress update every 5 seconds
- **Expected**: Attempt counter and elapsed time displayed

## Phase 6: Integration & End-to-End Tests

### Test 6.1: Complete Workflow - Single Domain
- **Objective**: Full workflow for single domain
- **Steps**:
  1. Run: `sudo ./ssl-wizard.sh testdomain.com`
  2. Follow all prompts
  3. Complete DNS record addition
  4. Verify certificate in output directory
- **Expected**: Certificate issued and organized successfully

### Test 6.2: Complete Workflow - Multi-Domain
- **Objective**: Full workflow for multiple domains
- **Steps**:
  1. Run: `sudo ./ssl-wizard.sh test1.com test2.com test3.com`
  2. Add DNS records for all domains
- **Expected**: One certificate for all domains

### Test 6.3: Complete Workflow - Wildcard
- **Objective**: Full workflow for wildcard certificate
- **Steps**:
  1. Run: `sudo ./ssl-wizard.sh example.com`
  2. Select wildcard option
  3. Add single DNS record
- **Expected**: Wildcard certificate covers all subdomains

### Test 6.4: Ubuntu 22.04 Full Test
- **Objective**: Verify complete functionality on 22.04
- **Steps**:
  1. Fresh Ubuntu 22.04 instance
  2. Run complete workflow
  3. Test all features
- **Expected**: Everything works on 22.04

### Test 6.5: Ubuntu 24.04 Full Test
- **Objective**: Verify complete functionality on 24.04
- **Steps**:
  1. Fresh Ubuntu 24.04 instance
  2. Run complete workflow
  3. Test all features
- **Expected**: Everything works on 24.04

## Performance Tests

### Test 7.1: DNS Propagation Time
- **Objective**: Measure actual DNS propagation time
- **Steps**:
  1. Add DNS record
  2. Note time when script detects it
- **Expected**: Detected within 3 minutes (typically 30-60 seconds)

### Test 7.2: Certificate Issuance Time
- **Objective**: Measure total issuance time
- **Steps**:
  1. Start script
  2. Time until certificate issued
- **Expected**: Typically 2-5 minutes

### Test 7.3: Script Startup Time
- **Objective**: Measure script initialization
- **Steps**:
  1. Time: `time sudo ./ssl-wizard.sh example.com`
- **Expected**: Diagnostics complete in < 10 seconds

## Stress & Error Handling Tests

### Test 8.1: Rate Limit Hit
- **Objective**: Verify handling when rate limit hit
- **Steps**:
  1. Issue multiple certificates for same domain in short time
  2. Observe error handling
- **Expected**: Clear error message, guidance to wait/use staging

### Test 8.2: DNS Propagation Timeout
- **Objective**: Verify timeout handling for slow DNS
- **Steps**:
  1. Add DNS record very slowly
  2. Let polling timeout
- **Expected**: Error displayed after 3 minutes

### Test 8.3: Network Interruption
- **Objective**: Verify handling of network issues
- **Steps**:
  1. Start issuance
  2. Simulate network outage during DNS poll
- **Expected**: Graceful error, can retry

### Test 8.4: Invalid Email
- **Objective**: Verify email validation
- **Steps**:
  1. Enter invalid email format
  2. Run script
- **Expected**: Error displayed, re-prompt for email

### Test 8.5: TOS Rejection
- **Objective**: Verify handling when TOS rejected
- **Steps**:
  1. Run script
  2. Reject TOS
- **Expected**: Script exits with message

## Security Tests

### Test 9.1: Private Key Permissions
- **Objective**: Verify private key has restrictive permissions
- **Steps**:
  1. Complete issuance
  2. Run: `ls -la output/example.com/live/privkey.pem`
- **Expected**: Permissions show 600 (rw-------)

### Test 9.2: Certificate Permissions
- **Objective**: Verify certificate has readable permissions
- **Steps**:
  1. Complete issuance
  2. Run: `ls -la output/example.com/live/cert.pem`
- **Expected**: Permissions show 644 (rw-r--r--)

### Test 9.3: Log File Permissions
- **Objective**: Verify logs not world-readable
- **Steps**:
  1. Check: `ls -la output/example.com/logs/`
- **Expected**: Logs readable by owner/group

## Test Results Summary Template

```
Test Run: [Date] on [Ubuntu Version]
Domain: [example.com]
Result: PASS / FAIL

Test Results:
- Phase 1 (Diagnostics): [# PASS / # FAIL]
- Phase 2 (DNS/Port): [# PASS / # FAIL]
- Phase 3 (Issuance): [# PASS / # FAIL]
- Phase 4 (Storage): [# PASS / # FAIL]
- Phase 5 (Logging): [# PASS / # FAIL]
- Phase 6 (E2E): [# PASS / # FAIL]

Notes:
- [Any issues or observations]
- [Performance metrics]
- [Recommendations]
```

## Continuous Integration Testing

### Automated Tests (Future)

```bash
# Run syntax check
bash -n ssl-wizard.sh

# Run shellcheck (static analysis)
shellcheck ssl-wizard.sh

# Run tests on both Ubuntu versions
docker run -v $(pwd):/app ubuntu:22.04 bash /app/test.sh
docker run -v $(pwd):/app ubuntu:24.04 bash /app/test.sh
```

## Regression Testing

After each update:

1. Run full end-to-end test on both Ubuntu versions
2. Verify DNS cache clearing still works
3. Verify file permissions correct
4. Check log format unchanged
5. Verify all color codes display correctly

## Success Criteria

All tests must pass for release:
- ✓ All Phase tests pass on Ubuntu 22.04
- ✓ All Phase tests pass on Ubuntu 24.04
- ✓ No security issues in private key/cert handling
- ✓ All error scenarios handled gracefully
- ✓ DNS propagation detected accurately
- ✓ Logs complete and readable
- ✓ Documentation complete and accurate

---

**Last Updated**: [Current Date]
**Version**: 1.0.0
**Status**: Ready for Testing
