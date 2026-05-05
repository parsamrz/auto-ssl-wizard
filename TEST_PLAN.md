# SSL Wizard - Test Plan

## Test Execution Summary

This document outlines all test cases for the SSL Wizard project.

## Pre-Test Requirements

- Clean Ubuntu 22.04 and 24.04 instances
- Public domain name with registrar access
- SSH access to both instances
- DNS provider access

## Phase 1: System Diagnostics Tests

### Test 1.1: OS Detection
- Run script on Ubuntu 22.04 → verify correct version
- Run script on Ubuntu 24.04 → verify correct version

### Test 1.2: Public IP Detection
- Verify IP obtained from primary source
- Verify fallback to alternate sources

### Test 1.3: Dependency Detection
- Verify certbot detection
- Verify dig/nslookup detection
- Verify ss/netstat detection
- Verify curl detection

### Test 1.4: Port Availability
- Test with ports free → should report available
- Test with service on port 80 → should report in use

## Phase 2: DNS & Port Tests

### Test 2.1: DNS A Record Lookup
- Verify A record resolution for known domains
- Verify fallback from dig to nslookup

### Test 2.2: DNS Mismatch Detection
- Provide domain not pointing to server
- Verify mismatch detected
- Verify user override option works

### Test 2.3: Port Conflict Resolution
- Start service on port 80
- Run script → should detect and offer termination
- Verify process terminated
- Verify port freed

### Test 2.4: DNS Cache Clearing
- Verify resolvectl method attempted first
- Verify systemctl fallback
- Verify nscd methods tried
- Verify graceful degradation if all fail

### Test 2.5: Multiple DNS Servers
- Verify querying 8.8.8.8, 1.1.1.1, 9.9.9.9
- Verify results logged

## Phase 3: Certificate Issuance Tests

### Test 3.1: Single Domain Certificate
- Issue certificate for single domain
- Verify TXT record added
- Verify propagation detected
- Verify certificate issued

### Test 3.2: Multi-Domain Certificate
- Issue certificate for 3 domains
- Verify all domains in single certificate

### Test 3.3: Wildcard Certificate
- Issue wildcard certificate
- Verify covers *.domain.com

### Test 3.4: Challenge Type Selection
- Test DNS-01 challenge flow
- Test HTTP-01 challenge flow

### Test 3.5: Email & TOS
- Verify email collection
- Verify TOS agreement required
- Verify email format validation

### Test 3.6: Rate Limit Warning
- Verify warning displayed
- Verify user acknowledgment required

## Phase 4: File Organization Tests

### Test 4.1: Directory Structure
- Verify live/, archive/, logs/ created
- Verify files in correct locations

### Test 4.2: File Permissions
- Verify privkey.pem has 600 permissions
- Verify cert.pem has 644 permissions

### Test 4.3: Backup on Overwrite
- Issue first certificate
- Issue second certificate for same domain
- Verify first certificate backed up with timestamp

## Phase 5: Logging Tests

### Test 5.1: Log File Creation
- Verify log file created
- Verify contains operation records
- Verify timestamps correct

### Test 5.2: Error Logging
- Trigger error scenario
- Verify error logged with details

### Test 5.3: ANSI Color Output
- Run in terminal
- Verify colors display correctly

## Phase 6: Integration Tests

### Test 6.1: Full Single Domain Workflow
- Run complete flow for single domain
- Verify success from start to finish

### Test 6.2: Full Multi-Domain Workflow
- Run complete flow for multiple domains
- Verify success

### Test 6.3: Full Wildcard Workflow
- Run complete workflow for wildcard
- Verify success

### Test 6.4: Ubuntu 22.04 Compatibility
- Run on clean Ubuntu 22.04
- Verify all features work

### Test 6.5: Ubuntu 24.04 Compatibility
- Run on clean Ubuntu 24.04
- Verify all features work

## Performance Tests

### Test 7.1: DNS Propagation Time
- Measure time from record addition to detection
- Target: < 3 minutes, typically 30-60 seconds

### Test 7.2: Certificate Issuance Time
- Measure total time for complete flow
- Target: 5-10 minutes

### Test 7.3: Script Startup Time
- Measure diagnostics execution time
- Target: < 10 seconds

## Error Handling Tests

### Test 8.1: Invalid Email
- Enter invalid email format
- Verify re-prompt

### Test 8.2: TOS Rejection
- Reject Let's Encrypt TOS
- Verify script exits gracefully

### Test 8.3: DNS Polling Timeout
- Trigger DNS polling without valid record
- Verify timeout after 3 minutes

### Test 8.4: Port Termination Failure
- Attempt to terminate non-existent process
- Verify graceful error handling

### Test 8.5: Rate Limit Hit
- Issue multiple certs in short time
- Verify error handling

## Security Tests

### Test 9.1: Private Key Permissions
- Verify privkey.pem has 600 permissions
- Verify not world-readable

### Test 9.2: Certificate Permissions
- Verify cert.pem has 644 permissions
- Verify readable by web servers

### Test 9.3: Backup Security
- Verify backups have appropriate permissions
- Verify not world-readable

## Test Execution Checklist

- [ ] Phase 1: 4 tests passed
- [ ] Phase 2: 10 tests passed
- [ ] Phase 3: 7 tests passed
- [ ] Phase 4: 4 tests passed
- [ ] Phase 5: 4 tests passed
- [ ] Phase 6: 5 tests passed
- [ ] Performance: 3 tests acceptable
- [ ] Error Handling: 5 tests passed
- [ ] Security: 3 tests passed

## Success Criteria

✓ All tests passing on Ubuntu 22.04
✓ All tests passing on Ubuntu 24.04
✓ No security issues found
✓ All errors handled gracefully
✓ DNS propagation detected accurately
✓ Logs complete and readable
✓ Documentation complete

---

**Version**: 1.0.0  
**License**: MIT
